/// Gem economy regressions — daily, settle, restart, owner isolation.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/firebase/firebase_app_check_policy.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/features/daily_rewards/models/daily_reward_claim_result.dart';
import 'package:oracly_new/features/daily_rewards/services/daily_rewards_service.dart';
import 'package:oracly_new/features/gems/controllers/gem_wallet_controller.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/economy/gem_economy.dart';
import 'package:oracly_new/features/gems/models/paid_ai_operation.dart';
import 'package:oracly_new/features/gems/services/gem_starter_grant.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/gems/services/paid_ai_operation_coordinator.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_charge.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_completion.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_gem_authority.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('App Check debug provider is off without explicit dart-define', () {
    expect(FirebaseAppCheckPolicy.forceDebugProvider, isFalse);
    expect(
      FirebaseAppCheckPolicy.useDebugProvider(
        environment: AppEnvironment.production,
        releaseLocked: true,
      ),
      isFalse,
    );
  });

  test('daily first claim credits and updates controller immediately', () async {
    final world = await _World.create(balance: 20);
    final day = DateTime.utc(2026, 9, 19);
    world.authority.serverDay = '2026-09-19';
    final result = await world.daily.claim(asOf: day);
    expect(result, isA<DailyRewardClaimSuccess>());
    expect(world.wallet.balance, 70);
    await world.controller.acceptAuthoritativeBalance(world.wallet.balance);
    expect(world.controller.formatted, '70');
    expect(world.controller.authoritative, isTrue);
  });

  test('daily same-day claim is idempotent', () async {
    final world = await _World.create(balance: 0);
    world.authority.serverDay = '2026-09-19';
    final day = DateTime.utc(2026, 9, 19);
    await world.daily.claim(asOf: day);
    await world.daily.claim(asOf: day);
    expect(world.wallet.balance, GemEconomy.dailyReward);
  });

  test('daily transport failure stays retryable without local success', () async {
    final world = await _World.create(balance: 10);
    world.authority.serverDay = '2026-09-19';
    world.authority.online = false;
    final day = DateTime.utc(2026, 9, 19);
    final failed = await world.daily.claim(asOf: day);
    expect(failed, isA<DailyRewardClaimFailure>());
    expect(world.storage.getString(DailyRewardsService.claimedKey), isNull);
    world.authority.online = true;
    final ok = await world.daily.claim(asOf: day);
    expect(ok, isA<DailyRewardClaimSuccess>());
    expect(world.wallet.balance, 60);
  });

  test('paid Tarot completes with exactly one settle', () async {
    final world = await _World.create(balance: 50);
    final completion = TarotReadingCompletion(charge: world.charge);
    expect(await completion.complete(_session('paid-ok')), isNotNull);
    expect(world.wallet.balance, 30);
    expect(await completion.complete(_session('paid-ok')), isNotNull);
    expect(world.wallet.balance, 30);
  });

  test('failed and cancelled Tarot never settle', () async {
    final world = await _World.create(balance: 50);
    final completion = TarotReadingCompletion(charge: world.charge);
    expect(
      await completion.complete(
        _session('fail'),
        load: () async => throw Exception('provider'),
      ),
      isNull,
    );
    expect(
      await completion.complete(_session('cancel'), shouldCommit: () => false),
      isNull,
    );
    expect(world.wallet.balance, 50);
  });

  test('unhydrated and insufficient wallets block paid Tarot', () async {
    final storage = LocalStorage.ephemeral();
    final dry = GemWalletService(GemWalletStore(storage), requireOwner: true);
    expect(dry.canSpend(20), isFalse);
    final poorWorld = await _World.create(balance: 5);
    expect(await poorWorld.charge.canAfford(
      TarotSpreadType.threeCard,
      sessionId: 'poor',
    ), isFalse);
    expect(
      await TarotReadingCompletion(charge: poorWorld.charge)
          .complete(_session('poor')),
      isNull,
    );
    expect(poorWorld.wallet.balance, 5);
  });

  test('restart reconcile settles providerOk leftover once', () async {
    final world = await _World.create(balance: 40);
    world.authority.online = false;
    final op = await world.ops.begin(
      feature: PaidAiFeature.tarot,
      ledgerKey: 'tarot_gem_charged_sessions',
      reason: 'tarot',
      cost: 20,
      existingId: 'resume-op',
    );
    await world.ops.markProviderOk(op.id);
    expect(await world.ops.settle(op), isFalse);
    world.authority.online = true;
    final restarted = PaidAiOperationCoordinator(
      wallet: world.wallet,
      storage: world.storage,
      store: world.ops.store,
    );
    expect(await restarted.reconcile(), 1);
    expect(world.wallet.balance, 20);
    expect(await restarted.reconcile(), 0);
  });

  test('owner A cache never displays for owner B', () async {
    final storage = LocalStorage.ephemeral();
    final store = GemWalletStore(storage);
    await store.cacheServerBalance(77, ownerId: 'owner-a');
    expect(store.balanceForOwner('owner-a'), 77);
    expect(store.balanceForOwner('owner-b'), isNull);
    final b = GemWalletService(
      store,
      ownerId: 'owner-b',
      requireOwner: true,
    );
    expect(b.cachedBalance, isNull);
    expect(GemWalletController(b).formatted, '—');
  });

  test('starter grant idempotent and transient failure clears memory', () async {
    final world = await _World.create(balance: 0);
    world.authority.online = false;
    final grant = GemStarterGrant(world.wallet, world.storage);
    expect(await grant.ensureOnce(), isFalse);
    expect(grant.alreadyGranted, isFalse);
    world.authority.online = true;
    expect(await grant.ensureOnce(), isTrue);
    expect(await grant.ensureOnce(), isFalse);
    expect(world.wallet.balance, GemEconomy.starterGrant);
  });

  test('Home and Gems share controller after settle', () async {
    final world = await _World.create(balance: 40);
    final completion = TarotReadingCompletion(charge: world.charge);
    expect(await completion.complete(_session('ui-sync')), isNotNull);
    await world.controller.acceptAuthoritativeBalance(world.wallet.balance);
    expect(world.controller.formatted, '20');
    expect(world.controller.balance, world.wallet.balance);
  });
}

class _World {
  _World._(this.storage, this.authority, this.wallet, this.controller,
      this.daily, this.charge, this.ops);

  final LocalStorage storage;
  final FakeGemAuthority authority;
  final GemWalletService wallet;
  final GemWalletController controller;
  final DailyRewardsService daily;
  final TarotReadingCharge charge;
  final PaidAiOperationCoordinator ops;

  static Future<_World> create({required int balance}) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final authority = FakeGemAuthority(balance: balance);
    final wallet = authority.wallet(storage);
    await wallet.refresh();
    return _World._(
      storage,
      authority,
      wallet,
      GemWalletController(wallet),
      DailyRewardsService(MockUserRepository(storage), storage, wallet),
      TarotReadingCharge(wallet, storage),
      PaidAiOperationCoordinator(wallet: wallet, storage: storage),
    );
  }
}

ReadingSession _session(String id) {
  final reveal = CardRevealSpread.forIndex(0);
  return ReadingSession(
    id: id,
    deckId: 'classic',
    spread: TarotSpreadType.threeCard,
    intention: const TarotIntention(text: 'Genel'),
    shuffleSeed: 1,
    startedAt: DateTime(2026, 9, 19),
    drawnCards: [
      TarotDrawnCard(
        card: reveal.card,
        positionIndex: 0,
        isReversed: false,
        positionLabel: 'Şimdi',
      ),
    ],
  );
}
