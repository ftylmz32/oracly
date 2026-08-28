/// Android Google TTS only. Never sent to the HQ proxy.
library;

import 'package:flutter/foundation.dart';

abstract final class OraclyDeviceSsml {
  OraclyDeviceSsml._();

  static String maybeWrap(String body, {required bool googleAndroid}) {
    if (!googleAndroid || kIsWeb) return body;
    if (defaultTargetPlatform != TargetPlatform.android) return body;
    final escaped = body
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    final paced = escaped
        .replaceAll('...', '<break time="380ms"/>')
        .replaceAll('…', '<break time="380ms"/>');
    return '<speak>$paced</speak>';
  }
}
