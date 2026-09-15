/// Safety gates for the server-authoritative client contract.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/features/daily_rewards/services/daily_rewards_service.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import '../../support/fake_gem_authority.dart';

void main() {
  test('cached balance is visible but cannot authorize offline spend', () async {
    final storage = LocalStorage.ephemeral({
      GemWalletStore.serverBalanceCacheKey: 100,
      GemWalletStore.balanceKey: 999999,
    });
    final wallet = GemWalletService(GemWalletStore(storage));
    expect(wallet.balance, 100);
    expect(wallet.stale, isTrue);
    expect(wallet.canSpend(20), isFalse);
    await expectLater(wallet.spend(amount: 20, reason: 'tarot'), throwsA(isA<GemSpendException>()));
    expect(wallet.balance, 100);
  });

  test('server reconciliation replaces tampered local value', () async {
    final storage = LocalStorage.ephemeral({GemWalletStore.balanceKey: 999999});
    final authority = FakeGemAuthority(balance: 12);
    final wallet = authority.wallet(storage);
    await wallet.refresh();
    expect(wallet.balance, 12);
    expect(wallet.stale, isFalse);
    expect(storage.getInt(GemWalletStore.balanceKey), 999999);
  });

  test('server-unavailable mutation preserves cached snapshot', () async {
    final storage = LocalStorage.ephemeral({GemWalletStore.serverBalanceCacheKey: 30});
    final authority = FakeGemAuthority(balance: 30)..online = false;
    final wallet = authority.wallet(storage);
    expect(await wallet.settleTarot(operationId: 'offline-op', idempotencyKey: 'offline-request'), isNull);
    expect(wallet.balance, 30);
    expect(wallet.stale, isTrue);
  });

  test('daily overlapping request produces one authoritative credit', () async {
    final storage = LocalStorage.ephemeral();
    final authority = FakeGemAuthority(serverDay: '2026-08-22');
    final rewards = DailyRewardsService(
      MockUserRepository(storage),
      storage,
      authority.wallet(storage),
    );
    final results = await Future.wait([
      rewards.claim(asOf: DateTime.utc(2026, 8, 22)),
      rewards.claim(asOf: DateTime.utc(2026, 8, 22)),
    ]);
    expect(results.any((result) => result.claimedToday), isTrue);
    expect(authority.balance, 50);
  });
}
