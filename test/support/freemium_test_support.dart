/// Freemium V1 test seams: the remote flag switch and a membership status
/// in any state (loading, free, verified Premium, failed) without a store.
library;

import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_runtime.dart';
import 'package:oracly_new/core/feature_flags/product_feature_flags.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';
import 'package:oracly_new/features/premium/services/unavailable_premium_purchase.dart';

void setFreemiumFlag(bool on) {
  FeatureFlagRuntime.refreshFromRemote({
    ...ProductFeatureFlags.defaults(),
    ProductFeatureFlags.freemiumV1.key: on,
  });
}

void resetFeatureFlags() =>
    FeatureFlagRuntime.refreshFromRemote(ProductFeatureFlags.defaults());

class FakePremiumStatus extends PremiumStatusController {
  FakePremiumStatus({
    bool loaded = true,
    bool premium = false,
    PremiumEntitlementState? entitlement,
    bool busy = false,
  }) : _loaded = loaded,
       _premium = premium,
       _entitlement =
           entitlement ??
           (premium
               ? PremiumEntitlementState.active
               : PremiumEntitlementState.inactive),
       _busy = busy,
       super(_service());

  static PremiumService _service() {
    final storage = LocalStorage.ephemeral();
    return PremiumService(
      MockPremiumRepository(storage),
      MockUserRepository(storage),
      const UnavailablePremiumPurchase(),
    );
  }

  final bool _loaded;
  final bool _premium;
  final PremiumEntitlementState _entitlement;
  final bool _busy;
  int refreshes = 0;

  @override
  bool get loaded => _loaded;
  @override
  bool get isPremium => _premium;
  @override
  PremiumEntitlementState get entitlement => _entitlement;
  @override
  bool get busy => _busy;
  @override
  Future<void> load() async {}
  @override
  Future<void> refresh() async => refreshes++;
}
