/// Dream Phase 2.1 — runs the real service and captures the provider context.
library;

import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/openai/openai_paid_requests.dart';
import 'package:oracly_new/features/dream/models/dream_emotion.dart';
import 'package:oracly_new/features/dream/models/dream_entry_context.dart';
import 'package:oracly_new/features/dream/models/dream_entry_selection.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';

import '../../support/dream_test_owner.dart';
import 'dream_honesty_fakes.dart';
import 'dream_phase2_support.dart';

const enTold = 'I walked toward a door by the sea and felt uneasy.';
const ruTold =
    'Мне снилось, что я шла по тихому лесу, а за деревьями светилось окно старого дома.';
const trTold = 'Rüyamda sessiz bir ev ve açık bir pencere vardı, kapı aralıktı.';

DreamEntrySelection entryWith(
  DreamGuidedQuestionId question,
  String answer, {
  DreamEntryChipId chip = DreamEntryChipId.nightmare,
}) =>
    DreamEntrySelection.of(chips: {chip}, guided: {question: answer});

/// Runs DreamExperienceService → DreamInsightBuilder under [app] locale and
/// returns the DreamAiContext the provider would receive.
Future<(DreamAiContext, MemDreamRepository, DreamExperienceService)> send(
  String told, {
  required String app,
  DreamEntrySelection? entry,
  List<DreamEmotionId> chips = const [DreamEmotionId.fearful],
  ScriptedDreamAi? ai,
}) async {
  OraclyL10n.bind(app);
  final scripted = ai ?? ScriptedDreamAi(phase2AllRejected);
  final repo = MemDreamRepository();
  final service = DreamExperienceService(
    repository: repo,
    owner: testDreamOwner(),
    ai: scripted,
  );
  await service.analyze(
    narrative: told,
    selectedEmotions: [for (final id in chips) DreamEmotion(id: id)],
    tags: const ['display tag as shown at entry'],
    entry: entry,
  );
  return (scripted.contexts.last, repo, service);
}

Map<String, dynamic> payloadOf(DreamAiContext context) =>
    OpenAiPaidRequests.dream(model: 'm', context: context).payload;
