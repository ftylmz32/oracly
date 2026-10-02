/// Safe purchase-stream diagnostics — no tokens/JWS/receipts/payloads.
///
/// Debug log lines plus a bounded in-memory ring buffer that the hidden
/// store diagnostics sheet can read on a TestFlight device.
library;

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/domain/models/premium_plan.dart';
import '../../../core/logging/logger.dart';
import 'premium_store_catalog.dart';

enum StorePurchaseStreamEventKind {
  listenerAttached,
  purchase,
  emptyBatch,
  dropped,
  streamError,
}

/// One safe stream observation. [product] is a known catalogue id or
/// `unrecognized`; never transaction ids or verification data.
@immutable
class StorePurchaseStreamEvent {
  const StorePurchaseStreamEvent({
    required this.at,
    required this.kind,
    this.status,
    this.product,
    this.reason,
    this.errorType,
  });

  final DateTime at;
  final StorePurchaseStreamEventKind kind;
  final String? status;
  final String? product;
  final String? reason;
  final String? errorType;
}

abstract final class StorePurchaseStreamDiagnostics {
  StorePurchaseStreamDiagnostics._();

  static final _log = Logger('StorePremiumPurchase');

  static const capacity = 24;
  static final _events = ListQueue<StorePurchaseStreamEvent>();

  /// Oldest first.
  static List<StorePurchaseStreamEvent> get recent =>
      List.unmodifiable(_events);

  @visibleForTesting
  static void reset() => _events.clear();

  static String safeProduct(String productId) =>
      PremiumStoreCatalog.kindFor(productId) == null
      ? 'unrecognized'
      : productId.trim();

  static void recordListenerAttached() =>
      _add(StorePurchaseStreamEventKind.listenerAttached);

  static void recordEmptyBatch() =>
      _add(StorePurchaseStreamEventKind.emptyBatch);

  static void recordPurchase(PurchaseDetails purchase) => _add(
    StorePurchaseStreamEventKind.purchase,
    status: purchase.status.name,
    product: safeProduct(purchase.productID),
  );

  /// Error TYPE only — stream error payloads are never kept.
  static void recordStreamError(Object error) => _add(
    StorePurchaseStreamEventKind.streamError,
    errorType: error.runtimeType.toString(),
  );

  static void logDropped({
    required String reason,
    required PurchaseStatus status,
    required bool recognized,
    PremiumPlanKind? expected,
    PremiumPlanKind? actual,
  }) {
    _add(
      StorePurchaseStreamEventKind.dropped,
      status: status.name,
      product: actual != null
          ? PremiumStoreCatalog.idFor(actual)
          : (recognized ? null : 'unrecognized'),
      reason: reason,
    );
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

  static void _add(
    StorePurchaseStreamEventKind kind, {
    String? status,
    String? product,
    String? reason,
    String? errorType,
  }) {
    if (_events.length >= capacity) _events.removeFirst();
    _events.addLast(
      StorePurchaseStreamEvent(
        at: DateTime.now().toUtc(),
        kind: kind,
        status: status,
        product: product,
        reason: reason,
        errorType: errorType,
      ),
    );
  }
}
