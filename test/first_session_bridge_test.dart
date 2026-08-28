/// First-session live bridge — Home CTA → Tarot single-card, intent lifecycle.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/first_session_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/first_session/first_session_intent.dart';
import 'package:oracly_new/core/first_session/first_session_scope.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/daily_ritual/widgets/daily_ritual_tarot_bridge.dart';
import 'package:oracly_new/features/gems/copy/gems_copy.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/home/master/home_master_hero.dart';
import 'package:oracly_new/features/home/reference/home_reference_hero.dart';
import 'package:oracly_new/features/home/reference/home_reference_hero_detail_button.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/economy/tarot_economy.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_charge.dart';
import 'package:oracly_new/features/tarot/first_session/tarot_first_reading.dart';
import 'package:oracly_new/features/tarot/shared/tarot_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers/provider_scope_harness.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  group('Home first-reading bridge', () {
    testWidgets('pending intent shows first-reading CTA in live hero', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      await FirstSessionIntent.requestFirstReading(storage);

      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          overrides: [firstReadingPendingProvider.overrideWith((ref) => true)],
          child: const MaterialApp(home: Scaffold(body: HomeMasterHero())),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(HomeReferenceHero), findsOneWidget);
      expect(find.text(FirstSessionCopy.homeCta), findsOneWidget);
      expect(find.text(FirstSessionCopy.homeSubtitleNew), findsOneWidget);
      expect(find.textContaining('Merhaba,'), findsNothing);
      expect(FirstSessionIntent.isPending(storage), isTrue);
    });

    testWidgets('no pending intent keeps normal hero', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();

      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          overrides: [firstReadingPendingProvider.overrideWith((ref) => false)],
          child: const MaterialApp(home: Scaffold(body: HomeMasterHero())),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Merhaba,'), findsOneWidget);
      expect(find.text(FirstSessionCopy.homeCta), findsNothing);
      expect(find.byType(HomeReferenceHeroDetailButton), findsNothing);
    });

    testWidgets('CTA tap does not consume pending intent', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      await FirstSessionIntent.requestFirstReading(storage);
      var opened = false;

      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          overrides: [firstReadingPendingProvider.overrideWith((ref) => true)],
          child: MaterialApp(
            home: Scaffold(
              body: HomeReferenceHero(
                hello: 'Hoş geldin,',
                invite: FirstSessionCopy.homeSubtitleNew,
                ctaLabel: FirstSessionCopy.homeCta,
                onCta: () => opened = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text(FirstSessionCopy.homeCta));
      await tester.pump();

      expect(opened, isTrue);
      expect(FirstSessionIntent.isPending(storage), isTrue);
    });
  });

  group('Tarot first-reading contract', () {
    test('first spread is single and free', () {
      expect(TarotFirstReading.spread, TarotSpreadType.single);
      expect(TarotEconomy.costFor(TarotFirstReading.spread), isNull);
      expect(TarotEconomy.isFree(TarotFirstReading.spread), isTrue);
    });

    test('single-card start cannot create a gem charge', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final wallet = GemWalletService(GemWalletStore(storage));
      final charge = TarotReadingCharge(wallet, storage);
      await wallet.earn(amount: 50, reason: GemsCopy.reasonDailyReward);

      expect(TarotEconomy.costFor(TarotSpreadType.single), isNull);
      expect(
        charge.canAfford(TarotSpreadType.single, sessionId: 'first_free'),
        isTrue,
      );
      expect(
        await charge.commit('first_free', spread: TarotSpreadType.single),
        isTrue,
      );
      expect(wallet.balance, 50);
      expect(wallet.history.where((t) => t.amount < 0), isEmpty);
    });

    testWidgets('shouldUseFirstSpread follows intent and scope', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      await FirstSessionIntent.requestFirstReading(storage);

      late WidgetRef captured;
      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          child: FirstSessionScope(
            isFirstSession: false,
            child: Consumer(
              builder: (context, ref, _) {
                captured = ref;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pump();

      final ctx = tester.element(find.byType(SizedBox));
      expect(TarotFirstReading.shouldUseFirstSpread(ctx, captured), isTrue);

      await FirstSessionIntent.consumePendingFirstReading(storage);
      expect(TarotFirstReading.shouldUseFirstSpread(ctx, captured), isFalse);
    });

    testWidgets('scope alone still marks first spread for empty history', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();

      late WidgetRef captured;
      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          child: FirstSessionScope(
            isFirstSession: true,
            child: Consumer(
              builder: (context, ref, _) {
                captured = ref;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pump();
      final ctx = tester.element(find.byType(SizedBox));
      expect(TarotFirstReading.shouldUseFirstSpread(ctx, captured), isTrue);
    });
  });

  group('Intent lifecycle', () {
    test('intent stays pending until successful consume after init', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      await FirstSessionIntent.requestFirstReading(storage);
      expect(FirstSessionIntent.isPending(storage), isTrue);

      // Simulate backing out before session init.
      expect(FirstSessionIntent.isPending(storage), isTrue);

      expect(
        await FirstSessionIntent.consumePendingFirstReading(storage),
        isTrue,
      );
      expect(FirstSessionIntent.isPending(storage), isFalse);
    });

    testWidgets('daily bridge does not auto-consume first-reading intent', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      await FirstSessionIntent.requestFirstReading(storage);

      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          child: MaterialApp(
            home: TarotModuleRoot(
              storage: storage,
              child: const DailyRitualTarotBridge(
                child: SizedBox(key: Key('bridge')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(FirstSessionIntent.isPending(storage), isTrue);
      expect(find.byKey(const Key('bridge')), findsOneWidget);
    });
  });
}
