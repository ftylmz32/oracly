/// G0 — Premium product truth: gates, platform plans, economy isolation.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/core/modules/oracly_feature_registry.dart';
import 'package:oracly_new/features/dream/economy/dream_economy.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/models/paid_ai_operation.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/gems/services/paid_ai_operation_coordinator.dart';
import 'package:oracly_new/features/premium/services/premium_dev_override.dart';
import 'package:oracly_new/features/premium/services/premium_feature_gates.dart';
import 'package:oracly_new/features/premium/services/premium_plan_availability.dart';
import 'package:oracly_new/features/premium/services/premium_store_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

PremiumPlanModel _plan(PremiumPlanKind kind) => PremiumPlanModel(
      kind: kind,
      label: kind.name,
      price: '',
      subtitle: '',
      isActive: false,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('only SoulMate is navigation-gated; every free ritual stays free', () {
    expect(PremiumFeatureGates.navigationPremiumModules, {
      OraclyFeatureId.soulMate,
    });
    final registryGated = OraclyFeatureRegistry.all
        .where((m) => m.requiresPremium)
        .map((m) => m.id)
        .toSet();
    expect(registryGated, PremiumFeatureGates.navigationPremiumModules);
    for (final id in [
      OraclyFeatureId.tarot, OraclyFeatureId.coffee, OraclyFeatureId.palm, //
      OraclyFeatureId.astrology, OraclyFeatureId.starMap,
      OraclyFeatureId.dailyEnergy, OraclyFeatureId.dailyMessage,
      OraclyFeatureId.discoveryJournal, OraclyFeatureId.dream,
      OraclyFeatureId.aiChat, OraclyFeatureId.readingHistory,
    ]) {
      expect(PremiumFeatureGates.ritualRequiresPremium(id), isFalse,
          reason: id.name);
    }
  });

  test('entitlement capabilities are exactly the documented Premium set', () {
    expect(
      PremiumFeatureGates.entitlementCapabilities,
      PremiumGatedCapability.values.toSet(),
    );
    expect(PremiumFeatureGates.orChamberPreviewAllowedWhenFree, isTrue);
  });

  group('platform plan truth', () {
    final all = PremiumPlanKind.values.map(_plan).toList();

    test('iOS: monthly + yearly only; lifetime never queried or shown', () {
      const ios = TargetPlatform.iOS;
      expect(
        PremiumPlanAvailability.visiblePlans(all, platform: ios)
            .map((p) => p.kind),
        [PremiumPlanKind.monthly, PremiumPlanKind.yearly],
      );
      expect(PremiumPlanAvailability.storeQueryIds(platform: ios), {
        PremiumStoreCatalog.monthlyId,
        PremiumStoreCatalog.yearlyId,
      });
      expect(
        PremiumPlanAvailability.isPurchasable(PremiumPlanKind.lifetime,
            platform: ios),
        isFalse,
      );
      expect(
        PremiumPlanAvailability.normalizeSelection(PremiumPlanKind.lifetime,
            platform: ios),
        PremiumPlanKind.yearly,
      );
    });

    test('Android keeps lifetime alongside subscriptions', () {
      const android = TargetPlatform.android;
      expect(
        PremiumPlanAvailability.visiblePlans(all, platform: android).length,
        3,
      );
      expect(
        PremiumPlanAvailability.storeQueryIds(platform: android),
        PremiumStoreCatalog.allIds,
      );
      expect(PremiumStoreCatalog.isSubscription(PremiumPlanKind.lifetime),
          isFalse);
    });
  });

  test('debug Premium override can never activate outside debug+dev', () {
    for (final env in AppEnvironment.values) {
      expect(
        PremiumDevOverride.allowsOverride(
          debugBuild: false,
          environment: env,
          flagEnabled: true,
        ),
        isFalse,
        reason: env.name,
      );
    }
    expect(
      PremiumDevOverride.allowsOverride(
        debugBuild: true,
        environment: AppEnvironment.production,
        flagEnabled: true,
      ),
      isFalse,
    );
  });

  test('Dream stays free; billable non-Tarot work fails closed', () async {
    expect(DreamEconomy.analysisCost, isNull);
    expect(DreamEconomy.hasCost, isFalse);
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final wallet = GemWalletService(GemWalletStore(storage));
    final ops = PaidAiOperationCoordinator(wallet: wallet, storage: storage);
    await wallet.acceptAuthoritativeBalance(50);
    for (final feature in PaidAiFeature.values) {
      if (feature == PaidAiFeature.tarot) continue;
      await expectLater(
        () => ops.begin(
          feature: feature,
          ledgerKey: 'g0_${feature.name}',
          reason: 'g0',
          cost: 10,
        ),
        throwsA(isA<UnsupportedError>()),
        reason: feature.name,
      );
    }
    expect(wallet.balance, 50);
  });

  test('Premium / review access code never grants gems (source contract)', () {
    for (final path in [
      'lib/features/premium/controllers/premium_status_controller.dart',
      'lib/core/services/premium_service.dart',
      'lib/features/premium/services/review_access_service.dart',
    ]) {
      final src = File(path).readAsStringSync();
      expect(src.contains(RegExp('GemWallet|gem_wallet|grantGems')), isFalse,
          reason: path);
    }
  });
}
