/// Debug-only Ruh Eşini Çiz gate bypass. Never entitlement or billing.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'premium_access.dart';
import 'premium_dev_override.dart';

/// Reuses [PremiumDevOverride] — no second bypass system.
abstract final class SoulMateDevAccess {
  SoulMateDevAccess._();

  static bool get enabled => PremiumDevOverride.enabled;

  /// Debug+development+flag only. Always false in release/profile.
  static bool get allowsTestAccess {
    if (kReleaseMode || !kDebugMode) return false;
    return PremiumDevOverride.isActive;
  }

  static bool allows(BuildContext context) {
    if (allowsTestAccess) return true;
    return PremiumAccess.ensure(context);
  }
}
