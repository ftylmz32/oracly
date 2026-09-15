/// Gem economy V1 — one wallet, daily claim, spend safety.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/features/daily_rewards/copy/daily_rewards_copy.dart';
import 'package:oracly_new/features/daily_rewards/services/daily_rewards_service.dart';
import 'package:oracly_new/features/gems/copy/gems_copy.dart';
import 'package:oracly_new/features/gems/data/gem_display.dart';
import 'package:oracly_new/features/gems/economy/gem_economy.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../support/fake_gem_authority.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late GemWalletService wallet;
  late DailyRewardsService rewards;
  late FakeGemAuthority authority;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    authority = FakeGemAuthority(serverDay: '2026-08-09');
    wallet = authority.wallet(storage);
    rewards = DailyRewardsService(MockUserRepository(storage), storage, wallet);
  });

  test('starts at zero and formats consistently', () {
    expect(wallet.balance, 0);
    expect(GemDisplay.format(0), '0');
    expect(GemDisplay.format(1250), '1.250');
    expect(GemEconomy.starterGrant, GemEconomy.tarotReading);
  });

  test('daily claim adds gems once per calendar day', () async {
    final day = DateTime.utc(2026, 8, 9);
    final first = await rewards.claim(asOf: day);
    expect(first.claimedToday, isTrue);
    expect(first.streak, 1);
    expect(wallet.balance, GemEconomy.dailyReward);

    final second = await rewards.claim(asOf: day);
    expect(second.streak, 1);
    expect(wallet.balance, GemEconomy.dailyReward);
  });

  test('new calendar day allows another claim after restart', () async {
    await rewards.claim(asOf: DateTime.utc(2026, 8, 9));
    final restarted = authority.wallet(storage);
    expect(restarted.balance, GemEconomy.dailyReward);

    authority.serverDay = '2026-08-10';
    final next = await rewards.claim(asOf: DateTime.utc(2026, 8, 10));
    expect(next.claimedToday, isTrue);
    expect(next.streak, 2);
    expect(wallet.balance, GemEconomy.dailyReward * 2);
  });

  test('server settlement deducts once and local spend fails closed', () async {
    authority.balance = 50;
    await wallet.refresh();
    await wallet.settleTarot(
      operationId: 'tarot-session-01',
      idempotencyKey: 'settle-request-01',
    );
    expect(wallet.balance, 30);
    await wallet.settleTarot(
      operationId: 'tarot-session-01',
      idempotencyKey: 'settle-request-02',
    );
    expect(wallet.balance, 30);
    await expectLater(
      wallet.spend(amount: 1, reason: GemsCopy.reasonTarot),
      throwsA(isA<GemSpendException>()),
    );
  });

  test('client cannot manufacture refund credit', () async {
    authority.balance = 20;
    await wallet.refresh();
    await expectLater(
      wallet.earn(amount: 20, reason: GemsCopy.reasonRefund),
      throwsA(isA<GemSpendException>()),
    );
    expect(wallet.balance, 20);
  });

  test('claimed copy matches the product sentence', () {
    expect(DailyRewardsCopy.claimedLabel, 'Bugünün ödülünü aldın');
    expect(DailyRewardsCopy.rewardAmountLabel(), '+50 mücevher');
  });
}
