/// Explicit reviewed keyword contrast table — Phase 3D.1B.
///
/// No string antonym inference. Unknown ids → invalidOntologyId.
library;

import '../domain/narrative_keyword_ids.dart';
import 'narrative_evidence_error.dart';

enum NarrativeKeywordContrastClass { hard, contextual }

abstract final class NarrativeKeywordContrasts {
  NarrativeKeywordContrasts._();

  /// Symmetric lookup. Returns null when pair is not in the locked table.
  static NarrativeKeywordContrastClass? between(String left, String right) {
    _requireOntology(left);
    _requireOntology(right);
    if (left == right) return null;
    final key = _pairKey(left, right);
    return _table[key];
  }

  static int get hardPairCount => _table.values
      .where((c) => c == NarrativeKeywordContrastClass.hard)
      .length;

  static int get contextualPairCount => _table.values
      .where((c) => c == NarrativeKeywordContrastClass.contextual)
      .length;

  static int get totalPairCount => _table.length;

  static void _requireOntology(String id) {
    if (!NarrativeKeywordIds.all.contains(id)) {
      throw NarrativeEvidenceException(
        NarrativeEvidenceErrorCode.invalidOntologyId,
        message: 'unknown keyword id: $id',
      );
    }
  }

  static String _pairKey(String a, String b) {
    if (a.compareTo(b) <= 0) return '$a|$b';
    return '$b|$a';
  }

  /// 11 HARD + 4 CONTEXTUAL = 15 unordered pairs (Phase 3D.0 §14).
  static final Map<String, NarrativeKeywordContrastClass> _table = {
    _pairKey(NarrativeKeywordIds.balance, NarrativeKeywordIds.imbalance):
        NarrativeKeywordContrastClass.hard,
    _pairKey(NarrativeKeywordIds.stability, NarrativeKeywordIds.instability):
        NarrativeKeywordContrastClass.hard,
    _pairKey(NarrativeKeywordIds.belonging, NarrativeKeywordIds.isolation):
        NarrativeKeywordContrastClass.hard,
    _pairKey(NarrativeKeywordIds.abundance, NarrativeKeywordIds.scarcity):
        NarrativeKeywordContrastClass.hard,
    _pairKey(NarrativeKeywordIds.clarity, NarrativeKeywordIds.confusion):
        NarrativeKeywordContrastClass.hard,
    _pairKey(NarrativeKeywordIds.truth, NarrativeKeywordIds.denial):
        NarrativeKeywordContrastClass.hard,
    _pairKey(NarrativeKeywordIds.union, NarrativeKeywordIds.isolation):
        NarrativeKeywordContrastClass.hard,
    _pairKey(NarrativeKeywordIds.opening, NarrativeKeywordIds.closing):
        NarrativeKeywordContrastClass.hard,
    _pairKey(NarrativeKeywordIds.joy, NarrativeKeywordIds.despair):
        NarrativeKeywordContrastClass.hard,
    _pairKey(NarrativeKeywordIds.hope, NarrativeKeywordIds.despair):
        NarrativeKeywordContrastClass.hard,
    _pairKey(NarrativeKeywordIds.listening, NarrativeKeywordIds.notListening):
        NarrativeKeywordContrastClass.hard,
    _pairKey(NarrativeKeywordIds.momentum, NarrativeKeywordIds.haste):
        NarrativeKeywordContrastClass.contextual,
    _pairKey(NarrativeKeywordIds.nurture, NarrativeKeywordIds.rescue):
        NarrativeKeywordContrastClass.contextual,
    _pairKey(NarrativeKeywordIds.pause, NarrativeKeywordIds.delay):
        NarrativeKeywordContrastClass.contextual,
    _pairKey(NarrativeKeywordIds.boundary, NarrativeKeywordIds.coldness):
        NarrativeKeywordContrastClass.contextual,
  };
}
