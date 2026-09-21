import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/data/paid_ai_operation_store.dart';
import 'package:oracly_new/features/gems/models/paid_ai_operation.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_gateway.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/gems/services/paid_ai_operation_coordinator.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/false_return_local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('provider failure never asks the server to debit', () async {
    final world = _World();
    final op = await world.ops.begin(
      feature: PaidAiFeature.tarot,
      ledgerKey: 'tarot',
      reason: 'tarot',
      cost: 20,
      existingId: 'provider-failure',
    );
    await world.ops.abandon(op.id);

    expect(world.settleCalls, 0);
    expect(world.serverBalance, 40);
  });

  test('usable result and replay settle one canonical server transaction', () async {
    final world = _World();
    final op = await world.ops.begin(
      feature: PaidAiFeature.tarot,
      ledgerKey: 'tarot',
      reason: 'tarot',
      cost: 999999,
      existingId: 'usable-result',
    );

    expect(await world.ops.completeAfterProvider(op), isTrue);
    expect(await world.ops.completeAfterProvider(op), isTrue);
    expect(world.serverBalance, 20);
    expect(world.wallet.balance, 20);
    // Second call is local-settled short-circuit — no second debit request.
    expect(world.settleCalls, 1);
  });

  test('lost response leaves providerOk and restart retries same operation', () async {
    final world = _World()..loseFirstResponse = true;
    final op = await world.ops.begin(
      feature: PaidAiFeature.tarot,
      ledgerKey: 'tarot',
      reason: 'tarot',
      cost: 20,
      existingId: 'lost-response',
    );

    expect(await world.ops.completeAfterProvider(op), isFalse);
    expect(world.ops.store.byId(op.id)?.status, PaidAiOperationStatus.providerOk);
    final restarted = PaidAiOperationCoordinator(
      wallet: world.wallet,
      storage: world.storage,
      store: world.ops.store,
    );
    expect(await restarted.reconcile(), 1);
    expect(world.serverBalance, 20);
    expect(restarted.store.byId(op.id)?.status, PaidAiOperationStatus.settled);
  });

  test(
    'billable begin fails before provider work when pending journal is not durable',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = FalseReturnLocalStorage(
        await SharedPreferences.getInstance(),
      )..falseReturnKeys.add(PaidAiOperationStore.key);
      final world = _World(storage: storage);

      await expectLater(
        () => world.ops.begin(
          feature: PaidAiFeature.tarot,
          ledgerKey: 'tarot',
          reason: 'tarot',
          cost: 20,
          existingId: 'journal-fail',
        ),
        throwsStateError,
      );

      expect(world.settleCalls, 0);
      expect(world.serverBalance, 40);
      expect(world.ops.store.all(), isEmpty);
    },
  );

  test(
    'providerOk promotion write loss still settles immediately with same operation',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = _FailNthStringListStorage(
        await SharedPreferences.getInstance(),
      );
      final world = _World(storage: storage);
      final op = await world.ops.begin(
        feature: PaidAiFeature.tarot,
        ledgerKey: 'tarot',
        reason: 'tarot',
        cost: 20,
        existingId: 'provider-marker-loss',
      );

      // #1 was durable pending. Fail #2 (providerOk promotion), allow #3
      // (settled marker after the authoritative server response).
      storage.failAt = 2;
      expect(await world.ops.completeAfterProvider(op), isTrue);

      expect(world.settleCalls, 1);
      expect(world.serverBalance, 20);
      expect(
        world.ops.store.byId(op.id)?.status,
        PaidAiOperationStatus.settled,
      );
    },
  );

  test(
    'settled-marker write loss keeps providerOk and restart replays idempotently',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = _FailNthStringListStorage(
        await SharedPreferences.getInstance(),
      );
      final world = _World(storage: storage);
      final op = await world.ops.begin(
        feature: PaidAiFeature.tarot,
        ledgerKey: 'tarot',
        reason: 'tarot',
        cost: 20,
        existingId: 'settled-marker-loss',
      );

      // #1 pending, #2 providerOk, #3 settled marker fails.
      storage.failAt = 3;
      expect(await world.ops.completeAfterProvider(op), isTrue);
      expect(world.serverBalance, 20);
      expect(
        world.ops.store.byId(op.id)?.status,
        PaidAiOperationStatus.providerOk,
      );

      storage.failAt = null;
      final restarted = PaidAiOperationCoordinator(
        wallet: world.wallet,
        storage: storage,
        store: world.ops.store,
      );
      expect(await restarted.reconcile(), 1);

      expect(world.serverBalance, 20);
      expect(world.settleCalls, 2);
      expect(
        restarted.store.byId(op.id)?.status,
        PaidAiOperationStatus.settled,
      );
    },
  );

  test(
    'server settlement stays successful when only local gem display cache fails',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = FalseReturnLocalStorage(
        await SharedPreferences.getInstance(),
      )..falseReturnKeys.add(GemWalletStore.serverBalanceCacheKey);
      final world = _World(storage: storage);
      final op = await world.ops.begin(
        feature: PaidAiFeature.tarot,
        ledgerKey: 'tarot',
        reason: 'tarot',
        cost: 20,
        existingId: 'cache-write-loss',
      );

      expect(await world.ops.completeAfterProvider(op), isTrue);

      expect(world.serverBalance, 20);
      expect(world.wallet.stale, isTrue);
      expect(
        world.ops.store.byId(op.id)?.status,
        PaidAiOperationStatus.settled,
      );
    },
  );

  test('insufficient server balance never creates local settled state', () async {
    final world = _World(initialBalance: 10);
    final op = await world.ops.begin(
      feature: PaidAiFeature.tarot,
      ledgerKey: 'tarot',
      reason: 'tarot',
      cost: 20,
      existingId: 'insufficient',
    );

    expect(await world.ops.completeAfterProvider(op), isFalse);
    expect(world.serverBalance, 10);
    expect(world.ops.store.byId(op.id)?.status, PaidAiOperationStatus.providerOk);
  });
}

