/// Phase 2 CONTRACT HARNESS — questionGrounding (offline corpus contract).
///
/// Length alone never proves grounding. Prefer fixture groundingAnchors.
library;

import 'narrative_tarot_v2_hard_failures.dart';
import 'narrative_tarot_v2_models.dart';
import 'narrative_tarot_v2_text.dart';

abstract final class Ntv2QuestionGrounding {
  static bool evaluate(
    Ntv2Scenario s,
    String text, {
    required bool irrMem,
    required bool sycophancy,
    required bool legacy,
    required bool repetitive,
    required bool cert,
    required bool genericity,
    required Set<String> hard,
  }) {
    if (hard.contains(Ntv2HardFailure.languageMismatch)) return true;
    final onlyRef =
        hard.isNotEmpty &&
        hard.difference(Ntv2HardFailure.referential).isEmpty &&
        !hard.contains(Ntv2HardFailure.fabricatedRecurrence);
    if (onlyRef) return true;
    if (irrMem || sycophancy || legacy || repetitive || cert) return false;
    if (genericity &&
        s.locale == 'tr' &&
        Ntv2TextHeuristics.englishStockDensity(text) >= 3) {
      return false;
    }
    if (genericity &&
        RegExp(
              r'kendine güven|pozitif kal|her şey yoluna|evren sana',
              caseSensitive: false,
            ).allMatches(text).length >=
            2) {
      return false;
    }

    final kind = '${s.input['questionKind'] ?? ''}'.trim();
    final anchors = ((s.input['groundingAnchors'] as List?) ?? const [])
        .cast<String>()
        .map((a) => a.trim().toLowerCase())
        .where((a) => a.isNotEmpty)
        .toList();

    // Open / no-question: no forced keyword overlap.
    if (kind == 'none' ||
        kind == 'open' ||
        (kind.isEmpty &&
            '${s.input['questionText'] ?? ''}'.trim().isEmpty &&
            anchors.isEmpty)) {
      return true;
    }

    final lower = text.toLowerCase();
    if (anchors.isNotEmpty) {
      return anchors.any(lower.contains);
    }

    // Fallback: question/topic token overlap — never length-alone.
    final seed = [
      '${s.input['questionText'] ?? ''}',
      '${s.input['topic'] ?? ''}',
      '${s.input['intention'] ?? ''}',
    ].join(' ');
    final tokens = seed
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((t) => t.length > 3)
        .take(6);
    var hits = 0;
    for (final t in tokens) {
      if (lower.contains(t)) hits++;
    }
    return hits > 0;
  }
}
