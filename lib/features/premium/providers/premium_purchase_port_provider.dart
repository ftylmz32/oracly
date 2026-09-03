/// Billing port provider - real store on mobile when products load.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/premium_purchase_port.dart';
import '../services/premium_store_test_env_io.dart'
    if (dart.library.html) '../services/premium_store_test_env_stub.dart';
import '../services/store_premium_purchase.dart';
import '../services/unavailable_premium_purchase.dart';

/// Mobile: [StorePremiumPurchase] (purchase needs catalogue; restore needs store).
/// Desktop/web/tests: closed store - honest unavailable UI.
final premiumPurchasePortProvider = Provider<PremiumPurchasePort>((ref) {
  if (premiumStoreUnderFlutterTest ||
      !StorePremiumPurchase.supportedPlatform) {
    return const UnavailablePremiumPurchase();
  }
  final port = StorePremiumPurchase();
  ref.onDispose(() => unawaited(port.dispose()));
  return port;
});
