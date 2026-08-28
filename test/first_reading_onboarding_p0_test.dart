/// P0 — starter gems + consistent first-session tarot entry.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/first_session_copy.dart';
import 'package:oracly_new/core/copy/onboarding_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/first_session/first_session_scope.dart';
import 'package:oracly_new/features/daily_rewards/services/daily_rewards_service.dart';
import 'package:oracly_new/features/gems/copy/gems_copy.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/economy/gem_economy.dart';
import 'package:oracly_new/features/gems/services/gem_starter_grant.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/economy/tarot_economy.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_charge.dart';
import 'package:oracly_new/features/tarot/first_session/tarot_first_reading.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late GemWalletService wallet;
  late GemStarterGrant starter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    wallet = GemWalletService(GemWalletStore(storage));
    starter = GemStarterGrant(wallet, storage);
  });

  test('new user receives exactly one starter grant of 20', () async {
    expect(GemEconomy.starterGrant, 20);
    expect(TarotEconomy.readingCost, 20);
    expect(TarotEconomy.costFor(TarotFirstReading.spread), isNull);
    expect(await starter.ensureOnce(), isTrue);
    expect(wallet.balance, 20);
    expect(wallet.history.first.reason, GemsCopy.reasonStarter);
    expect(await starter.ensureOnce(), isFalse);
    expect(wallet.balance, 20);
  });

  test('restart does not grant starter gems again', () async {
    await starter.ensureOnce();
    final restarted = GemStarterGrant(
      GemWalletService(GemWalletStore(storage)),
      storage,
    );
    expect(restarted.alreadyGranted, isTrue);
    expect(await restarted.ensureOnce(), isFalse);
    expect(restarted.alreadyGranted, isTrue);
    expect(GemWalletService(GemWalletStore(storage)).balance, 20);
  });

  test('repeated onboarding tap does not grant again', () async {
    expect(await starter.ensureOnce(), isTrue);
    expect(await starter.ensureOnce(), isFalse);
    expect(await starter.ensureOnce(), isFalse);
    expect(wallet.balance, 20);
  });

  test('first tarot reading succeeds then normal 20-gem price applies', () async {
    await starter.ensureOnce();
    expect(wallet.canSpend(TarotEconomy.readingCost), isTrue);
    final charge = TarotReadingCharge(wallet, storage);
    expect(await charge.commit('first'), isTrue);
    expect(wallet.balance, 0);
    expect(wallet.canSpend(TarotEconomy.readingCost), isFalse);
    expect(await charge.commit('second'), isFalse);
    expect(wallet.balance, 0);
  });

  test('insufficient gems after starter resources stay non-negative', () async {
    await starter.ensureOnce();
    await wallet.spend(
      amount: TarotEconomy.readingCost,
      reason: GemsCopy.reasonTarot,
    );
    expect(wallet.balance, 0);
    expect(
      () => wallet.spend(amount: 20, reason: GemsCopy.reasonTarot),
      throwsA(isA<GemSpendException>()),
    );
    expect(wallet.balance, greaterThanOrEqualTo(0));
  });

  test('daily +50 remains separate from starter grant', () async {
    await starter.ensureOnce();
    final rewards = DailyRewardsService(
      MockUserRepository(storage),
      storage,
      wallet,
    );
    final before = await rewards.load(asOf: DateTime(2026, 8, 9));
    expect(before.claimedToday, isFalse);
    expect(wallet.balance, 20);

    final claimed = await rewards.claim(asOf: DateTime(2026, 8, 9));
    expect(claimed.claimedToday, isTrue);
    expect(wallet.balance, 70);
    expect(
      wallet.history.map((e) => e.reason),
      containsAll([GemsCopy.reasonStarter, GemsCopy.reasonDailyReward]),
    );
  });

  test('onboarding copy explains first reading without pay or premium', () {
    expect(OnboardingCopy.pages, hasLength(1));
    expect(OnboardingCopy.title, 'ORACLY');
    expect(
      OnboardingCopy.startFirstReading.toLowerCase(),
      isNot(contains('kart')),
    );
    expect(
      OnboardingCopy.startFirstReading.toLowerCase(),
      isNot(contains('premium')),
    );
    expect(
      OnboardingCopy.pages.any((p) => p.title.contains('Premium')),
      isFalse,
    );
    expect(
      OnboardingCopy.tagline.toLowerCase(),
      isNot(contains('satın')),
    );
    expect(
      OnboardingCopy.tagline.toLowerCase(),
      isNot(contains('premium')),
    );
    expect(FirstSessionCopy.cardSelectionTitle, 'İlk kartın.');
  });

  test('first-session tarot entry is single card for both CTAs', () {
    expect(TarotFirstReading.spread, TarotSpreadType.single);
    expect(TarotFirstReading.spread.cardCount, 1);
  });

  testWidgets('first-session scope uses first spread, returning does not',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FirstSessionScope(
          isFirstSession: true,
          child: _SpreadProbe(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('first-spread'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: FirstSessionScope(
          isFirstSession: false,
          child: _SpreadProbe(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('returning-spread'), findsOneWidget);
  });
}

class _SpreadProbe extends StatelessWidget {
  const _SpreadProbe();

  @override
  Widget build(BuildContext context) {
    final first = FirstSessionScope.of(context);
    return Text(first ? 'first-spread' : 'returning-spread');
  }
}
