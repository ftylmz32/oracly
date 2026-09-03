import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/features/daily_rewards/models/daily_reward_claim_result.dart';
import 'package:oracly_new/features/daily_rewards/services/daily_rewards_service.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/economy/gem_economy.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DailyRewardsService service;
  late GemWalletService wallet;
  late LocalStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    wallet = GemWalletService(GemWalletStore(storage));
    service = DailyRewardsService(MockUserRepository(storage), storage, wallet);
  });

  test('claim increments streak once per day', () async {
    final day = DateTime(2026, 8, 8);
    final first = await service.claim(asOf: day);
    expect(first, isA<DailyRewardClaimSuccess>());
    final success = first as DailyRewardClaimSuccess;
    expect(success.state.claimedToday, isTrue);
    expect(success.state.streak, 1);
    expect(wallet.balance, GemEconomy.dailyReward);

    final second = await service.claim(asOf: day);
    expect(second, isA<DailyRewardClaimSuccess>());
    final again = second as DailyRewardClaimSuccess;
    expect(again.state.streak, 1);
    expect(again.state.claimedToday, isTrue);
    expect(wallet.balance, GemEconomy.dailyReward);
  });

  test('new day allows another claim', () async {
    await service.claim(asOf: DateTime(2026, 8, 8));
    final next = await service.claim(asOf: DateTime(2026, 8, 9));
    expect(next, isA<DailyRewardClaimSuccess>());
    final success = next as DailyRewardClaimSuccess;
    expect(success.state.streak, 2);
    expect(success.state.claimedToday, isTrue);
    expect(wallet.balance, GemEconomy.dailyReward * 2);
  });

  test('crash after earn before claim flag does not double-credit', () async {
    SharedPreferences.setMockInitialValues({});
    final local = LocalStorage(await SharedPreferences.getInstance());
    final w = GemWalletService(GemWalletStore(local));
    final rewards = DailyRewardsService(MockUserRepository(local), local, w);
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
    expect(local.getString(DailyRewardsService.claimedKey), isNull);

    final after = await rewards.claim(asOf: day);
    expect(after, isA<DailyRewardClaimSuccess>());
    expect(w.balance, GemEconomy.dailyReward);
  });

  test('date boundary uses injected asOf clock', () async {
    final dayA = DateTime(2026, 8, 31, 23, 30);
    final dayB = DateTime(2026, 9, 1, 0, 5);
    await service.claim(asOf: dayA);
    final next = await service.claim(asOf: dayB);
    expect(next, isA<DailyRewardClaimSuccess>());
    expect((next as DailyRewardClaimSuccess).state.streak, 2);
    expect(wallet.balance, GemEconomy.dailyReward * 2);
  });

  test('rapid overlapping claims do not double credit', () async {
    final day = DateTime(2026, 9, 2);
    final results = await Future.wait([
      service.claim(asOf: day),
      service.claim(asOf: day),
      service.claim(asOf: day),
    ]);
    final successes = results.whereType<DailyRewardClaimSuccess>().toList();
    expect(successes.any((r) => r.state.claimedToday), isTrue);
    expect(wallet.balance, GemEconomy.dailyReward);
  });
}