class _World {
  _World({int initialBalance = 40, LocalStorage? storage})
      : serverBalance = initialBalance {
    this.storage = storage ?? LocalStorage.ephemeral();
    wallet = GemWalletService(
      GemWalletStore(this.storage),
      gateway: GemWalletGateway(_send),
    );
    ops = PaidAiOperationCoordinator(wallet: wallet, storage: this.storage);
  }

  late final LocalStorage storage;
  late final GemWalletService wallet;
  late final PaidAiOperationCoordinator ops;
  int serverBalance;
  int settleCalls = 0;
  bool loseFirstResponse = false;
  final Set<String> _settled = <String>{};

  Future<ReadingOperationWire?> _send(
    String method,
    String path,
    Map<String, Object>? body,
  ) async {
    if (path == '/v1/gems/balance') {
      return ReadingOperationWire(
        statusCode: 200,
        json: {'data': {'balance': serverBalance}},
      );
    }
    settleCalls += 1;
    final operationId = path.split('/')[4];
    if (serverBalance < 20 && !_settled.contains(operationId)) {
      return const ReadingOperationWire(statusCode: 409, json: {});
    }
    final first = _settled.add(operationId);
    if (first) serverBalance -= 20;
    if (loseFirstResponse && settleCalls == 1) return null;
    return ReadingOperationWire(
      statusCode: 200,
      json: {
        'data': {
          'balance': serverBalance,
          'settled': true,
          'idempotent': !first,
          'canonicalCost': 20,
        },
      },
    );
  }
}


class _FailNthStringListStorage extends LocalStorage {
  _FailNthStringListStorage(super.prefs);

  int setStringListAttempts = 0;
  int? failAt;

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    setStringListAttempts++;
    if (key == PaidAiOperationStore.key && failAt == setStringListAttempts) {
      return false;
    }
    return super.setStringList(key, value);
  }
}
