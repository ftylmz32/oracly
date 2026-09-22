/// Phase 2 CONTRACT HARNESS — questionGrounded heuristic.
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
    final q = '${s.input['questionText'] ?? ''}'.trim();
    if (q.isEmpty) return true;
    final tokens = q
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((t) => t.length > 3)
        .take(4);
    final lower = text.toLowerCase();
    var hits = 0;
    for (final t in tokens) {
      if (lower.contains(t)) hits++;
    }
    return hits > 0 || lower.length > 40;
  }
}
