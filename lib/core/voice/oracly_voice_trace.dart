/// Debug voice timing — lengths and flags only, never spoken text.
library;

import 'package:flutter/foundation.dart';

void logOrVoice({
  required String path,
  required int bytes,
  required int ttsMs,
  required int firstAudioMs,
  required bool failed,
}) {
  if (!kDebugMode) return;
  debugPrint(
    'OR_VOICE: path=$path bytes=$bytes ttsMs=$ttsMs firstAudioMs=$firstAudioMs '
    'premiumFailed=${failed ? 'yes' : 'no'}',
  );
}
