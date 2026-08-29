/// OR conversation entitlement — Premium, or one contextual first-reading deepen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../ai/oracle_conversation/models/oracle_reading_context.dart';
import '../../premium/models/premium_entitlement_state.dart';
import '../../premium/providers/premium_providers.dart';
import '../../premium/services/premium_access.dart';
import '../presentation/reference/companion_reference_or_premium_sheet.dart';
import 'first_reading_or_deepen.dart';

abstract final class CompanionOrConversationAccess {
  CompanionOrConversationAccess._();

  static PremiumEntitlementState stateOf(BuildContext context) =>
      PremiumAccess.entitlementOf(context);

  static PremiumEntitlementState watch(WidgetRef ref) =>
      ref.watch(premiumStatusProvider).entitlement;

  static bool isAllowed(BuildContext context) =>
      stateOf(context).allowsPremiumFeatures;

  /// Premium always; otherwise one matching unconsumed first-reading deepen.
  static bool canCompose(
    BuildContext context, {
    OracleReadingContext? readingContext,
  }) {
    if (isAllowed(context)) return true;
    final entitlement = stateOf(context);
    if (entitlement.isTransient) return false;
    final storage = ProviderScope.containerOf(
      context,
    ).read(localStorageProvider);
    return FirstReadingOrDeepen.allows(storage, readingContext);
  }

  /// True when active or contextual deepen applies. Else opens OR paywall.
  static bool ensure(
    BuildContext context, {
    OracleReadingContext? readingContext,
  }) {
    if (canCompose(context, readingContext: readingContext)) return true;
    showGate(context);
    return false;
  }

  /// Mic / voice always require Premium — never the free deepen.
  static bool ensurePremium(BuildContext context) {
    if (isAllowed(context)) return true;
    showGate(context);
    return false;
  }

  static Future<void> showGate(BuildContext context) {
    return CompanionReferenceOrPremiumSheet.show(context);
  }
}
