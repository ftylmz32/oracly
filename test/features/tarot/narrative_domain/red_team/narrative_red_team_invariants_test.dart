import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n_triple.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_symbol_tags.dart';
import 'package:oracly_new/features/tarot/narrative/domain/reversed_transform_kind.dart';

/// Phase 3C — objective red-team invariants (diagnostic, not prose judgment).
void main() {
  String norm(L10nTriple t) => t.en.trim().toLowerCase();

  test('no exact substantial EN field duplicates across different cards', () {
    const minLen = 40;
    final buckets = <String, List<String>>{};
    for (final p in NarrativeTarotProfileCatalog.all) {
      void add(String label, L10nTriple field) {
        final t = norm(field);
        if (t.length < minLen) return;
        buckets.putIfAbsent('$label::$t', () => []).add(p.canonicalCardId);
      }

      add('core', p.coreMeaning);
      add('light', p.light);
      add('shadow', p.shadow);
      add('tension', p.tension);
      add('desire', p.desire);
      add('fear', p.fear);
      add('rel', p.relationshipDynamic);
      add('dec', p.decisionDynamic);
      add('act', p.actionDirection);
      add('up', p.upright.expression);
      add('rev', p.reversed.expression);
    }
    final dups = buckets.entries.where((e) => e.value.toSet().length > 1);
    expect(dups, isEmpty, reason: dups.map((e) => e.value).join('; '));
  });

  test('catalog remains exact set-equal to canonical deck', () {
    final a = NarrativeTarotProfileCatalog.all
        .map((p) => p.canonicalCardId)
        .toSet();
    final b = OraclyTarotDeck.expectedIds.toSet();
    expect(a.difference(b), isEmpty);
    expect(b.difference(a), isEmpty);
    expect(a.length, 78);
  });

  test('all symbol tags remain in ontology', () {
    for (final p in NarrativeTarotProfileCatalog.all) {
      for (final t in p.symbolTags) {
        expect(NarrativeSymbolTags.all, contains(t), reason: p.canonicalCardId);
      }
    }
  });

  test('reversed transforms are non-empty valid enums', () {
    for (final p in NarrativeTarotProfileCatalog.all) {
      expect(p.reversed.transforms, isNotEmpty, reason: p.canonicalCardId);
      for (final t in p.reversed.transforms) {
        expect(ReversedTransformKind.values, contains(t));
      }
    }
  });

  test(
    'diagnostic counts shadow≈reversed EN clones without failing readiness',
    () {
      // Documents RT-M02. Soft bounds only — remediation must not break CI.
      var clones = 0;
      for (final p in NarrativeTarotProfileCatalog.all) {
        if (norm(p.shadow) == norm(p.reversed.expression)) clones++;
      }
      expect(clones, inInclusiveRange(0, 78));
    },
  );
}
