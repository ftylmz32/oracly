/// BATCH 3A.1 — Coffee personalization context reaches the writer only when
/// a trustworthy first name is available, and a reading never blocks or
/// degrades when it is not.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/personality/or_response_depth.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/models/chat_ai_reply.dart';
import 'package:oracly_new/features/ai/production/models/coffee_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/palm_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_service.dart';
import 'package:oracly_new/features/ai/production/openai/openai_paid_requests.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/services/openai_coffee_analysis.dart';
import 'package:oracly_new/features/discovery_journal/services/discovery_journal_map.dart';
import 'package:oracly_new/features/personal_discovery/models/cross_discovery_insight.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_theme_signal.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_theme_strength.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';

const _validAsset = 'lib/assets/images/coffee_ritual_hero.webp';

const _goodOverall =
    'Fincanda beliren yolun bir kısmı yarım kalmış bir kararı hatırlatıyor; '
    'bu ara ver, sonra devam et düşüncesi bugüne kadar hep haklı çıkmış '
    'gibi görünüyor.';

class _RecordingCoffeeAi implements OraclyAiService {
  Map<String, dynamic>? lastPersonalization;

  @override
  bool get isConfigured => true;
  @override
  bool get allowsLocalFallback => false;
  @override
  bool get visionAvailable => true;

  @override
  Future<AiOutcome<CoffeeAiAnalysis>> analyzeCoffee({
    required List<int> imageBytes,
    required String mimeType,
    Map<String, dynamic>? personalization,
  }) async {
    lastPersonalization = personalization;
    return AiOutcome.success(
      const CoffeeAiAnalysis(
        visualObservation: 'Fincan sakin duruyor.',
        overall: _goodOverall,
        love: '',
        career: '',
        money: '',
        nearFuture: '',
        takeaway: 'Yarım kalan işi bugün küçük bir adımla ilerletmek iyi gelebilir.',
      ),
    );
  }

  @override
  Future<AiOutcome<PalmAiAnalysis>> analyzePalm({
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
    Map<String, dynamic>? personalization,
  }) async =>
      throw UnsupportedError('palm not used in this test');

  @override
  Future<AiOutcome<ChatAiReply>> chat({
    required String userMessage,
    List<String> priorUser = const [],
    String? styleHint,
    String? personality,
    List<ConversationTurn> turns = const [],
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
  }) async =>
      throw UnsupportedError('chat not used in this test');

  @override
  Future<AiOutcome<ChatAiReply>> askOracle({
    required ReadingAiContext context,
    required String userMessage,
    List<String> priorUser = const [],
    List<String> observedThemes = const [],
    String? styleHint,
    String? personality,
    List<ConversationTurn> turns = const [],
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
  }) async =>
      throw UnsupportedError('askOracle not used in this test');

  @override
  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(DreamAiContext context) async =>
      throw UnsupportedError('dream not used in this test');

  @override
  Future<AiOutcome<ChatAiReply>> generateTarotReading({
    required List<Map<String, dynamic>> cards,
    required String spreadLabel,
    String? userQuestion,
    String? readingTheme,
    Map<String, dynamic>? journeyHints,
  }) async =>
      throw UnsupportedError('tarot not used in this test');
}

