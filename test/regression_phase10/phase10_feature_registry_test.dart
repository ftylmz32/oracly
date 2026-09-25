/// Phase 10 — live feature registry destinations (audit-only).
/// REAL PROVIDER CALLS = 0. Production unmodified.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/core/modules/oracly_feature_registry.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/core/navigation/universe/oracly_universe_realm.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/features/premium/services/premium_plan_availability.dart';

void main() {
  test('live modules keep distinct destinations and realms', () {
    final live = OraclyFeatureRegistry.live;
    expect(live, isNotEmpty);

    final routes = <String>{};
    for (final m in live) {
      if (m.routeName == null) continue;
      expect(m.isReserved, isFalse);
      expect(routes.add(m.routeName!), isTrue, reason: 'duplicate ${m.routeName}');
    }

    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.tarot)?.routeName,
      OraclyRoutes.tarot,
    );
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.coffee)?.routeName,
      OraclyRoutes.coffee,
    );
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.palm)?.routeName,
      OraclyRoutes.palm,
    );
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.dream)?.routeName,
      OraclyRoutes.dream,
    );
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.astrology)?.routeName,
      OraclyRoutes.astrology,
    );
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.starMap)?.routeName,
      OraclyRoutes.starMap,
    );
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.aiChat)?.routeName,
      OraclyRoutes.chat,
    );
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.premium)?.routeName,
      OraclyRoutes.premium,
    );

    final soul = OraclyFeatureRegistry.byId(OraclyFeatureId.soulMate)!;
    expect(soul.requiresPremium, isTrue);
    expect(soul.isLive, isTrue);

    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.tarot)?.universeRealm,
      OraclyUniverseRealm.explore,
    );
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.aiChat)?.universeRealm,
      OraclyUniverseRealm.reflect,
    );
  });

  test('iOS premium catalog excludes lifetime; monthly+yearly purchasable', () {
    expect(
      PremiumPlanAvailability.isPurchasable(
        PremiumPlanKind.lifetime,
        platform: TargetPlatform.iOS,
      ),
      isFalse,
    );
    expect(
      PremiumPlanAvailability.isPurchasable(
        PremiumPlanKind.monthly,
        platform: TargetPlatform.iOS,
      ),
      isTrue,
    );
    expect(
      PremiumPlanAvailability.isPurchasable(
        PremiumPlanKind.yearly,
        platform: TargetPlatform.iOS,
      ),
      isTrue,
    );
  });
}
