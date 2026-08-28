/// Gem economy V1 — one wallet, daily claim, spend safety.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/features/daily_rewards/copy/daily_rewards_copy.dart';
import 'package:oracly_new/features/daily_rewards/services/daily_rewards_service.dart';
import 'package:oracly_new/features/gems/copy/gems_copy.dart';
import 'package:oracly_new/features/gems/data/gem_display.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/economy/gem_economy.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/tarot/economy/tarot_economy.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late GemWalletService wallet;
  late DailyRewardsService rewards;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    wallet = GemWalletService(GemWalletStore(storage));
    rewards = DailyRewardsService(MockUserRepository(storage), storage, wallet);
  });

  test('starts at zero and formats consistently', () {
    expect(wallet.balance, 0);
    expect(GemDisplay.format(0), '0');
    expect(GemDisplay.format(1250), '1.250');
    expect(GemEconomy.starterGrant, GemEconomy.tarotReading);
  });

  test('daily claim adds gems once per calendar day', () async {
    final day = DateTime(2026, 8, 9);
    final first = await rewards.claim(asOf: day);
    expect(first.claimedToday, isTrue);
    expect(first.streak, 1);
    expect(wallet.balance, GemEconomy.dailyReward);
    expect(wallet.history.first.displayLine, '+50 — Günlük Ödül');

    final second = await rewards.claim(asOf: day);
    expect(second.streak, 1);
    expect(wallet.balance, GemEconomy.dailyReward);
  });

  test('new calendar day allows another claim after restart', () async {
    await rewards.claim(asOf: DateTime(2026, 8, 9));
    final restarted = GemWalletService(GemWalletStore(storage));
    expect(restarted.balance, GemEconomy.dailyReward);

    final next = await rewards.claim(asOf: DateTime(2026, 8, 10));
    expect(next.claimedToday, isTrue);
    expect(next.streak, 2);
    expect(wallet.balance, GemEconomy.dailyReward * 2);
  });

  test('spend deducts, never goes negative, and blocks double tap', () async {
    await wallet.earn(amount: 50, reason: GemsCopy.reasonDailyReward);
    await wallet.spend(
      amount: TarotEconomy.readingCost,
      reason: GemsCopy.reasonTarot,
    );
    expect(wallet.balance, 30);
    expect(wallet.history.first.displayLine, '-20 — Tarot');

    expect(
      () => wallet.spend(amount: 40, reason: GemsCopy.reasonTarot),
      throwsA(
        isA<GemSpendException>().having(
          (e) => e.message,
          'message',
          GemsCopy.insufficient,
        ),
      ),
    );
    expect(wallet.balance, 30);

    final first = wallet.spend(amount: 10, reason: GemsCopy.reasonTarot);
    expect(
      () => wallet.spend(amount: 10, reason: GemsCopy.reasonTarot),
      throwsA(isA<GemSpendException>()),
    );
    await first;
    expect(wallet.balance, 20);
  });

  test('provider failure credits gems back through earn', () async {
    await wallet.earn(amount: 20, reason: GemsCopy.reasonStarter);
    await wallet.spend(amount: 20, reason: GemsCopy.reasonCoffee);
    expect(wallet.balance, 0);
    await wallet.earn(amount: 20, reason: GemsCopy.reasonRefund);
    expect(wallet.balance, 20);
    expect(
      wallet.history.map((e) => e.reason),
      contains(GemsCopy.reasonRefund),
    );
  });

  test('claimed copy matches the product sentence', () {
    expect(DailyRewardsCopy.claimedLabel, 'Bugünün ödülünü aldın');
    expect(DailyRewardsCopy.rewardAmountLabel(), '+50 mücevher');
  });
}
