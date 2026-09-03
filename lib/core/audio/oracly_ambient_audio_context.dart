/// Ambient player audio session config (Android media + iOS ambient mix).
library;

import 'package:audioplayers/audioplayers.dart';

AudioContext oraclyAmbientAudioContext() => AudioContext(
      android: const AudioContextAndroid(
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
        options: const {AVAudioSessionOptions.mixWithOthers},
      ),
    );
