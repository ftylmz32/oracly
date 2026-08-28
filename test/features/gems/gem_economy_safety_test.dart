/// P2 gem economy safety — single charge, no charge on fail/cancel, no double.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/features/daily_rewards/services/daily_rewards_service.dart';
import 'package:oracly_new/features/gems/copy/gems_copy.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/economy/gem_economy.dart';
import 'package:oracly_new/features/gems/models/gem_transaction.dart';
import 'package:oracly_new/features/gems/models/paid_ai_operation.dart';
import 'package:oracly_new/features/gems/services/gem_action_charge.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/gems/services/paid_ai_operation_coordinator.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_charge.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SlowGemStore extends GemWalletStore {
  _SlowGemStore(super.storage);

  @override
  Future<void> write({
    required int balance,
    required GemTransaction transaction,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await super.write(balance: balance, transaction: transaction);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late GemWalletService wallet;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    wallet = GemWalletService(GemWalletStore(storage));
    await wallet.earn(amount: 100, reason: GemsCopy.reasonDailyReward);
  });

  test('successful spend with operationId happens exactly once', () async {
    await wallet.spend(
      amount: 20,
      reason: GemsCopy.reasonTarot,
      operationId: 'op-once',
    );
    await wallet.spend(
      amount: 20,
      reason: GemsCopy.reasonTarot,
      operationId: 'op-once',
    );
    expect(wallet.balance, 80);
    expect(wallet.history.where((t) => t.amount < 0), hasLength(1));
  });

  test('insufficient spend never mutates balance', () async {
    final before = wallet.balance;
    expect(
      () => wallet.spend(amount: before + 1, reason: GemsCopy.reasonTarot),
      throwsA(isA<GemSpendException>()),
    );
    expect(wallet.balance, before);
  });

  test('rapid parallel spend with same id cannot double-charge', () async {
    Future<int> attempt() async {
      try {
        return await wallet.spend(
          amount: 20,
          reason: GemsCopy.reasonTarot,
          operationId: 'race-id',
        );
      } on GemSpendException {
        return wallet.balance;
      }
    }

    await Future.wait([attempt(), attempt()]);
    expect(wallet.balance, 80);
    expect(wallet.history.where((t) => t.id == 'race-id'), hasLength(1));
  });

  test('GemActionCharge free / zero cost never deducts', () async {
    final charge = GemActionCharge(
      wallet,
      storage,
      ledgerKey: 'safety_free_ledger',
    );
    expect(
      await charge.commit(
        actionId: 'free',
        cost: null,
        reason: GemsCopy.reasonCoffee,
      ),
      isTrue,
    );
    expect(wallet.balance, 100);
  });

  test('failed charge after providerOk is abandoned — reconcile does not bill',
      () async {
    SharedPreferences.setMockInitialValues({});
    final isolated = LocalStorage(await SharedPreferences.getInstance());
    final poor = GemWalletService(GemWalletStore(isolated));
    final charge = TarotReadingCharge(poor, isolated);
    await charge.markProviderOk(
      'sess-poor',
      spread: TarotSpreadType.threeCard,
    );
    expect(
      await charge.commit('sess-poor', spread: TarotSpreadType.threeCard),
      isFalse,
    );
    await charge.abandon('sess-poor', spread: TarotSpreadType.threeCard);
    final ops = PaidAiOperationCoordinator(wallet: poor, storage: isolated);
    expect(await ops.reconcile(), 0);
    expect(poor.balance, 0);
  });

  test('reconcile settles providerOk once and clears stale pending', () async {
    final ops = PaidAiOperationCoordinator(wallet: wallet, storage: storage);
    final pending = await ops.begin(
      feature: PaidAiFeature.coffee,
      ledgerKey: 'coffee_gem_charged',
      reason: GemsCopy.reasonCoffee,
      cost: 20,
    );
    final owed = await ops.begin(
      feature: PaidAiFeature.palm,
      ledgerKey: 'palm_gem_charged',
      reason: GemsCopy.reasonPalm,
      cost: 20,
      existingId: 'palm-owed',
    );
    await ops.markProviderOk(owed.id);
    expect(await ops.reconcile(), 1);
    expect(wallet.balance, 80);
    expect(ops.store.byId(pending.id)?.status, PaidAiOperationStatus.abandoned);
    expect(ops.store.needingSettle(), isEmpty);
    expect(await ops.reconcile(), 0);
    expect(wallet.balance, 80);
  });

  test('daily claim earns before locking the day', () async {
    SharedPreferences.setMockInitialValues({});
    final s = LocalStorage(await SharedPreferences.getInstance());
    final w = GemWalletService(_SlowGemStore(s));
    final day = DateTime(2026, 8, 22);
    final blocker = w.earn(amount: 1, reason: 'hold');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final rewards = DailyRewardsService(MockUserRepository(s), s, w);
    final blocked = await rewards.claim(asOf: day);
    await blocker;
    expect(blocked.claimedToday, isFalse);
    expect(s.getString(DailyRewardsService.claimedKey), isNull);

    final ok = await rewards.claim(asOf: day);
    expect(ok.claimedToday, isTrue);
    expect(w.balance, 1 + GemEconomy.dailyReward);
  });

  test('parallel daily claims grant gems once', () async {
    SharedPreferences.setMockInitialValues({});
    final s = LocalStorage(await SharedPreferences.getInstance());
    final w = GemWalletService(GemWalletStore(s));
    final rewards = DailyRewardsService(MockUserRepository(s), s, w);
    final day = DateTime(2026, 8, 22);
    await Future.wait([
      rewards.claim(asOf: day),
      rewards.claim(asOf: day),
    ]);
    expect(w.balance, GemEconomy.dailyReward);
  });

  test('displayed store balance matches wallet after charge', () async {
    final charge = GemActionCharge(
      wallet,
      storage,
      ledgerKey: 'display_ledger',
    );
    await charge.commit(
      actionId: 'display-1',
      cost: GemEconomy.tarotReading,
      reason: GemsCopy.reasonTarot,
    );
    expect(GemWalletStore(storage).balance(), wallet.balance);
    expect(wallet.balance, 100 - GemEconomy.tarotReading);
  });
}