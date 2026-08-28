/// Tarot interpretation quality — all visible sections must pass.
library;

import '../../features/tarot/interpretation/models/interpretation_result.dart';
import 'ai_output_quality_category.dart';
import 'ai_output_quality_gate.dart';
import 'ai_output_quality_kind.dart';

abstract final class AiOutputQualityTarot {
  AiOutputQualityTarot._();

  static const _kind = AiOutputQualityKind.tarot;

  static bool passes(InterpretationResult result) =>
      firstFailure(result) == null && result.summary.trim().isNotEmpty;

  static AiOutputQualityCategory? firstFailure(InterpretationResult result) {
    for (final field in _fields(result)) {
      if (field.trim().isEmpty) continue;
      final check = AiOutputQualityGate.validate(field, kind: _kind);
      if (!check.isAcceptable) return check.category;
    }
    return null;
  }

  static Iterable<String> _fields(InterpretationResult result) sync* {
    yield result.summary;
    yield result.love;
    yield result.career;
    yield result.money;
    yield result.health;
    yield result.spiritualGuidance;
    yield result.advice;
    yield result.warnings;
    yield result.luckyEnergy;
    yield result.dailyFocus;
    yield result.closingMessage;
  }
}
