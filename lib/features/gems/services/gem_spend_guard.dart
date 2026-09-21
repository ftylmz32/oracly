/// Shared spend check — confirm first, deduct only after success.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/copy/resilience_copy.dart';
import '../../../core/services/analytics_service.dart';
import '../controllers/gem_wallet_controller.dart';
import '../models/paid_ai_operation.dart';
import '../providers/gem_providers.dart';
import 'gem_spend_ui.dart';

abstract final class GemSpendGuard {
  GemSpendGuard._();

  static bool ensureAffordable(
    WidgetRef ref, {
    required BuildContext context,
    required int? cost,
  }) =>
      GemSpendUi.ensureAffordable(ref, context: context, cost: cost);

  static Future<bool> confirmCost(
    WidgetRef ref,
    BuildContext context, {
    required int? cost,
    String? reason,
  }) =>
      GemSpendUi.confirmCost(ref, context, cost: cost, reason: reason);

  /// Ask and check. Never deducts. Returns a stable paid operation when allowed.
  static Future<PaidAiOperation?> beginPaid(
    WidgetRef ref, {
    required BuildContext context,
    required PaidAiFeature feature,
    required String ledgerKey,
    required String reason,
    required int? cost,
    String? existingId,
  }) async {
    if (cost != null && cost > 0) {
      if (!ensureAffordable(ref, context: context, cost: cost)) return null;
      if (!context.mounted) return null;
      final confirmed =
          await confirmCost(ref, context, cost: cost, reason: reason);
      if (!confirmed || !context.mounted) return null;
      // After confirm only — cancel must not count as spend intent.
      ref.read(analyticsServiceProvider).logGemPurchaseStarted(
            reason: _reasonKey(ledgerKey: ledgerKey, reason: reason),
          );
    }
    try {
      return await ref.read(paidAiOperationCoordinatorProvider).begin(
            feature: feature,
            ledgerKey: ledgerKey,
            reason: reason,
            cost: cost,
            existingId: existingId,
          );
    } catch (_) {
      // A billable provider call must never start unless its pending operation
      // was durably recorded first. Storage failure therefore stops here,
      // before AI work and before any server debit can happen.
      if (context.mounted) {
        OraclySnackBar.error(context, ResilienceCopy.temporaryFailure);
      }
      return null;
    }
  }

  /// Legacy confirm-only entry — prefer [beginPaid] for paid AI flows.
  static Future<bool> trySpend(
    WidgetRef ref, {
    required BuildContext context,
    required int? cost,
    required String reason,
    String? ledgerKey,
  }) async {
    if (cost == null || cost <= 0) return true;
    if (!ensureAffordable(ref, context: context, cost: cost)) return false;
    if (!context.mounted) return false;
    final confirmed =
        await confirmCost(ref, context, cost: cost, reason: reason);
    if (!confirmed) return false;
    ref.read(analyticsServiceProvider).logGemPurchaseStarted(
          reason: _reasonKey(ledgerKey: ledgerKey, reason: reason),
        );
    return true;
  }

  /// One deduction after provider success — uses the operation's stable id.
  /// Safe after unmount: charge does not require a live [BuildContext].
  static Future<bool> settleOperation(
    WidgetRef ref, {
    required PaidAiOperation operation,
    BuildContext? context,
  }) {
    // Capture provider-backed objects synchronously. Callers that may outlive
    // their widget should prefer [settleOperationCaptured] and capture these
    // BEFORE starting their long provider request.
    return settleOperationCaptured(
      coordinator: ref.read(paidAiOperationCoordinatorProvider),
      wallet: ref.read(gemWalletProvider),
      analytics: ref.read(analyticsServiceProvider),
      operation: operation,
      context: context,
    );
  }

  static Future<bool> settleOperationCaptured({
    required PaidAiOperationCoordinator coordinator,
    required GemWalletController wallet,
    required AnalyticsService analytics,
    required PaidAiOperation operation,
    BuildContext? context,
  }) async {
    bool ok;
    try {
      ok = await coordinator.completeAfterProvider(operation);
    } catch (_) {
      ok = false;
    }

    // Synchronize the UI-facing wallet from server authority. A stale captured
    // controller is safe: GemWalletService now refuses commands when its owner
    // no longer matches live auth, and GemWalletController suppresses notify
    // after dispose.
    try {
      await wallet.reload();
    } catch (_) {}

    if (ok && operation.isBillable) {
      analytics.logGemPurchaseSuccess(
        reason: _reasonKey(
          ledgerKey: operation.ledgerKey,
          reason: operation.reason,
        ),
      );
    }

    final ctx = context;
    if (!ok && operation.isBillable && ctx != null && ctx.mounted) {
      if (wallet.authoritative && wallet.balance < operation.cost) {
        GemSpendUi.showInsufficient(ctx, cost: operation.cost);
      } else {
        OraclySnackBar.error(ctx, ResilienceCopy.temporaryFailure);
      }
    }
    return ok;
  }

  /// One deduction after a successful provider completion.
  static Future<bool> settle(
    WidgetRef ref, {
    BuildContext? context,
    required String ledgerKey,
    required String actionId,
    required int? cost,
    required String reason,
    PaidAiFeature feature = PaidAiFeature.coffee,
  }) async {
    if (cost == null || cost <= 0) return true;
    final op = await ref.read(paidAiOperationCoordinatorProvider).begin(
          feature: feature,
          ledgerKey: ledgerKey,
          reason: reason,
          cost: cost,
          existingId: actionId,
        );
    return settleOperation(
      ref,
      operation: op,
      context: context != null && context.mounted ? context : null,
    );
  }

  static String _reasonKey({String? ledgerKey, required String reason}) {
    final key = ledgerKey;
    if (key != null && key.endsWith('_gem_charged')) {
      return key.replaceAll('_gem_charged', '');
    }
    return 'feature';
  }
}
