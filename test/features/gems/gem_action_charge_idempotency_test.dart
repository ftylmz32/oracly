/// Idempotency — same actionId never double-deducts.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/gems/copy/gems_copy.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/economy/gem_economy.dart';
import 'package:oracly_new/features/gems/services/gem_action_charge.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late GemWalletService wallet;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    wallet = GemWalletService(GemWalletStore(storage));
  });

  test('commit deducts exactly once for the same actionId', () async {
    await wallet.earn(
      amount: 100,
      reason: GemsCopy.reasonDailyReward,
    );
    final charger = GemActionCharge(
      wallet,
      storage,
      ledgerKey: 'test_ledger_idempotency',
    );

    expect(wallet.balance, 100);

    final ok1 = await charger.commit(
      actionId: 'action_1',
      cost: 20,
      reason: GemsCopy.reasonTarot,
    );
    expect(ok1, isTrue);
    expect(wallet.balance, 80);

    // Simulate double settle with the same actionId.
    final ok2 = await charger.commit(
      actionId: 'action_1',
      cost: 20,
      reason: GemsCopy.reasonTarot,
    );
    expect(ok2, isTrue);
    expect(wallet.balance, 80);
  });

  test('parallel duplicate commit deducts once', () async {
    await wallet.earn(
      amount: 100,
      reason: GemsCopy.reasonDailyReward,
    );
    final charger = GemActionCharge(
      wallet,
      storage,
      ledgerKey: 'test_ledger_parallel',
    );
    await Future.wait([
      charger.commit(
        actionId: 'race',
        cost: 20,
        reason: GemsCopy.reasonTarot,
      ),
      charger.commit(
        actionId: 'race',
        cost: 20,
        reason: GemsCopy.reasonTarot,
      ),
    ]);
    expect(wallet.history.where((t) => t.amount < 0), hasLength(1));
    expect(wallet.balance, 80);
  });

  test('commit with cost <= 0 never mutates', () async {
    await wallet.earn(
      amount: GemEconomy.dailyReward,
      reason: GemsCopy.reasonDailyReward,
    );
    final before = wallet.balance;
    final charger = GemActionCharge(
      wallet,
      storage,
      ledgerKey: 'test_ledger_zero_cost',
    );

    final ok = await charger.commit(
      actionId: 'x',
      cost: 0,
      reason: GemsCopy.reasonTarot,
    );
    expect(ok, isTrue);
    expect(wallet.balance, before);
  });
}

