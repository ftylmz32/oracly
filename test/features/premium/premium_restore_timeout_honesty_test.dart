/// Restore timeout must fail closed — never pretend "none found".
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/services/store_premium_purchase_session.dart';

void main() {
  test('restore session timeout yields failed not noneFound', () async {
    final session = StorePremiumPurchaseSession();
    expect(session.begin(restore: true), isTrue);
    final result = await session.wait(const Duration(milliseconds: 20));
    expect(result.outcome, PremiumPurchaseOutcome.failed);
    expect(result.outcome, isNot(PremiumPurchaseOutcome.noneFound));
  });
}
