/// Terminal purchased/restored handling for [StorePremiumPurchaseSession].
library;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/domain/models/premium_plan.dart';
import '../models/premium_purchase_credentials.dart';
import '../models/premium_purchase_result.dart';
import 'premium_plan_availability.dart';
import 'store_purchase_stream_diagnostics.dart';

/// Durable UNVERIFIED recovery material (never grants Premium). Must throw
/// when nothing durable was written, so the transaction is not finished.
typedef PersistRetryCredentials =
    Future<void> Function(PremiumPurchaseCredentials credentials);

abstract final class StorePurchaseTerminalHandler {
  StorePurchaseTerminalHandler._();

  static Future<PremiumPurchaseResult?> apply({
    required PurchaseDetails purchase,
    required PremiumPlanKind? kind,
    required PremiumPlanKind? expected,
    required bool restore,
    required PersistRetryCredentials? persistRetryCredentials,
    required Future<void> Function(PurchaseDetails purchase) completePurchase,
  }) async {
    if (kind == null) {
      StorePurchaseStreamDiagnostics.logDropped(
        reason: 'unknown_product',
        status: purchase.status,
        recognized: false,
        expected: expected,
      );
      return PremiumPurchaseResult.failed();
    }
    if (expected != null && kind != expected) {
      StorePurchaseStreamDiagnostics.logDropped(
        reason: 'mismatched_plan',
        status: purchase.status,
        recognized: true,
        expected: expected,
        actual: kind,
      );
      return null; // leave pending for store redelivery / Restore
    }
    final creds = PremiumPurchaseCredentials(
      platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      productId: purchase.productID,
      purchaseToken: purchase.verificationData.serverVerificationData,
      transactionId: purchase.purchaseID,
    );
    if (persistRetryCredentials != null &&
        creds.isComplete &&
        PremiumPlanAvailability.isPurchasable(kind)) {
      try {
        await persistRetryCredentials(creds);
      } catch (_) {
        // No durable recovery material: finishing the transaction now could
        // strand a paid purchase if the backend verify then fails, because
        // the store stops redelivering completed transactions. Leave it
        // unfinished for redelivery and report it honestly, never granted.
        StorePurchaseStreamDiagnostics.logDropped(
          reason: 'recovery_persist_failed',
          status: purchase.status,
          recognized: true,
          expected: expected,
          actual: kind,
        );
        return PremiumPurchaseResult.unverified();
      }
    }
    if (purchase.pendingCompletePurchase) {
      await completePurchase(purchase);
    }
    return restore || purchase.status == PurchaseStatus.restored
        ? PremiumPurchaseResult.restored(kind, credentials: creds)
        : PremiumPurchaseResult.granted(kind, credentials: creds);
  }
}
