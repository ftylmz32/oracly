/// Paid AI settle invariants — free OK; non-Tarot paid must fail closed.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/economy/coffee_economy.dart';
import 'package:oracly_new/features/gems/models/paid_ai_operation.dart';
import 'package:oracly_new/features/gems/services/paid_ai_operation_coordinator.dart';
import 'package:oracly_new/features/palm/economy/palm_economy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_gem_authority.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Coffee and Palm stay free — null analysis cost', () {
    expect(CoffeeEconomy.analysisCost, isNull);
    expect(PalmEconomy.analysisCost, isNull);
  });

  test('non-Tarot billable begin is refused explicitly', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final wallet = FakeGemAuthority(balance: 100).wallet(storage);
    final ops = PaidAiOperationCoordinator(wallet: wallet, storage: storage);
    await expectLater(
      () => ops.begin(
        feature: PaidAiFeature.coffee,
        ledgerKey: 'coffee_gem_charged',
        reason: 'coffee',
        cost: 20,
      ),
      throwsA(isA<UnsupportedError>()),
    );
  });

  test('free Coffee begin settles without Tarot endpoint', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final wallet = FakeGemAuthority(balance: 40).wallet(storage);
    await wallet.refresh();
    final ops = PaidAiOperationCoordinator(wallet: wallet, storage: storage);
    final op = await ops.begin(
      feature: PaidAiFeature.coffee,
      ledgerKey: 'coffee_gem_charged',
      reason: 'coffee',
      cost: CoffeeEconomy.analysisCost,
    );
    expect(op.isBillable, isFalse);
    expect(await ops.completeAfterProvider(op), isTrue);
    expect(wallet.balance, 40);
  });
}
