/// Dedicated OR speech player — not SFX, never silent fake files.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

abstract class OraclySpeechSink {
  void Function()? onComplete;
  void Function()? onInterrupted;

  Future<void> play(List<int> bytes, {String mimeType = 'audio/mpeg'});

  Future<void> stop();

  Future<void> pause() async {}

  Future<void> resume() async {}
}

class OraclySpeechPlayer implements OraclySpeechSink {
  OraclySpeechPlayer({AudioPlayer? player}) : _injected = player;

  final AudioPlayer? _injected;
  AudioPlayer? _created;
  StreamSubscription<void>? _completeSub;
  StreamSubscription<PlayerState>? _stateSub;
  bool _ready = false;
  bool _expectPlaying = false;
  bool _selfStop = false;

  AudioPlayer get _player =>
      _injected ?? (_created ??= AudioPlayer(playerId: 'oracly_or_tts'));

  @override
  void Function()? onComplete;

  @override
  void Function()? onInterrupted;

  Future<void> ensureReady() async {
    if (_ready) return;
    await _player.setPlayerMode(PlayerMode.mediaPlayer);
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(1);
    await _player.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.speech,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.mixWithOthers},
        ),
      ),
    );
    await _completeSub?.cancel();
    await _stateSub?.cancel();
    _completeSub = _player.onPlayerComplete.listen((_) {
      _expectPlaying = false;
      onComplete?.call();
    });
    _stateSub = _player.onPlayerStateChanged.listen(_onState);
    _ready = true;
  }

  void _onState(PlayerState state) {
    if (!_expectPlaying || _selfStop) return;
    // Phone call / focus loss / external stop — never leave speaking stuck.
    if (state == PlayerState.paused || state == PlayerState.stopped) {
      _expectPlaying = false;
      onInterrupted?.call();
    }
  }

  Future<void> dispose() async {
    _ready = false;
    _expectPlaying = false;
    await _completeSub?.cancel();
    await _stateSub?.cancel();
    _completeSub = null;
    _stateSub = null;
    try {
      await _created?.dispose();
    } catch (_) {}
    _created = null;
    try {
      final file = File('${Directory.systemTemp.path}/oracly_or_tts.mp3');
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  @override
  Future<void> play(List<int> bytes, {String mimeType = 'audio/mpeg'}) async {
    if (bytes.length < 32) return;
    await ensureReady();
    _selfStop = true;
    await _player.stop();
    _selfStop = false;
    _expectPlaying = true;
    try {
      final file = File('${Directory.systemTemp.path}/oracly_or_tts.mp3');
      await file.writeAsBytes(bytes, flush: true);
      await _player.play(DeviceFileSource(file.path));
    } catch (_) {
      final source = bytes is Uint8List
          ? bytes
          : Uint8List.fromList(bytes);
      await _player.play(
        BytesSource(source, mimeType: mimeType),
      );
    }
  }

  @override
  Future<void> stop() async {
    if (!_ready) return;
    _selfStop = true;
    _expectPlaying = false;
    try {
      await _player.stop();
    } catch (_) {}
    _selfStop = false;
    try {
      final file = File('${Directory.systemTemp.path}/oracly_or_tts.mp3');
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  @override
  Future<void> pause() async {
    if (!_ready) return;
    _selfStop = true;
    try {
      await _player.pause();
    } catch (_) {}
    _selfStop = false;
  }

  @override
  Future<void> resume() async {
    if (!_ready) return;
    _expectPlaying = true;
    try {
      await _player.resume();
    } catch (_) {}
  }
}
