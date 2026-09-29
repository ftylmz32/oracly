/// Whether Daily Message may freeze today's snapshot.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A loading provider is not settled. A value or a terminal error is.
///
/// Riverpod keeps the previous value while a reload is in flight
/// (`isRefreshing` / `isReloading`). That retained value can belong to the
/// owner who just left, so it is not safe personalization for the new owner.
abstract final class DailyMessageReadiness {
  static bool settled(AsyncValue<Object?> value) {
    if (value.isRefreshing || value.isReloading) return false;
    return value.hasValue || value.hasError;
  }

  static bool all({
    required AsyncValue<Object?> profile,
    required AsyncValue<Object?> discovery,
    required AsyncValue<Object?> settings,
  }) => settled(profile) && settled(discovery) && settled(settings);
}
