import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reading_operation/providers/reading_live_provider.dart';
import '../../reading_operation/services/reading_operation_gateway.dart';
import 'reading_commerce_buyer.dart';
import 'reading_purchase_disk.dart';
import 'reading_purchase_monitor.dart';
import 'reading_purchase_tracker.dart';

final readingPurchaseMonitorProvider = Provider<ReadingPurchaseMonitor>((ref) {
  final buyer = ReadingCommerceBuyer();
  final tracker = ReadingPurchaseTracker(
    memory: DiskReadingPurchases(),
    verify: (update) => verifyReadingPurchase(ref.read(readingOperationSenderProvider), update),
    complete: (update) => buyer.complete(update.purchaseId),
  );
  final monitor = ReadingPurchaseMonitor(
    tracker: tracker,
    updates: buyer.updates,
    buyProduct: buyer.buy,
    storePrices: buyer.storePrices,
  );
  ref.onDispose(monitor.dispose);
  unawaited(monitor.start());
  return monitor;
});

Future<ReadingVerifyOutcome> verifyReadingPurchase(
  ReadingOperationSender? send,
  ReadingPurchaseUpdate update,
) async {
  if (send == null) return ReadingVerifyOutcome.unavailable;
  final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  final wire = await send('POST', '/v1/reading-entitlements/verify', {
    'platform': platform,
    'productId': update.productId,
    'purchaseToken': update.token,
  });
  if (wire == null || wire.statusCode >= 500) return ReadingVerifyOutcome.unavailable;
  if (wire.json?['data']?['granted'] == true) return ReadingVerifyOutcome.granted;
  if (wire.json?['data']?['reason'] == 'pending') return ReadingVerifyOutcome.unavailable;
  return ReadingVerifyOutcome.rejected;
}
