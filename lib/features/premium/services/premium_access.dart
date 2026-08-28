/// Single Premium gate — features never duplicate membership logic.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../models/premium_entitlement_state.dart';
import '../presentation/reference/premium_entry_sheet.dart';
import '../providers/premium_providers.dart';

abstract final class PremiumAccess {
  PremiumAccess._();

  /// Commerce entitlement — never a widget-local flag.
  static PremiumEntitlementState entitlementOf(BuildContext context) {
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final status = container.read(premiumStatusProvider);
      if (status.loaded) return status.entitlement;
      return container.read(premiumServiceProvider).isActiveNow
          ? PremiumEntitlementState.active
          : PremiumEntitlementState.inactive;
    } catch (_) {
      return PremiumEntitlementState.error;
    }
  }

  static bool isActive(BuildContext context) =>
      entitlementOf(context).allowsPremiumFeatures;

  static bool ensure(BuildContext context) => isActive(context);

  static void prompt(BuildContext context) {
    PremiumEntrySheet.show(context);
  }
}
