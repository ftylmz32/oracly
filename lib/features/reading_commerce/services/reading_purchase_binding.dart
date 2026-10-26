import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/auth/user_local_data_isolation.dart';
import '../../../core/storage/premium_purchase_attempt_store.dart';
import '../../reading_operation/providers/reading_live_provider.dart';
import '../../reading_operation/services/reading_operation_gateway.dart';
import 'reading_commerce_buyer.dart';
import 'reading_purchase_disk.dart';
import 'reading_purchase_monitor.dart';
import 'reading_purchase_tracker.dart';

final readingPurchaseMonitorProvider = Provider<ReadingPurchaseMonitor>((ref) {
  final storage = ref.read(localStorageProvider);
  // The same opaque owner tag Premium sends to the store.
  String? ownerTag() {
    final uid = storage.getString(UserLocalDataIsolation.ownerKey);
    return uid == null || uid.isEmpty ? null : PremiumPurchaseAttemptStore.ownerTag(uid);
  }

  final buyer = ReadingCommerceBuyer(ownerTag: ownerTag);
  final tracker = ReadingPurchaseTracker(
    memory: SecureReadingPurchases(
      secure: ref.read(secureStorageProvider),
      currentOwnerTag: ownerTag,
    ),
    currentOwnerTag: ownerTag,
    verify: (update) => verifyReadingPurchase(ref.read(readingOperationSenderProvider), update),
    complete: (update) => buyer.complete(update.purchaseId),
  );
  final monitor = ReadingPurchaseMonitor(
    tracker: tracker,
    updates: buyer.updates,
    buyProduct: buyer.buy,
    storePrices: buyer.storePrices,
    storeUnfinished: buyer.unfinishedPurchases,
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
