/// Production-safe structural validation for NarrativeCardProfile.
library;

import '../../../../core/l10n/l10n_triple.dart';
import 'narrative_card_profile.dart';
import 'narrative_symbol_tags.dart';

abstract final class NarrativeCardProfileValidator {
  static bool isComplete(NarrativeCardProfile p) {
    if (p.canonicalCardId.trim().isEmpty) return false;
    if (p.profileRevision < 1) return false;
    if (p.symbolTags.isEmpty) return false;
    if (p.symbolTags.any((t) => !NarrativeSymbolTags.all.contains(t))) {
      return false;
    }
    if (p.reversed.transforms.isEmpty) return false;
    for (final field in p.semanticFields) {
      if (!_tripleFilled(field)) return false;
    }
    return true;
  }

  static bool uprightDiffersFromReversed(NarrativeCardProfile p) {
    return !_sameTriple(p.upright.expression, p.reversed.expression);
  }

  /// True when most semantic fields collapse to the same string per locale.
  static bool hasMechanicalFieldDuplication(NarrativeCardProfile p) {
    for (final loc in const ['tr', 'en', 'ru']) {
      final values = p.semanticFields
          .map((f) => f.of(loc).trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (values.length < 5) continue;
      final unique = values.toSet();
      if (unique.length <= 2) return true;
    }
    return false;
  }

  static String primarySignature(NarrativeCardProfile p) {
    final parts = <String>[];
    for (final f in p.semanticFields) {
      parts.add(f.en.trim().toLowerCase());
      parts.add(f.tr.trim().toLowerCase());
      parts.add(f.ru.trim().toLowerCase());
    }
    return parts.join('||');
  }

  static bool _tripleFilled(L10nTriple t) =>
      t.tr.trim().isNotEmpty &&
      t.en.trim().isNotEmpty &&
      t.ru.trim().isNotEmpty;

  static bool _sameTriple(L10nTriple a, L10nTriple b) =>
      a.tr.trim() == b.tr.trim() &&
      a.en.trim() == b.en.trim() &&
      a.ru.trim() == b.ru.trim();
}
