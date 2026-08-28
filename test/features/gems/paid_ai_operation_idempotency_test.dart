/// Paid AI operation idempotency — no double charge, safe resume settle.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/gems/copy/gems_copy.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/models/paid_ai_operation.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/gems/services/paid_ai_operation_binder.dart';
import 'package:oracly_new/features/gems/services/paid_ai_operation_coordinator.dart';
import 'package:oracly_new/features/gems/services/paid_ai_operation_id.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late GemWalletService wallet;
  late PaidAiOperationCoordinator ops;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    wallet = GemWalletService(GemWalletStore(storage));
    ops = PaidAiOperationCoordinator(wallet: wallet, storage: storage);
    await wallet.earn(amount: 100, reason: GemsCopy.reasonDailyReward);
  });

  test('IDEMPOTENCY — same operation settles once', () async {
    final op = await ops.begin(
      feature: PaidAiFeature.coffee,
      ledgerKey: 'coffee_gem_charged',
      reason: GemsCopy.reasonCoffee,
      cost: 20,
    );
    expect(op.id.startsWith('or-'), isTrue);
    expect(await ops.completeAfterProvider(op), isTrue);
    expect(wallet.balance, 80);
    expect(await ops.completeAfterProvider(op), isTrue);
    expect(wallet.balance, 80);
    expect(wallet.history.where((t) => t.amount < 0), hasLength(1));
    expect(wallet.history.first.id, op.id);
  });

  test('IDEMPOTENCY — accidental retry reuses the same id', () async {
    final a = PaidAiOperationId.fromExisting('tarot', 'session-9');
    final b = PaidAiOperationId.fromExisting('tarot', 'session-9');
    expect(a, b);
    final first = await ops.begin(
      feature: PaidAiFeature.tarot,
      ledgerKey: 'tarot_gem_charged_sessions',
      reason: GemsCopy.reasonTarot,
      cost: 20,
      existingId: 'session-9',
    );
    final retry = await ops.begin(
      feature: PaidAiFeature.tarot,
      ledgerKey: 'tarot_gem_charged_sessions',
      reason: GemsCopy.reasonTarot,
      cost: 20,
      existingId: 'session-9',
    );
    expect(first.id, retry.id);
    await ops.completeAfterProvider(first);
    await ops.completeAfterProvider(retry);
    expect(wallet.balance, 80);
  });

  test('NO DOUBLE CHARGE — provider retry after success does not spend again',
      () async {
    final op = await ops.begin(
      feature: PaidAiFeature.soulmate,
      ledgerKey: 'soulmate_gem_charged',
      reason: GemsCopy.reasonSoulMate,
      cost: 20,
    );
    await ops.completeAfterProvider(op);
    await wallet.spend(amount: 20, reason: 'other', operationId: op.id);
    expect(wallet.balance, 80);
  });

  test('RECONCILIATION — resume settles providerOk leftover', () async {
    final op = await ops.begin(
      feature: PaidAiFeature.palm,
      ledgerKey: 'palm_gem_charged',
      reason: GemsCopy.reasonPalm,
      cost: 20,
    );
    await ops.markProviderOk(op.id);
    expect(wallet.balance, 100);
    final restarted = PaidAiOperationCoordinator(
      wallet: wallet,
      storage: storage,
    );
    expect(await restarted.reconcile(), 1);
    expect(wallet.balance, 80);
    expect(await restarted.reconcile(), 0);
    expect(wallet.balance, 80);
  });

  test('RECONCILIATION — lost response after provider ok then settle',
      () async {
    final op = await ops.begin(
      feature: PaidAiFeature.dream,
      ledgerKey: 'dream_gem_charged',
      reason: GemsCopy.reasonDream,
      cost: 20,
    );
    await ops.markProviderOk(op.id);
    final replay = await PaidAiOperationBinder.runWithKey(
      op.idempotencyKey,
      () async => PaidAiOperationBinder.idempotencyKey,
    );
    expect(replay, op.idempotencyKey);
    expect(await ops.settle(op), isTrue);
    expect(wallet.balance, 80);
    expect(await ops.settle(op), isTrue);
    expect(wallet.balance, 80);
  });

  test('NO DOUBLE CHARGE — provider failure never deducts', () async {
    final op = await ops.begin(
      feature: PaidAiFeature.coffee,
      ledgerKey: 'coffee_gem_charged',
      reason: GemsCopy.reasonCoffee,
      cost: 20,
    );
    await ops.abandon(op.id);
    expect(wallet.balance, 100);
    expect(ops.store.needingSettle(), isEmpty);
  });

  test('wallet never goes negative', () async {
    SharedPreferences.setMockInitialValues({});
    final isolated = LocalStorage(await SharedPreferences.getInstance());
    final poor = GemWalletService(GemWalletStore(isolated));
    expect(poor.balance, 0);
    expect(
      () => poor.spend(amount: 1, reason: GemsCopy.reasonTarot),
      throwsA(isA<GemSpendException>()),
    );
    expect(poor.balance, 0);
  });
}
