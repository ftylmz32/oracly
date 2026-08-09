import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/features/premium/models/premium_models.dart';

void main() {
  group('PremiumCopy', () {
    test('plan labels avoid FOMO and urgency language', () {
      expect(PremiumCopy.planYearlySubtitle.toLowerCase(), isNot(contains('popüler')));
      expect(PremiumCopy.planYearlySubtitle.toLowerCase(), isNot(contains('tasarruf')));
      expect(PremiumCopy.heroSubtitle.toLowerCase(), contains('isteğe bağlı'));
    });

    test('unavailable purchase copy is honest and non-purchasing', () {
      expect(
        PremiumCopy.purchaseUnavailableTitle,
        'Premium satın alma yakında kullanılabilir.',
      );
      expect(
        PremiumCopy.purchaseUnavailableBody,
        'Satın alma şu an mağaza üzerinden yapılamaz.',
      );
      expect(PremiumCopy.purchaseUnavailableTitle.toLowerCase(), isNot(contains('açıldı')));
      expect(PremiumCopy.purchaseUnavailableBody.toLowerCase(), isNot(contains('satın alındı')));
    });

    test('catalogue benefits avoid pressure framing', () {
      for (final benefit in PremiumCatalogue.benefits) {
        expect(benefit.description.toLowerCase(), isNot(contains('mutlaka')));
        expect(benefit.description.toLowerCase(), isNot(contains('hemen')));
      }
    });
  });
}
