/// Whether Daily Message may freeze today's snapshot.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A loading provider is not settled. A value or a terminal error is.
abstract final class DailyMessageReadiness {
  static bool settled(AsyncValue<Object?> value) =>
      value.hasValue || value.hasError;

  static bool all({
    required AsyncValue<Object?> profile,
    required AsyncValue<Object?> discovery,
    required AsyncValue<Object?> settings,
  }) => settled(profile) && settled(discovery) && settled(settings);
}
