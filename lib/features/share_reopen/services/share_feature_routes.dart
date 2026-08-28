/// Share kind → route names. No private ids, no URL auth.
library;

import '../../../core/navigation/oracly_routes.dart';
import '../../discovery_share/models/shareable_discovery.dart';

abstract final class ShareFeatureRoutes {
  ShareFeatureRoutes._();

  static String publicRoute(DiscoveryShareKind kind) {
    return switch (kind) {
      DiscoveryShareKind.coffee => OraclyRoutes.coffee,
      DiscoveryShareKind.palm => OraclyRoutes.palm,
      DiscoveryShareKind.tarot => OraclyRoutes.tarot,
      DiscoveryShareKind.astrology => OraclyRoutes.astrology,
      DiscoveryShareKind.starMap => OraclyRoutes.starMap,
      DiscoveryShareKind.soulMate => OraclyRoutes.premium,
      DiscoveryShareKind.dailyInsight => OraclyRoutes.dailyMessage,
    };
  }

  static String ownerRoute(DiscoveryShareKind kind) {
    if (kind == DiscoveryShareKind.tarot) return OraclyRoutes.readingHistory;
    return publicRoute(kind);
  }
}
