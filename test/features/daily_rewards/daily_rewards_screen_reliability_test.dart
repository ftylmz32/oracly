/// Daily rewards screen: loading, error, and claim honesty.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/daily_rewards/copy/daily_rewards_copy.dart';
import 'package:oracly_new/features/daily_rewards/models/daily_reward_claim_result.dart';
import 'package:oracly_new/features/daily_rewards/models/daily_reward_state.dart';
import 'package:oracly_new/features/daily_rewards/presentation/reference/daily_rewards_reference_screen.dart';
import 'package:oracly_new/features/daily_rewards/providers/daily_rewards_providers.dart';
import 'package:oracly_new/features/daily_rewards/services/daily_rewards_service.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/economy/gem_economy.dart';
import 'package:oracly_new/features/gems/providers/gem_providers.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/shared/widgets/oracly_error_state.dart';
import 'package:oracly_new/shared/widgets/oracly_skeleton_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

class _FlakyRewards extends DailyRewardsService {
  _FlakyRewards(
    super.user,
    super.storage,
    super.wallet, {
    this.loadFails = false,
    this.claimFails = false,
  });

  bool loadFails;
  bool claimFails;
  int claims = 0;

  @override
  Future<DailyRewardState> load({DateTime? asOf}) async {
    if (loadFails) throw StateError('load failed');
    return super.load(asOf: asOf);
  }

  @override
  Future<DailyRewardClaimResult> claim({DateTime? asOf}) async {
    claims++;
    if (claimFails) {
      final state = await super.load(asOf: asOf);
      return DailyRewardClaimFailure(
        message: DailyRewardsCopy.claimFailed,
        state: state,
      );
    }
    return super.claim(asOf: asOf);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('tr'));

  Future<(LocalStorage, GemWalletService, _FlakyRewards)> open({
    bool loadFails = false,
    bool claimFails = false,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    final wallet = GemWalletService(GemWalletStore(storage));
    final service = _FlakyRewards(
      MockUserRepository(storage),
      storage,
      wallet,
      loadFails: loadFails,
      claimFails: claimFails,
    );
    return (storage, wallet, service);
  }

  testWidgets('load failure is not shown as unclaimed zero', (tester) async {
    final (storage, wallet, service) = await open(loadFails: true);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          dailyRewardsServiceProvider.overrideWithValue(service),
          gemWalletServiceProvider.overrideWithValue(wallet),
        ],
        child: const MaterialApp(home: DailyRewardsReferenceScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byType(OraclySkeletonLoader), findsNothing);
    expect(find.byType(OraclyErrorState), findsOneWidget);
    expect(find.text(DailyRewardsCopy.loadFailed), findsOneWidget);
    expect(find.text(DailyRewardsCopy.claimShort), findsNothing);
  });

  testWidgets('successful claim updates UI and wallet', (tester) async {
    final (storage, wallet, service) = await open();
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          dailyRewardsServiceProvider.overrideWithValue(service),
          gemWalletServiceProvider.overrideWithValue(wallet),
        ],
        child: const MaterialApp(home: DailyRewardsReferenceScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text(DailyRewardsCopy.claimShort), findsOneWidget);
    await tester.tap(find.text(DailyRewardsCopy.claimShort));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(wallet.balance, GemEconomy.dailyReward);
    expect(find.text(DailyRewardsCopy.claimedLabel), findsOneWidget);
  });

  testWidgets('claim failure shows localized retryable error', (tester) async {
    final (storage, wallet, service) = await open(claimFails: true);
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          dailyRewardsServiceProvider.overrideWithValue(service),
          gemWalletServiceProvider.overrideWithValue(wallet),
        ],
        child: const MaterialApp(home: DailyRewardsReferenceScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(find.text(DailyRewardsCopy.claimShort));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text(DailyRewardsCopy.claimFailed), findsOneWidget);
    expect(find.text(DailyRewardsCopy.claimShort), findsOneWidget);
    expect(wallet.balance, 0);
  });
}
