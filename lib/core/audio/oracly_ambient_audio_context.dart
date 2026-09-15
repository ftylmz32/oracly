/// Ambient player audio session config (Android media + iOS ambient mix).
library;

import 'package:audioplayers/audioplayers.dart';

// `AudioContextIOS` asserts that `mixWithOthers` is only set EXPLICITLY for
// the `playback`/`playAndRecord`/`multiRoute` categories — for `ambient` the
// option is already implied automatically (see the package's own doc
// comment on `AVAudioSessionOptions.mixWithOthers`), so passing it here
// tripped that assert during construction on EVERY platform (Dart builds
// both `android:`/`iOS:` sub-configs unconditionally), not just iOS —
// confirmed live on an Android device via `[ORACLY] ambient init failed:
// ... Failed assertion: line 178 ...`.
AudioContext oraclyAmbientAudioContext() => AudioContext(
      android: const AudioContextAndroid(
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
      ),
    );
