/// Premium conversion — unlock copy, honest purchase, gem confirm, free value.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/gems/copy/gems_copy.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/economy/gem_economy.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/premium/models/premium_models.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_screen.dart';
import 'package:oracly_new/features/premium/services/premium_dev_override.dart';
import 'package:oracly_new/features/premium/services/unavailable_premium_purchase.dart';
import 'package:oracly_new/features/tarot/economy/tarot_economy.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_charge.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unlock list is complete and never a hard gate line', () {
    expect(PremiumCopy.unlocks, hasLength(3));
    expect(PremiumCopy.unlocks, contains(PremiumCopy.benefitDepthTitle));
    expect(PremiumCopy.unlocks, contains(PremiumCopy.benefitContinuityTitle));
    expect(
      PremiumCopy.unlocks,
      contains(PremiumCopy.benefitPersonalizationTitle),
    );
    expect(PremiumCopy.whatTitle, 'NEDİR BU KATMAN');
    expect(PremiumCopy.whyTitle, 'NEDEN VAR');
    expect(PremiumCopy.heroTitle, 'ÖZEL BİR ODA');
    expect(
      PremiumCopy.heroSubtitle,
      'ORACLY’nin daha derin, sessiz bir katmanı — isteğe bağlı bir oda.',
    );
    expect(PremiumCopy.heroLead.toLowerCase(), contains('isteğe bağlı'));
    expect(PremiumCopy.gateTitle.toLowerCase(), isNot(contains('gerekli')));
    expect(PremiumCopy.ctaUnavailable, 'Mağaza satın alması henüz açılmadı.');
    expect(PremiumCatalogue.showcaseBenefits, hasLength(3));
    expect(
      PremiumCatalogue.showcaseBenefits.every((b) => b.requiresPremium),
      isTrue,
    );
  });

  test('free capabilities stay ungated and gems stay priced honestly', () {
    expect(
      PremiumCatalogue.includedCapabilities.every((b) => !b.requiresPremium),
      isTrue,
    );
    expect(GemsCopy.costLabel(GemEconomy.tarotReading), '20 Mücevher');
    expect(TarotEconomy.readingCost, 20);
  });

  test('failed or repeated gem charge does not deduct twice', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final wallet = GemWalletService(GemWalletStore(storage));
    final charge = TarotReadingCharge(wallet, storage);
    expect(await charge.commit('s1'), isFalse);
    expect(wallet.balance, 0);

    await wallet.earn(amount: 50, reason: GemsCopy.reasonDailyReward);
    expect(await charge.commit('s1'), isTrue);
    expect(wallet.balance, 30);
    expect(await charge.commit('s1'), isTrue);
    expect(wallet.balance, 30);
  });

  test('purchase port stays unconfigured; debug override is not entitlement', () {
    expect(const UnavailablePremiumPurchase().isConfigured, isFalse);
    expect(PremiumDevOverride.isActive, isFalse);
  });

  testWidgets('membership screen shows unlocks, free value, no fake price',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: const MaterialApp(home: PremiumReferenceScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text(PremiumCopy.heroTitle), findsOneWidget);
    expect(find.text(PremiumCopy.heroSubtitle), findsOneWidget);
    expect(find.text(PremiumCopy.benefitSoulmateTitle), findsWidgets);
    expect(find.text(PremiumCopy.benefitOrTitle), findsWidgets);
    expect(find.text(PremiumCopy.benefitJourneyTitle), findsWidgets);
    expect(find.text(PremiumCopy.benefitDiscoveryTitle), findsNothing);
    expect(find.text(PremiumCopy.ctaExplore), findsOneWidget);
    expect(find.text(PremiumCopy.ctaUnavailable), findsOneWidget);
    expect(find.text(PremiumCopy.gemNote(20)), findsOneWidget);
    expect(find.textContaining('₺'), findsNothing);
    expect(find.textContaining('son şans'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
