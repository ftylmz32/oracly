/// Is the device busy with someone else's sound? Ambient music yields to it.
library;

import 'package:flutter/services.dart';

abstract interface class OraclyAudioInterruptions {
  /// Another app's music/media is playing (checked only while we are silent).
  Future<bool> otherAudioActive();

  /// A call is ringing or in progress.
  Future<bool> callActive();
}

/// Android answers through `oracly/audio` (AudioManager, no permission).
/// iOS has no handler: the `ambient` session category already mixes politely
/// and is interrupted by calls, so a missing handler means "not busy".
class OraclyPlatformAudioInterruptions implements OraclyAudioInterruptions {
  const OraclyPlatformAudioInterruptions();

  static const _channel = MethodChannel('oracly/audio');

  Future<bool> _ask(String method) async {
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> otherAudioActive() => _ask('otherAudioActive');

  @override
  Future<bool> callActive() => _ask('callActive');
}
