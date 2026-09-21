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
      return PremiumEntitlementState.inactive;
    } catch (_) {
      return PremiumEntitlementState.error;
    }
  }

  /// Commerce entitlement OR an active Play/App Store reviewer grant — the
  /// single boolean every feature gate should call.
  static bool isActive(BuildContext context) {
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final status = container.read(premiumStatusProvider);
      return status.loaded && status.isPremium;
    } catch (_) {
      return false;
    }
  }

  static bool ensure(BuildContext context) => isActive(context);

  /// R3 — await a fresh reconciliation when stale, then gate.
  /// Returns false (and optionally prompts) when definitively inactive.
  static Future<bool> ensureFresh(
    BuildContext context, {
    bool promptIfInactive = true,
  }) async {
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      var status = container.read(premiumStatusProvider);

      // Production Premium is owner-bound. Home may become visible while the
      // deferred Firebase/local-owner isolation is still converging, so an
      // owner mismatch here means "not proven yet", not "Free". Complete/join
      // the canonical auth session first, then re-read the provider because
      // auth readiness may have rebuilt the repository/status controller.
      if (!status.ownerAccessReady) {
        await container.read(authServiceProvider).ensureAnonymousSession();
        if (!context.mounted) return false;
        status = container.read(premiumStatusProvider);
        if (!status.ownerAccessReady) return false;
      }

      await status.ensureFresh();
      if (!context.mounted) return false;
      if (status.isPremium) return true;
      if (promptIfInactive) prompt(context);
      return false;
    } catch (_) {
      return false;
    }
  }

  /// R3 — server denial self-heal. Forces reconcile; never auto-retries paid
  /// work. Returns true when Premium remains active after re-verify.
  static Future<bool> healAfterEntitlementDenial(BuildContext context) async {
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final status = container.read(premiumStatusProvider);
      await status.forceReconcile();
      if (!context.mounted) return false;
      return status.isPremium;
    } catch (_) {
      return false;
    }
  }

  static void prompt(BuildContext context) {
    PremiumEntrySheet.show(context);
  }
}
