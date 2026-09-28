/// Dream Phase 4C — the synthetic live corpus, turned into the exact
/// provider payloads the production client would send for it.
library;

import 'dart:convert';
import 'dart:io';

import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/memory/oracly_memory.dart';
import 'package:oracly_new/core/memory/oracly_memory_retriever.dart';
import 'package:oracly_new/core/memory/oracly_memory_store.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/openai/openai_paid_requests.dart';
import 'package:oracly_new/features/dream/models/dream_emotion.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';

import '../../support/dream_test_owner.dart';
import 'dream_honesty_fakes.dart';
import 'dream_phase2_support.dart';
import 'dream_phase4a_support.dart';

const phase4cCorpusPath = 'backend/tests/fixtures/dream-phase4c-corpus.json';
const phase4cPayloadsPath =
    'backend/tests/fixtures/dream-phase4c-payloads.json';

List<Map<String, dynamic>> loadPhase4cCases() {
  final raw = jsonDecode(File(phase4cCorpusPath).readAsStringSync()) as Map;
  return [
    for (final c in raw['cases'] as List) Map<String, dynamic>.from(c as Map),
  ];
}

List<DreamEmotion> _emotions(Object? ids) => [
      for (final id in (ids as List?) ?? const [])
        DreamEmotion(id: DreamEmotionId.values.byName(id as String)),
    ];

Future<OraclyMemoryRetriever?> _memory(Map<String, dynamic> c) async {
  final spec = c['memory'] as Map?;
  if (spec == null) return null;
  final store = OraclyMemoryStore(LocalStorage.ephemeral());
  await store.upsert(OraclyMemory(
    id: 'reading:${spec['type']}:${spec['id']}',
    kind: OraclyMemoryKind.reading,
    source: OraclyMemorySource(
      id: spec['id'] as String,
      type: OraclyReadingType.values.byName(spec['type'] as String),
      occurredAt: DateTime.parse(spec['occurredAt'] as String),
    ),
    summary: spec['summary'] as String,
    themes: [for (final t in spec['themes'] as List) t as String],
  ));
  return OraclyMemoryRetriever(store);
}

/// The request context the real service builds for [c]: its own language
/// detection, symbols, emotions, connected memory and saved-Dream history.
Future<({DreamAiContext context, String memorySource})> clientContext(
  Map<String, dynamic> c,
) async {
  final language = c['language'] as String;
  final repo = MemDreamRepository();
  final now = DateTime.now();
  final priors = (c['priorDreams'] as List?) ?? const [];
  await seed(repo, [
    for (final (i, p) in priors.indexed)
      savedDream(
        'qa4c-${c['id']}-$i',
        p['narrative'] as String,
        now.subtract(Duration(days: 40 - (p['day'] as int))),
        language: language,
        emotions: [for (final e in _emotions(p['emotions'])) e.id],
      ),
  ]);
  final ai = ScriptedDreamAi.grounded();
  final memory = await _memory(c);
  try {
    await DreamExperienceService(
      repository: repo,
      owner: testDreamOwner(),
      ai: ai,
      memory: memory,
    ).analyze(
      narrative: c['narrative'] as String,
      selectedEmotions: _emotions(c['selectedEmotions']),
    );
  } catch (_) {
    // Only the outgoing request is needed; the scripted reply is irrelevant.
  }
  final sent = ai.contexts.single;
  final source = memory == null
      ? 'none'
      : sent.memorySummary == null
          ? 'not_retrieved'
          : 'retriever';
  return (context: sent, memorySource: source);
}

/// Wire payload + model exactly as `OpenAiPaidRequests.dream` builds them.
Future<Map<String, dynamic>> clientRequest(Map<String, dynamic> c) async {
  final built = await clientContext(c);
  final request = OpenAiPaidRequests.dream(
    model: AiRuntimeConfig.defaultModel,
    context: built.context,
  );
  return {
    'id': c['id'],
    'language': c['language'],
    'category': c['category'],
    'memorySource': built.memorySource,
    'model': request.model,
    'payload': request.payload,
  };
}
