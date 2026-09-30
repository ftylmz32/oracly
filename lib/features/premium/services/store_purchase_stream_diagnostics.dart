/// Safe purchase-stream drop diagnostics — no tokens/JWS/receipts/payloads.
library;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/domain/models/premium_plan.dart';
import '../../../core/logging/logger.dart';

abstract final class StorePurchaseStreamDiagnostics {
  StorePurchaseStreamDiagnostics._();

  static final _log = Logger('StorePremiumPurchase');

  static void logDropped({
    required String reason,
    required PurchaseStatus status,
    required bool recognized,
    PremiumPlanKind? expected,
    PremiumPlanKind? actual,
  }) {
    final platform =
        defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
    _log.warning(
      'purchase_stream_dropped',
      'reason=$reason status=${status.name} '
      'product=${recognized ? 'recognized' : 'unknown'} '
      'expected=${expected?.name ?? 'none'} '
      'actual=${actual?.name ?? 'none'} platform=$platform',
    );
  }
}
