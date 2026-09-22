import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n_triple.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';

/// Phase 3C.1 — hard invariant: shadow ≠ reversed.expression.
void main() {
  String normalize(String raw) {
    var s = raw.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    s = s.replaceAll(RegExp(r'''[.,;:!?\-—–"'()\[\]]+'''), '');
    return s.trim();
  }

  bool sameLocale(L10nTriple a, L10nTriple b, String loc) {
    final left = normalize(a.of(loc));
    final right = normalize(b.of(loc));
    return left.isNotEmpty && left == right;
  }

  test('shadow and reversed.expression differ in TR/EN/RU for all 78', () {
    final clones = <String>[];
    for (final p in NarrativeTarotProfileCatalog.all) {
      for (final loc in const ['tr', 'en', 'ru']) {
        if (sameLocale(p.shadow, p.reversed.expression, loc)) {
          clones.add('${p.canonicalCardId}:$loc');
        }
      }
    }
    expect(clones, isEmpty, reason: clones.join(', '));
  });
}
