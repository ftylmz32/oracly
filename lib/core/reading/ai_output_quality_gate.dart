/// Lightweight validation + polish before user-facing AI output.
library;

import '../../features/insights/services/reflective_intelligence.dart';
import 'ai_output_quality_checks.dart';
import 'ai_output_quality_context.dart';
import 'ai_output_quality_kind.dart';
import 'ai_output_quality_result.dart';
import 'human_reader_guard.dart';
import 'robotic_language_rewrite.dart';

abstract final class AiOutputQualityGate {
  AiOutputQualityGate._();

  static String polish(
    String text, {
    AiOutputQualityKind kind = AiOutputQualityKind.tarot,
  }) {
    if (text.trim().isEmpty) return text;
    var out = ReflectiveIntelligence.soften(text);
    out = HumanReaderGuard.scrub(out);
    out = RoboticLanguageRewrite.bounded(out);
    return out.trim();
  }

  static AiOutputQualityResult validate(
    String text, {
    required AiOutputQualityKind kind,
    AiOutputQualityContext context = const AiOutputQualityContext(),
  }) {
    final failure = AiOutputQualityChecks.firstFailure(
      text,
      kind: kind,
      context: context,
    );
    if (failure == null) return const AiOutputQualityResult.pass();
    return AiOutputQualityResult.fail(failure);
  }

  static String ensurePolished(
    String text, {
    required AiOutputQualityKind kind,
    AiOutputQualityContext context = const AiOutputQualityContext(),
  }) {
    final polished = polish(text, kind: kind);
    final check = validate(polished, kind: kind, context: context);
    return check.isAcceptable ? polished : '';
  }
}
