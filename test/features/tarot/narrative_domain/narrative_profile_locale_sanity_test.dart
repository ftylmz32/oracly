import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_card_profile.dart';

import '../../../support/narrative_tarot_v2/narrative_tarot_v2_language.dart';

/// Full-body locale sanity for every registered V2 profile.
///
/// Reuses Phase 2.1 [Ntv2LanguageContract] (test-only). Does not claim
/// linguistic perfection — fails wrong-language-dominant bodies.
void main() {
  String body(NarrativeCardProfile p, String loc) {
    final buf = StringBuffer();
    for (final f in p.semanticFields) {
      buf.writeln(f.of(loc));
    }
    return buf.toString();
  }

  test('all 50 registered V2 profiles pass TR/EN/RU locale sanity', () {
    expect(NarrativeTarotProfileCatalog.all.length, 50);
    for (final p in NarrativeTarotProfileCatalog.all) {
      final tr = body(p, 'tr');
      final en = body(p, 'en');
      final ru = body(p, 'ru');

      expect(
        Ntv2LanguageContract.isMismatch('tr', tr),
        isFalse,
        reason: '${p.canonicalCardId} TR body language mismatch',
      );
      expect(
        RegExp(r'[А-Яа-яЁё]').hasMatch(tr),
        isFalse,
        reason: '${p.canonicalCardId} TR must not be Cyrillic',
      );

      expect(
        Ntv2LanguageContract.isMismatch('en', en),
        isFalse,
        reason: '${p.canonicalCardId} EN body language mismatch',
      );

      expect(
        Ntv2LanguageContract.isMismatch('ru', ru),
        isFalse,
        reason: '${p.canonicalCardId} RU body language mismatch',
      );
      expect(
        RegExp(r'[А-Яа-яЁё]').hasMatch(ru),
        isTrue,
        reason: '${p.canonicalCardId} RU must contain Cyrillic',
      );
    }
  });
}
