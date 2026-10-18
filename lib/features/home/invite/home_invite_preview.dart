/// Debug-only invite preview. Release builds never read the launch extra.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// `guest` shows the invite over a missing profile; `complete` hides it.
/// Either way nothing is written.
enum HomeInvitePreview {
  guest,
  complete;

  static const _channel = MethodChannel('oracly/debug');

  static HomeInvitePreview? parse(String? raw) => switch (raw) {
    'guest' => guest,
    'complete' => complete,
    _ => null,
  };

  static Future<HomeInvitePreview?> requested() async {
    if (kReleaseMode) return null;
    try {
      return parse(await _channel.invokeMethod<String>('homeInvitePreview'));
    } catch (_) {
      return null;
    }
  }
}
