import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/notifications/memory_notification_port.dart';
import 'package:oracly_new/core/notifications/oracly_notification_providers.dart';
import 'package:oracly_new/features/premium/providers/premium_purchase_port_provider.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:oracly_new/features/premium/services/unavailable_premium_purchase.dart';

Widget buildProviderScopeHarness({
  required LocalStorage storage,
  required Widget child,
  PremiumPurchasePort? purchasePort,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(storage),
      secureStorageProvider.overrideWithValue(InMemorySecureStorage()),
      oraclyNotificationPortProvider.overrideWithValue(
        MemoryNotificationPort(),
      ),
      // Widget tests stay store-closed unless a real/test port is supplied.
      premiumPurchasePortProvider.overrideWithValue(
        purchasePort ?? const UnavailablePremiumPurchase(),
      ),
      ...overrides,
    ],
    child: child,
  );
}
