import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/features/premium/models/premium_models.dart';

void main() {
  group('PremiumCopy', () {
    test('plan labels avoid FOMO and urgency language', () {
      expect(PremiumCopy.planYearlySubtitle.toLowerCase(), isNot(contains('popüler')));
      expect(PremiumCopy.planYearlySubtitle.toLowerCase(), isNot(contains('tasarruf')));
      expect(PremiumCopy.heroLead.toLowerCase(), contains('isteğe bağlı'));
    });

    test('unavailable purchase copy is honest, not a buy CTA', () {
      expect(PremiumCopy.ctaUnavailable, contains('henüz'));
      expect(PremiumCopy.ctaJoin, "Premium'a Geç");
      expect(PremiumCopy.ctaExplore, "Premium'a Geç");
      expect(PremiumCopy.purchaseUnavailable, PremiumCopy.ctaUnavailable);
      expect(PremiumCopy.ctaUnavailable.toLowerCase(), isNot(contains('abone ol')));
      expect(PremiumCopy.ctaHint.toLowerCase(), contains('hazır'));
    });

    test('catalogue benefits avoid pressure framing', () {
      for (final benefit in PremiumCatalogue.benefits) {
        expect(benefit.description.toLowerCase(), isNot(contains('mutlaka')));
        expect(benefit.description.toLowerCase(), isNot(contains('hemen')));
      }
    });
  });
}
