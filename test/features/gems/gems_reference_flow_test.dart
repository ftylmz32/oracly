/// Gems screen flow — live wallet, no fake purchase, daily route intact.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/daily_rewards/copy/daily_rewards_copy.dart';
import 'package:oracly_new/features/gems/copy/gems_copy.dart';
import 'package:oracly_new/features/gems/data/gem_display.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/economy/gem_economy.dart';
import 'package:oracly_new/features/gems/presentation/reference/gems_reference_screen.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<LocalStorage> pumpScreen(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: const MaterialApp(home: GemsReferenceScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    return storage;
  }

  testWidgets('shows live balance and honest economy, never fake IAP', (
    tester,
  ) async {
    final storage = await pumpScreen(tester);
    final wallet = GemWalletService(GemWalletStore(storage));

    expect(tester.takeException(), isNull);
    expect(wallet.balance, 0);
    expect(find.text(GemDisplay.format(0)), findsAtLeastNWidgets(2));
    expect(find.text('+${GemEconomy.starterGrant}'), findsOneWidget);
    expect(
      find.text('+${GemEconomy.dailyReward}${GemsCopy.dailyValueSuffix}'),
      findsOneWidget,
    );
    expect(find.text('-${GemEconomy.tarotReading}'), findsOneWidget);
    expect(find.textContaining('₺'), findsNothing);
    expect(find.text('Mücevher Paketi Satın Al'), findsNothing);
    expect(find.text('Yakında'), findsNothing);

    await tester.tap(find.text('+${GemEconomy.starterGrant}'));
    await tester.pump();
    expect(wallet.balance, 0);
  });

  testWidgets('daily reward card opens existing daily rewards route', (
    tester,
  ) async {
    await pumpScreen(tester);

    final daily = find.text(GemsCopy.dailyRewardLink);
    expect(daily, findsOneWidget);
    await tester.ensureVisible(daily);
    await tester.tap(daily);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(DailyRewardsCopy.screenTitle), findsOneWidget);
  });

  testWidgets('balance capsule is honest and non-interactive on gems screen', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.byIcon(Icons.add), findsNothing);
    final capsule = find.text(GemDisplay.format(0)).first;
    await tester.tap(capsule);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(GemsCopy.screenTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
