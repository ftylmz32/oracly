import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/models/paid_ai_operation.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_gateway.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/gems/services/paid_ai_operation_coordinator.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';

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
    expect(world.settleCalls, 2);
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
  _World({int initialBalance = 40}) : serverBalance = initialBalance {
    storage = LocalStorage.ephemeral();
    wallet = GemWalletService(
      GemWalletStore(storage),
      gateway: GemWalletGateway(_send),
    );
    ops = PaidAiOperationCoordinator(wallet: wallet, storage: storage);
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
