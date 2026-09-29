/// P4E — daily claim and screen state stay with the owner who started them.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/daily_rewards/copy/daily_rewards_copy.dart';
import 'package:oracly_new/features/daily_rewards/models/daily_reward_claim_result.dart';
import 'package:oracly_new/features/daily_rewards/presentation/reference/daily_rewards_reference_screen.dart';
import 'package:oracly_new/features/daily_rewards/providers/daily_rewards_providers.dart';
import 'package:oracly_new/features/daily_rewards/services/daily_rewards_service.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/providers/gem_providers.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_gateway.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';

import '../../support/fake_gem_authority.dart';
import '../../support/test_path_provider.dart';
import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late int savedEpoch;
  late Directory docsRoot;

  setUp(() async {
    savedEpoch = UserLocalDataIsolation.accountSwitchEpoch.value;
    docsRoot = await installTestPathProvider('p4e-daily-');
    OraclyL10n.bind('tr');
  });

  tearDown(() {
    final epoch = UserLocalDataIsolation.accountSwitchEpoch;
    if (epoch.value != savedEpoch) epoch.value = savedEpoch;
    if (docsRoot.existsSync()) docsRoot.deleteSync(recursive: true);
  });

  test('A daily claim cannot mark B claimed or increment B streak', () async {
    final storage = LocalStorage.ephemeral();
    final isolation = UserLocalDataIsolation(
      storage,
      secureStorage: InMemorySecureStorage(),
    );
    expect((await isolation.onSignedIn('owner-a')).success, isTrue);
    var live = 'owner-a';
    final authority = FakeGemAuthority(serverDay: '2026-09-29');
    final hold = Completer<void>();
    var held = false;
    final wallet = GemWalletService(
      GemWalletStore(storage),
      gateway: GemWalletGateway((method, path, body) async {
        if (path == '/v1/gems/daily-reward' && !held) {
          held = true;
          await hold.future;
        }
        return authority.send(method, path, body);
      }),
      ownerId: 'owner-a',
      requireOwner: true,
      currentOwnerId: () => live,
    );
    final rewards = DailyRewardsService(
      MockUserRepository(storage),
      storage,
      wallet,
      currentOwnerId: () => live,
    );
    final pending = rewards.claim(asOf: DateTime.utc(2026, 9, 29));
    await _until(() => held);
    final switched = isolation.onSignedIn('owner-b');
    expect((await switched).success, isTrue);
    live = 'owner-b';
    hold.complete();
    final result = await pending;
    expect(result, isA<DailyRewardClaimFailure>());
    expect(storage.getString(DailyRewardsService.claimedKey), isNull);
    expect((await MockUserRepository(storage).getProfile()).currentStreak, 0);
    final reloaded = await rewards.load(asOf: DateTime.utc(2026, 9, 29));
    expect(reloaded.claimedToday, isFalse);
  });

  test('in-memory claimed day does not follow a new owner', () async {
    final storage = LocalStorage.ephemeral();
    await storage.setString('or_local_data_owner_uid', 'owner-a');
    var live = 'owner-a';
    final authority = FakeGemAuthority(serverDay: '2026-09-29');
    final wallet = authority.wallet(storage);
    final rewards = DailyRewardsService(
      MockUserRepository(storage),
      storage,
      wallet,
      currentOwnerId: () => live,
    );
    final first = await rewards.claim(asOf: DateTime.utc(2026, 9, 29));
    expect(first, isA<DailyRewardClaimSuccess>());
    live = 'owner-b';
    await storage.setString('or_local_data_owner_uid', 'owner-b');
    await storage.remove(DailyRewardsService.claimedKey);
    final next = await rewards.load(asOf: DateTime.utc(2026, 9, 29));
    expect(next.claimedToday, isFalse);
  });

  test('a thrown local claim flag does not fail a server grant', () async {
    final storage = _ThrowClaimedFlag();
    final authority = FakeGemAuthority(serverDay: '2026-09-29');
    final rewards = DailyRewardsService(
      MockUserRepository(storage),
      storage,
      authority.wallet(storage),
    );
    final result = await rewards.claim(asOf: DateTime.utc(2026, 9, 29));
    expect(result, isA<DailyRewardClaimSuccess>());
    expect((result as DailyRewardClaimSuccess).state.streak, 1);
    final again = await rewards.claim(asOf: DateTime.utc(2026, 9, 29));
    expect(again, isA<DailyRewardClaimSuccess>());
    expect((again as DailyRewardClaimSuccess).state.streak, 1);
  });

  testWidgets('mounted daily rewards clears A when the owner epoch moves', (
    tester,
  ) async {
    final storage = LocalStorage.ephemeral();
    await storage.setString('or_local_data_owner_uid', 'owner-a');
    final today = DateTime.now().toUtc();
    final authority = FakeGemAuthority();
    var live = 'owner-a';
    final wallet = authority.wallet(storage);
    final service = DailyRewardsService(
      MockUserRepository(storage),
      storage,
      wallet,
      currentOwnerId: () => live,
    );
    await service.claim(asOf: today);
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
    expect(find.text(DailyRewardsCopy.claimedLabel), findsOneWidget);
    live = 'owner-b';
    await storage.setString('or_local_data_owner_uid', 'owner-b');
    await storage.remove(DailyRewardsService.claimedKey);
    UserLocalDataIsolation.accountSwitchEpoch.value++;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text(DailyRewardsCopy.claimedLabel), findsNothing);
    expect(find.text(DailyRewardsCopy.claimShort), findsOneWidget);
  });
}

Future<void> _until(bool Function() ready) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!ready()) {
    if (DateTime.now().isAfter(deadline)) fail('condition was not reached');
    await Future<void>.delayed(Duration.zero);
  }
}

class _ThrowClaimedFlag extends LocalStorage {
  _ThrowClaimedFlag() : super.ephemeral();

  @override
  Future<bool> setString(String key, String value) async {
    if (key == DailyRewardsService.claimedKey) {
      throw StateError('ux cache failed');
    }
    return super.setString(key, value);
  }
}
