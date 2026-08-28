/// Debug-only Ruh Eşini Çiz gate bypass. Never entitlement or billing.
library;

import 'package:flutter/widgets.dart';

import 'premium_access.dart';
import 'premium_dev_override.dart';

abstract final class SoulMateDevAccess {
  SoulMateDevAccess._();

  static bool get enabled => PremiumDevOverride.enabled;

  static bool get allowsTestAccess => PremiumDevOverride.isActive;

  static bool allows(BuildContext context) {
    if (allowsTestAccess) return true;
    return PremiumAccess.ensure(context);
  }
}
