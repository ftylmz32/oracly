/// Retired local charge compatibility surface must always fail closed.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/services/gem_action_charge.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';

void main() {
  test('positive local commit cannot debit cached or legacy balance', () async {
    final storage = LocalStorage.ephemeral({
      GemWalletStore.serverBalanceCacheKey: 100,
      GemWalletStore.balanceKey: 9000,
    });
    final wallet = GemWalletService(GemWalletStore(storage));
    final charge = GemActionCharge(wallet, storage, ledgerKey: 'retired');

    expect(await charge.commit(actionId: 'action-1', cost: 20, reason: 'tarot'), isFalse);
    expect(wallet.balance, 100);
    expect(storage.getInt(GemWalletStore.balanceKey), 9000);
    expect(charge.alreadyCharged('action-1'), isFalse);
  });

  test('parallel retired commits cannot create local settlement proof', () async {
    final storage = LocalStorage.ephemeral({GemWalletStore.serverBalanceCacheKey: 40});
    final wallet = GemWalletService(GemWalletStore(storage));
    final charge = GemActionCharge(wallet, storage, ledgerKey: 'retired-race');

    expect(await Future.wait([
      charge.commit(actionId: 'same-action', cost: 20, reason: 'tarot'),
      charge.commit(actionId: 'same-action', cost: 20, reason: 'tarot'),
    ]), [false, false]);
    expect(wallet.balance, 40);
    expect(charge.alreadyCharged('same-action'), isFalse);
  });

  test('free compatibility operation remains a no-op', () async {
    final storage = LocalStorage.ephemeral({GemWalletStore.serverBalanceCacheKey: 25});
    final charge = GemActionCharge(
      GemWalletService(GemWalletStore(storage)),
      storage,
      ledgerKey: 'free',
    );
    expect(await charge.commit(actionId: 'free-1', cost: 0, reason: 'free'), isTrue);
    expect(storage.getInt(GemWalletStore.serverBalanceCacheKey), 25);
  });
}