void main() {
  test('a trustworthy first name reaches the writer as personalization', () async {
    final ai = _RecordingCoffeeAi();
    final analysis = OpenAiCoffeeAnalysis(ai: ai, firstName: () => 'Deniz');
    await analysis.analyze(const CoffeeImagePick(path: _validAsset));
    expect(ai.lastPersonalization, {'firstName': 'Deniz'});
  });

  test('no profile name means no personalization — reading still succeeds', () async {
    final ai = _RecordingCoffeeAi();
    final analysis = OpenAiCoffeeAnalysis(ai: ai, firstName: () => null);
    final reading = await analysis.analyze(const CoffeeImagePick(path: _validAsset));
    expect(ai.lastPersonalization, isNull);
    expect(reading.overall, isNotEmpty);
  });

  test('constructing without a firstName accessor at all never blocks a reading', () async {
    final ai = _RecordingCoffeeAi();
    final analysis = OpenAiCoffeeAnalysis(ai: ai);
    final reading = await analysis.analyze(const CoffeeImagePick(path: _validAsset));
    expect(ai.lastPersonalization, isNull);
    expect(reading.overall, isNotEmpty);
  });

  test('placeholder-like or email-like names are never sent as personalization', () async {
    final ai = _RecordingCoffeeAi();
    for (final bad in ['guest', 'user', 'null', 'someone@example.com', '  ']) {
      final analysis = OpenAiCoffeeAnalysis(ai: ai, firstName: () => bad);
      await analysis.analyze(const CoffeeImagePick(path: _validAsset));
      expect(ai.lastPersonalization, isNull, reason: 'rejected for "$bad"');
    }
  });

  test(
    'authoritative backend interpretation reaches the composed reading and the Journal unchanged',
    () async {
      final ai = _RecordingCoffeeAi();
      final analysis = OpenAiCoffeeAnalysis(ai: ai, firstName: () => 'Deniz');
      final reading = await analysis.analyze(const CoffeeImagePick(path: _validAsset));
      expect(reading.overall, _goodOverall);
      final entry = DiscoveryJournalMap.coffee(reading);
      expect(entry.title, contains('yarım kalmış'));
    },
  );

  test('relevant recurring themes reach the writer as personalization', () async {
    final ai = _RecordingCoffeeAi();
    final analysis = OpenAiCoffeeAnalysis(
      ai: ai,
      relevantThemes: () => ['karar verme', 'iş değişikliği'],
    );
    await analysis.analyze(const CoffeeImagePick(path: _validAsset));
    expect(ai.lastPersonalization, {
      'relevantThemes': ['karar verme', 'iş değişikliği'],
    });
  });

  test('relevant sourced memory reaches writer and lookup failure is soft',
      () async {
    final withMemory = _RecordingCoffeeAi();
    await OpenAiCoffeeAnalysis(
      ai: withMemory,
      relevantThemes: () => ['kariyer'],
      memorySummary: (_) => '[tarot | 2026-09-07 | t1] Kariyer kararı.',
    ).analyze(const CoffeeImagePick(path: _validAsset));
    expect(withMemory.lastPersonalization!['memorySummary'], contains('t1'));

    final failingMemory = _RecordingCoffeeAi();
    final reading = await OpenAiCoffeeAnalysis(
      ai: failingMemory,
      relevantThemes: () => ['kariyer'],
      memorySummary: (_) => throw StateError('memory unavailable'),
    ).analyze(const CoffeeImagePick(path: _validAsset));
    expect(reading.overall, isNotEmpty);
    expect(failingMemory.lastPersonalization!.containsKey('memorySummary'),
        isFalse);
  });

  test('themes are capped to 3 and blank entries are dropped', () async {
    final ai = _RecordingCoffeeAi();
    final analysis = OpenAiCoffeeAnalysis(
      ai: ai,
      relevantThemes: () => ['a', '  ', 'b', 'c', 'd', 'e'],
    );
    await analysis.analyze(const CoffeeImagePick(path: _validAsset));
    expect(ai.lastPersonalization!['relevantThemes'], ['a', 'b', 'c']);
  });

  test(
    'D: personalization is instance-scoped — one accessor never leaks '
    'another instance/profile\'s themes or name',
    () async {
      final aiA = _RecordingCoffeeAi();
      final analysisA = OpenAiCoffeeAnalysis(
        ai: aiA,
        firstName: () => 'Deniz',
        relevantThemes: () => ['karar verme'],
      );
      final aiB = _RecordingCoffeeAi();
      final analysisB = OpenAiCoffeeAnalysis(
        ai: aiB,
        firstName: () => 'Kaya',
        relevantThemes: () => ['sınırlar'],
      );
      await analysisA.analyze(const CoffeeImagePick(path: _validAsset));
      await analysisB.analyze(const CoffeeImagePick(path: _validAsset));
      expect(aiA.lastPersonalization, {
        'firstName': 'Deniz',
        'relevantThemes': ['karar verme'],
      });
      expect(aiB.lastPersonalization, {
        'firstName': 'Kaya',
        'relevantThemes': ['sınırlar'],
      });
    },
  );

  test(
    'C: only genuinely recurring themes are ever eligible — an isolated '
    '(non-recurring) observation is never treated as relevant context',
    () {
      final profile = PersonalDiscoveryProfile(
        crossInsights: [
          CrossDiscoveryInsight(
            theme: 'sınırlar',
            sources: ['tarot', 'coffee'],
            confidence: DiscoveryThemeStrength.recurring,
            lastObserved: DateTime(2026, 8, 20),
            sourceCount: 2,
            discoveryCount: 2,
            recencyWeight: 1,
          ),
        ],
        themeSignals: [
          DiscoveryThemeSignal(
            label: 'tek seferlik gözlem',
            strength: DiscoveryThemeStrength.observed,
            discoveryCount: 1,
            sources: ['dream'],
          ),
        ],
      );
      expect(profile.observedRecurringLabels, ['sınırlar']);
      expect(profile.observedRecurringLabels, isNot(contains('tek seferlik gözlem')));
    },
  );

  test('wire payload includes personalization only when present', () {
    final withName = OpenAiPaidRequests.coffee(
      model: 'gpt-test',
      imageBytes: const [1, 2, 3],
      mimeType: 'image/jpeg',
      personalization: const {'firstName': 'Deniz'},
    );
    expect(withName.payload['personalization'], {'firstName': 'Deniz'});

    final withoutName = OpenAiPaidRequests.coffee(
      model: 'gpt-test',
      imageBytes: const [1, 2, 3],
      mimeType: 'image/jpeg',
    );
    expect(withoutName.payload.containsKey('personalization'), isFalse);
  });
}
