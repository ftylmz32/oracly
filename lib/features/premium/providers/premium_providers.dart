/// Riverpod surface for the single Premium status + billing port.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../controllers/premium_status_controller.dart';

export 'premium_purchase_port_provider.dart' show premiumPurchasePortProvider;

final premiumStatusProvider =
    ChangeNotifierProvider<PremiumStatusController>((ref) {
  final controller = PremiumStatusController(ref.watch(premiumServiceProvider));
  unawaited(controller.load());
  return controller;
});
