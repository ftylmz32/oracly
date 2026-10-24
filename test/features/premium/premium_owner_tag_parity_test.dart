/// The account tag sent to Play must equal the backend's
/// `premiumOwnerTag` byte for byte, or every tagged purchase would be
/// refused as another account's. Same constant as
/// backend/tests/billing-account-ownership.test.ts.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/storage/premium_purchase_attempt_store.dart';

void main() {
  test('owner tag matches the backend', () {
    expect(
      PremiumPurchaseAttemptStore.ownerTag('uid-account-a'),
      '34ab4ceb725c03573ce3b1659380289077c75df9d3ece5fc2eb12ddbc4ca76d5',
    );
  });
}
