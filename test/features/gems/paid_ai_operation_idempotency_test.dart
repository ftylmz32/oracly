/// Server-aware paid AI lifecycle: provider state local, money authoritative.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/gems/models/paid_ai_operation.dart';
import 'package:oracly_new/features/gems/services/paid_ai_operation_coordinator.dart';
import '../../support/fake_gem_authority.dart';

void main() {
  test('same Tarot operation settles once on server', () async {
    final storage = LocalStorage.ephemeral();
    final authority = FakeGemAuthority(balance: 100);
    final wallet = authority.wallet(storage);
    final ops = PaidAiOperationCoordinator(wallet: wallet, storage: storage);
    final op = await ops.begin(
      feature: PaidAiFeature.tarot,
      ledgerKey: 'tarot',
      reason: 'tarot',
      cost: 20,
      existingId: 'same-session',
    );

    expect(await ops.completeAfterProvider(op), isTrue);
    expect(await ops.completeAfterProvider(op), isTrue);
    expect(authority.balance, 80);
    expect(ops.store.byId(op.id)?.status, PaidAiOperationStatus.settled);
  });

  test('provider failure abandons without server settlement', () async {
    final storage = LocalStorage.ephemeral();
    final authority = FakeGemAuthority(balance: 100);
    final ops = PaidAiOperationCoordinator(
      wallet: authority.wallet(storage),
      storage: storage,
    );
    final op = await ops.begin(
      feature: PaidAiFeature.tarot,
      ledgerKey: 'tarot',
      reason: 'tarot',
      cost: 20,
    );
    final requestsBefore = authority.requests;
    await ops.abandon(op.id);

    expect(authority.requests, requestsBefore);
    expect(authority.balance, 100);
    expect(ops.store.byId(op.id)?.status, PaidAiOperationStatus.abandoned);
  });

  test('restart reconciles providerOk using server transaction identity', () async {
    final storage = LocalStorage.ephemeral();
    final authority = FakeGemAuthority(balance: 40);
    final wallet = authority.wallet(storage);
    final first = PaidAiOperationCoordinator(wallet: wallet, storage: storage);
    final op = await first.begin(
      feature: PaidAiFeature.tarot,
      ledgerKey: 'tarot',
      reason: 'tarot',
      cost: 20,
      existingId: 'restart-session',
    );
    await first.markProviderOk(op.id);
    final restarted = PaidAiOperationCoordinator(
      wallet: wallet,
      storage: storage,
      store: first.store,
    );

    expect(await restarted.reconcile(), 1);
    expect(authority.balance, 20);
    expect(await restarted.reconcile(), 0);
    expect(authority.balance, 20);
  });

  test('non-billable features remain free at zero balance', () async {
    final storage = LocalStorage.ephemeral();
    final ops = PaidAiOperationCoordinator(
      wallet: FakeGemAuthority().wallet(storage),
      storage: storage,
    );
    final op = await ops.begin(
      feature: PaidAiFeature.coffee,
      ledgerKey: 'coffee',
      reason: 'coffee',
      cost: null,
    );
    expect(op.isBillable, isFalse);
    expect(await ops.completeAfterProvider(op), isTrue);
  });
}
