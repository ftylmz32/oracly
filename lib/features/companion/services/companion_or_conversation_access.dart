/// OR conversation entitlement — PremiumEntitlementState from commerce only.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../premium/models/premium_entitlement_state.dart';
import '../../premium/providers/premium_providers.dart';
import '../../premium/services/premium_access.dart';
import '../presentation/reference/companion_reference_or_premium_sheet.dart';

abstract final class CompanionOrConversationAccess {
  CompanionOrConversationAccess._();

  static PremiumEntitlementState stateOf(BuildContext context) =>
      PremiumAccess.entitlementOf(context);

  static PremiumEntitlementState watch(WidgetRef ref) =>
      ref.watch(premiumStatusProvider).entitlement;

  static bool isAllowed(BuildContext context) =>
      stateOf(context).allowsPremiumFeatures;

  /// True when active. Otherwise opens the OR paywall and returns false.
  static bool ensure(BuildContext context) {
    if (isAllowed(context)) return true;
    showGate(context);
    return false;
  }

  static Future<void> showGate(BuildContext context) {
    return CompanionReferenceOrPremiumSheet.show(context);
  }
}
