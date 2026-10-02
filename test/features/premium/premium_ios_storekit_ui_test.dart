/// iOS Premium screen rendering for each StoreKit catalogue outcome.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/shared/widgets/oracly_gold_button.dart';

import 'support/ios_premium_screen_harness.dart';
import 'support/ios_storekit_fake.dart';

void main() {
  iosPremiumTest('monthly + yearly returned: both plans render with store '
      'prices', (tester) async {
    await pumpIosPremium(
      tester,
      FakeStoreKit(products: [monthlyProduct, yearlyProduct]),
    );
    expect(find.text(PremiumCopy.planMonthlyLabel), findsOneWidget);
    expect(find.text(PremiumCopy.planYearlyLabel), findsOneWidget);
    expect(find.text('STORE-MONTHLY'), findsOneWidget);
    expect(find.text('STORE-YEARLY'), findsOneWidget);
    expect(find.text(PremiumCopy.planPricePending), findsNothing);
    expect(find.byType(OraclyGoldButton), findsWidgets);
    expect(find.text(PremiumCopy.ctaUnavailable), findsNothing);
  });

  iosPremiumTest('lifetime never renders on iOS, even if the store returns '
      'it', (tester) async {
    await pumpIosPremium(
      tester,
      FakeStoreKit(
        products: [monthlyProduct, yearlyProduct, lifetimeProduct],
        returnUnrequested: true,
      ),
    );
    expect(find.text(PremiumCopy.planLifetimeLabel), findsNothing);
    expect(find.text('STORE-LIFETIME'), findsNothing);
  });

  for (final (label, product, ownLabel, missingLabel) in [
    (
      'only monthly',
      monthlyProduct,
      PremiumCopy.planMonthlyLabel,
      PremiumCopy.planYearlyLabel,
    ),
    (
      'only yearly',
      yearlyProduct,
      PremiumCopy.planYearlyLabel,
      PremiumCopy.planMonthlyLabel,
    ),
  ]) {
    iosPremiumTest('$label returned: only that plan renders, no pending '
        'price', (tester) async {
      await pumpIosPremium(tester, FakeStoreKit(products: [product]));
      expect(find.text(product.price), findsOneWidget);
      expect(find.text(ownLabel), findsOneWidget);
      expect(find.text(missingLabel), findsNothing);
      expect(find.text(PremiumCopy.planPricePending), findsNothing);
      expect(find.byType(OraclyGoldButton), findsWidgets);
      expect(find.text(PremiumCopy.ctaUnavailable), findsNothing);
    });
  }

  iosPremiumTest('zero products: honest unavailable plaque with Retry + '
      'Restore', (tester) async {
    await pumpIosPremium(tester, FakeStoreKit());
    expect(find.text(PremiumCopy.planMonthlyLabel), findsNothing);
    expect(find.text(PremiumCopy.planYearlyLabel), findsNothing);
    expect(find.text(PremiumCopy.planPricePending), findsNothing);
    expect(find.text(PremiumCopy.ctaUnavailable), findsOneWidget);
    expect(find.text(PremiumCopy.ctaRetryStore), findsOneWidget);
    expect(find.text(PremiumCopy.ctaRestore), findsOneWidget);
  });

  iosPremiumTest('store unavailable: plaque with Retry, no Restore', (
    tester,
  ) async {
    await pumpIosPremium(tester, FakeStoreKit(available: false));
    expect(find.text(PremiumCopy.ctaUnavailable), findsOneWidget);
    expect(find.text(PremiumCopy.ctaRetryStore), findsOneWidget);
    expect(find.text(PremiumCopy.ctaRestore), findsNothing);
  });
}
