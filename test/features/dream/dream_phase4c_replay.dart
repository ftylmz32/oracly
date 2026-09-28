/// Dream Phase 4C — offline client replay of one backend-accepted body,
/// step for step as `DreamInsightBuilder.build` runs it (no provider call):
/// parser → output safety → mapper/composer/guard → delivery quality →
/// provenance, plus a per-field layer diagnosis and rewrite audit.
library;

import 'package:oracly_new/core/copy/fortune_voice.dart';
import 'package:oracly_new/core/reading/ai_output_quality_context.dart';
import 'package:oracly_new/core/reading/ai_output_quality_gate.dart';
import 'package:oracly_new/core/reading/ai_output_quality_kind.dart';
import 'package:oracly_new/core/reading/human_reader.dart';
import 'package:oracly_new/features/ai/production/openai/dream_analysis_parser.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/models/dream_emotion.dart';
import 'package:oracly_new/features/dream/models/dream_insight.dart';
import 'package:oracly_new/features/dream/safety/dream_output_safety.dart';
import 'package:oracly_new/features/dream/services/dream_ai_insight_mapper.dart';
import 'package:oracly_new/features/dream/services/dream_analysis_facts.dart';
import 'package:oracly_new/features/dream/services/dream_analysis_guard.dart';
import 'package:oracly_new/features/dream/services/dream_narrative_language.dart';
import 'package:oracly_new/features/dream/services/dream_premium_delivery_quality.dart';
import 'package:oracly_new/features/dream/services/dream_provider_evidence.dart';
import 'package:oracly_new/features/dream/services/dream_reading_provenance.dart';
import 'package:oracly_new/features/dream/services/dream_understanding_service.dart';

import 'dream_phase4c_rewrite.dart';

const _fields = <String, DreamInsightKind>{
  'summary': DreamInsightKind.summary,
  'emotionalTheme': DreamInsightKind.emotionalMeaning,
  'interpretation': DreamInsightKind.mainInterpretation,
  'dailyLifeReflection': DreamInsightKind.personalConnection,
  'conclusion': DreamInsightKind.closingTakeaway,
};

/// The first client layer that refuses [original]; null when the guard
/// would speak it. Replayed bodies are provider AI (no local style layer).
String? rejectionLayer(String original, DreamAnalysisFacts facts,
    {bool closing = false, DreamGuardRole role = DreamGuardRole.dream}) {
  if (closing && DreamAnalysisGuard.questionMarks(original) != 1) {
    return 'DreamAnalysisGuard.questionCount';
  }
  final text = HumanReader.guard(FortuneVoice.scrub(original)).trim();
  if (text.length < 24) return 'DreamAnalysisGuard.tooShort';
  if (DreamAnalysisGuard.looksDictionary(text)) {
    return 'DreamAnalysisGuard.dictionary';
  }
  if (FortuneVoice.claimsMedical(text)) return 'FortuneVoice.claimsMedical';
  if (FortuneVoice.claimsCertainty(text)) return 'FortuneVoice.claimsCertainty';
  final gate = AiOutputQualityGate.validate(
    text,
    kind: AiOutputQualityKind.dream,
    context: AiOutputQualityContext(localeCode: facts.language),
  );
  if (!gate.isAcceptable) return 'AiOutputQualityGate.${gate.category?.name}';
  if (!DreamAnalysisGuard.isSpeakable(text, facts,
      role: role, source: DreamGuardSource.providerAi)) {
    return 'DreamAnalysisGuard.inventedImageOrUngrounded';
  }
  return null;
}

Map<String, dynamic> replayClient({
  required String runId,
  required String narrative,
  required String appLanguage,
  required Map<String, dynamic> data,
  List<DreamEmotion> selectedEmotions = const [],
  String? memorySummary,
}) {
  final language = DreamNarrativeLanguage.forOperation(narrative, appLanguage);
  final understanding = DreamUnderstandingService().build(
    narrative: narrative,
    selectedEmotions: selectedEmotions,
    language: language,
  );
  final dream = Dream(
    id: 'qa4c-$runId',
    narrative: narrative,
    recordedAt: DateTime(2026, 9, 28, 8),
    selectedEmotions: selectedEmotions,
    understanding: understanding,
  );
  final analysis = DreamAnalysisParser.fromMap(data);
  if (analysis == null || DreamOutputSafety.isUnsafe(analysis)) {
    return {
      'runId': runId,
      'clientLanguage': language,
      'clientResult': analysis == null ? 'FAIL_PARSE' : 'FAIL_OUTPUT_SAFETY',
    };
  }
  final insights = DreamAiInsightMapper.map(
    analysis: analysis,
    dream: dream,
    understanding: understanding,
    language: language,
    memorySummary: memorySummary,
  );
  final facts = DreamAnalysisFacts.from(
    narrative: narrative,
    understanding: understanding,
    tags: const [],
    statedFeelings:
        DreamProviderEvidence.emotions(dream, understanding, language),
    language: language,
  );
  final gap = DreamPremiumDeliveryQuality.firstGap(insights);
  final fields = <String, dynamic>{};
  for (final MapEntry(key: field, value: kind) in _fields.entries) {
    final original = data[field] as String;
    final section = insights.where((i) => i.kind == kind).firstOrNull;
    final ai = section?.source == DreamInsightSource.ai;
    final displayed = ai ? section!.body : null;
    final rewrite = rewriteClass(original, displayed);
    fields[field] = {
      'section': kind.name,
      'source': section?.source.name,
      'layer': ai
          ? null
          : rejectionLayer(
              original,
              kind == DreamInsightKind.personalConnection
                  ? facts.withContext(memorySummary)
                  : facts,
              closing: kind == DreamInsightKind.closingTakeaway,
              role: kind == DreamInsightKind.emotionalMeaning
                  ? DreamGuardRole.emotionalTheme
                  : DreamGuardRole.dream,
            ),
      'rewrite': rewrite,
      if (rewrite != 'unchanged') 'original': original,
      if (rewrite != 'unchanged' && displayed != null) 'displayed': displayed,
    };
  }
  final symbols = insights.where((i) => i.kind == DreamInsightKind.symbols);
  return {
    'runId': runId,
    'clientLanguage': language,
    'clientResult': gap == null ? 'PASS' : 'FAIL_DELIVERY',
    'clientGap': gap?.name,
    'requiredAiSections': DreamPremiumDeliveryQuality.required
        .where((k) => insights.any(
            (i) => i.kind == k && i.source == DreamInsightSource.ai))
        .length,
    'fromAi': DreamReadingProvenance.hasAcceptedAi(insights),
    'symbolsSource': symbols.firstOrNull?.source.name,
    'fields': fields,
  };
}
