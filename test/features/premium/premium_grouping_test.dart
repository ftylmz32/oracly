/// Premium groups real experiences only — no invented purchasable features.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/features/premium/copy/soul_mate_copy.dart';
import 'package:oracly_new/features/premium/models/premium_models.dart';

void main() {
  test('premium experiences list only implemented gated features', () {
    final experiences = PremiumCatalogue.premiumExperiences;
    expect(experiences, hasLength(3));
    expect(
      experiences.map((b) => b.title),
      containsAll([
        SoulMateCopy.listTitle,
        PremiumCopy.benefitOrTitle,
        PremiumCopy.benefitJourneyTitle,
      ]),
    );
    expect(experiences.every((b) => b.requiresPremium), isTrue);
  });

  test('included capabilities stay honest and ungated', () {
    final included = PremiumCatalogue.includedCapabilities;
    expect(included, isNotEmpty);
    expect(included.every((b) => !b.requiresPremium), isTrue);
    expect(
      included.map((b) => b.title),
      isNot(contains(SoulMateCopy.listTitle)),
    );
    expect(
      PremiumCopy.gemNote(20),
      contains('20 Mücevher'),
    );
  });

  test('purchase copy stays unavailable without fake IAP', () {
    expect(PremiumCopy.ctaUnavailable, contains('henüz'));
    expect(PremiumCopy.ctaHint, contains('Hazır'));
  });

  test('unlock copy explains value without pressure', () {
    expect(PremiumCopy.unlocks, hasLength(3));
    expect(PremiumCopy.unlockTitle, 'NEDİR BU KATMAN');
    expect(PremiumCopy.whyTitle, 'NEDEN VAR');
    expect(PremiumCopy.gateTitle.toLowerCase(), isNot(contains('gerekli')));
    expect(PremiumCopy.unlocks.join(), isNot(contains('son şans')));
    expect(PremiumCopy.ctaUnavailable, contains('henüz'));
  });
}
