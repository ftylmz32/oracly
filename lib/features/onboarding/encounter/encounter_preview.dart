/// Debug-only isolated encounter. Release builds never take this path.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract final class EncounterPreview {
  EncounterPreview._();

  static const _channel = MethodChannel('oracly/debug');

  static Future<bool> requested() async {
    if (kReleaseMode) return false;
    try {
      final value = await _channel.invokeMethod<bool>('encounterPreview');
      return value == true;
    } catch (_) {
      return false;
    }
  }
}
