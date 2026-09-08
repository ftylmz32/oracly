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
    final substantial = <Set<String>>[];
    for (final field in _fields(result)) {
      if (field.trim().isEmpty) continue;
      final check = AiOutputQualityGate.validate(field, kind: _kind);
      if (!check.isAcceptable) return check.category;

      final words = _normalizedWords(field);
      if (words.length >= 9) substantial.add(words);
    }

    for (var i = 0; i < substantial.length; i++) {
      for (var j = i + 1; j < substantial.length; j++) {
        if (_nearDuplicate(substantial[i], substantial[j])) {
          return AiOutputQualityCategory.repetitiveFiller;
        }
      }
    }
    return null;
  }

  static bool _nearDuplicate(Set<String> a, Set<String> b) {
    final smaller = a.length < b.length ? a : b;
    final larger = a.length < b.length ? b : a;
    var common = 0;
    for (final word in smaller) {
      if (larger.contains(word)) common++;
    }
    if (common < 8) return false;
    return common / smaller.length >= 0.86;
  }

  static Set<String> _normalizedWords(String raw) => raw
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9çğıöşü]+', caseSensitive: false), ' ')
      .split(RegExp(r'\s+'))
      .map((e) => e.trim())
      .where((e) => e.length > 1)
      .toSet();

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
