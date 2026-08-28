/// Atmospheric music bed — low-volume zodiac loop (symbolic, not astrology).
library;

import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import '../../features/birth_chart/models/zodiac_sign_id.dart';
import 'oracly_atmosphere_palette.dart';
import 'oracly_wav_synth.dart';

/// Owns the ambient [AudioPlayer] only — independent from SFX.
class OraclyAmbientBed {
  AudioPlayer? _player;
  final _cache = <String, Source>{};
  bool _ready = false;
  bool _enabled = false;
  bool _lifecyclePaused = false;
  int _epoch = 0;
  ZodiacSignId _sign = ZodiacSignId.cancer;

  bool get enabled => _enabled;
  ZodiacSignId get sign => _sign;

  Future<void> ensureReady() async {
    if (_ready) return;
    try {
      _player ??= AudioPlayer(playerId: 'oracly_ambient');
      await _player!.setReleaseMode(ReleaseMode.loop);
      await _player!.setVolume(0);
      await _player!.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.none,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _epoch++;
    final epoch = _epoch;
    _enabled = enabled;
    if (!enabled) {
      await stop();
      return;
    }
    await refresh(epoch: epoch);
  }

  Future<void> setSign(ZodiacSignId sign) async {
    if (_sign == sign) return;
    _sign = sign;
    if (_enabled) await refresh();
  }

  Future<void> refresh({int? epoch}) async {
    final token = epoch ?? _epoch;
    await ensureReady();
    if (token != _epoch) return;
    if (!_enabled || !_ready || _lifecyclePaused) {
      if (!_enabled || _lifecyclePaused) await stop();
      return;
    }
    final player = _player;
    if (player == null) return;

    final bytes = OraclyWavSynth.zodiacAtmosphere(_sign);
    if (bytes.isEmpty) return;

    try {
      final source = _sourceFor('zodiac_${_sign.name}', bytes);
      await player.stop();
      if (token != _epoch || !_enabled) return;
      await player.setVolume(0);
      await player.play(source);
      await _fadeIn(epoch: token);
    } catch (_) {}
  }

  Future<void> pauseForBackground() async {
    _lifecyclePaused = true;
    try {
      await _player?.pause();
    } catch (_) {}
  }

  Future<void> resumeFromBackground() async {
    _lifecyclePaused = false;
    if (!_enabled) return;
    await ensureReady();
    final player = _player;
    if (player == null || !_ready) return;
    try {
      if (player.state == PlayerState.paused) {
        await player.resume();
        await player.setVolume(OraclyAtmospherePalette.volume);
        return;
      }
    } catch (_) {}
    await refresh();
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
      await _player?.setVolume(0);
    } catch (_) {}
  }

  Future<void> dispose() async {
    _epoch++;
    await stop();
    await _player?.dispose();
    _player = null;
    _ready = false;
  }

  Source _sourceFor(String key, Uint8List bytes) {
    return _cache.putIfAbsent(
      key,
      () => BytesSource(bytes, mimeType: 'audio/wav'),
    );
  }

  Future<void> _fadeIn({required int epoch}) async {
    final player = _player;
    if (player == null) return;
    final target = OraclyAtmospherePalette.volume;
    for (var i = 1; i <= 10; i++) {
      if (epoch != _epoch || !_enabled || _lifecyclePaused) return;
      await player.setVolume(target * (i / 10));
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
  }
}
