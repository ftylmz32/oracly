/// Injectable wall clock for Home continuity eligibility.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Defaults to wall clock; override in tests for deterministic recall windows.
final homeNowProvider = Provider<DateTime>((ref) => DateTime.now());
