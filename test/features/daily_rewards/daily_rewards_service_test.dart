import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/features/daily_rewards/services/daily_rewards_service.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/economy/gem_economy.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DailyRewardsService service;
  late GemWalletService wallet;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    wallet = GemWalletService(GemWalletStore(storage));
    service = DailyRewardsService(MockUserRepository(storage), storage, wallet);
  });

  test('claim increments streak once per day', () async {
    final day = DateTime(2026, 8, 8);
    final first = await service.claim(asOf: day);
    expect(first.claimedToday, isTrue);
    expect(first.streak, 1);
    expect(wallet.balance, GemEconomy.dailyReward);

    final second = await service.claim(asOf: day);
    expect(second.streak, 1);
    expect(second.claimedToday, isTrue);
    expect(wallet.balance, GemEconomy.dailyReward);
  });

  test('new day allows another claim', () async {
    await service.claim(asOf: DateTime(2026, 8, 8));
    final next = await service.claim(asOf: DateTime(2026, 8, 9));
    expect(next.streak, 2);
    expect(next.claimedToday, isTrue);
    expect(wallet.balance, GemEconomy.dailyReward * 2);
  });

  test('crash after earn before claim flag does not double-credit', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final w = GemWalletService(GemWalletStore(storage));
    final rewards = DailyRewardsService(MockUserRepository(storage), storage, w);
    final day = DateTime(2026, 8, 22);
    final dayKey =
        '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';

    await w.earn(
      amount: GemEconomy.dailyReward,
      reason: 'simulated-crash-window',
      operationId: 'daily_reward_$dayKey',
    );
    expect(storage.getString(DailyRewardsService.claimedKey), isNull);

    final after = await rewards.claim(asOf: day);
    expect(after.claimedToday, isTrue);
    expect(w.balance, GemEconomy.dailyReward);
  });
}
