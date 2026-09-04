/// Binds commerce entitlement to the OR paywall.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../premium/providers/premium_providers.dart';
import 'companion_or_premium_purchase.dart';
import 'companion_reference_or_paywall.dart';

class CompanionReferenceOrPaywallHost extends ConsumerWidget {
  const CompanionReferenceOrPaywallHost({
    super.key,
    this.compact = false,
    this.showHero = true,
    this.popOnGranted = false,
  });

  final bool compact;
  final bool showHero;
  final bool popOnGranted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(premiumStatusProvider);
    return CompanionReferenceOrPaywall(
      entitlement: status.entitlement,
      premiumUnlocked: status.isPremium,
      purchaseConfigured: status.purchaseConfigured,
      entitlementMessage: status.entitlementMessage,
      compact: compact,
      showHero: showHero,
      plans: status.plans,
      selectedPlan: status.selectedPlan,
      onSelectPlan: status.selectPlan,
      onPurchase: () async {
        final result = await ref.read(premiumStatusProvider).purchase();
        if (!context.mounted) return;
        await finishCompanionOrPremiumPurchase(
          context: context,
          ref: ref,
          result: result,
          popOnGranted: popOnGranted,
        );
      },
      onRestore: () async {
        final result = await ref.read(premiumStatusProvider).restore();
        if (!context.mounted) return;
        await finishCompanionOrPremiumPurchase(
          context: context,
          ref: ref,
          result: result,
          popOnGranted: popOnGranted,
        );
      },
    );
  }
}
