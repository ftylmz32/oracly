/// Atmospheric music bed — deterministic file-backed zodiac loop.
library;

import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../features/birth_chart/models/zodiac_sign_id.dart';
import '../runtime/oracly_apply_outcome.dart';
import 'oracly_ambient_audio_context.dart';
import 'oracly_atmosphere_palette.dart';
import 'oracly_wav_synth.dart';

abstract interface class OraclyAmbientPlayback {
  PlayerState get state;
  Future<void> initialize();
  Future<void> playFile(String path);
  Future<void> setVolume(double volume);
  Future<void> stop();
  Future<void> pause();
  Future<void> resume();
  Future<void> dispose();
}

class _AudioPlayersAmbientPlayback implements OraclyAmbientPlayback {
  _AudioPlayersAmbientPlayback(Object owner)
    : _player = AudioPlayer(
        playerId: 'oracly_ambient_${identityHashCode(owner)}',
      );

  final AudioPlayer _player;
  @override
  PlayerState get state => _player.state;

  @override
  Future<void> initialize() async {
    await _player.setPlayerMode(PlayerMode.mediaPlayer);
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(0);
    await _player.setAudioContext(oraclyAmbientAudioContext());
  }

  @override
  Future<void> playFile(String path) => _player.play(DeviceFileSource(path));
  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);
  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> resume() => _player.resume();
  @override
  Future<void> dispose() => _player.dispose();
}

class OraclyAmbientBed {
  OraclyAmbientBed({
    OraclyAmbientPlayback Function()? playbackFactory,
    Future<Directory> Function()? tempDirectory,
    Duration playingTimeout = const Duration(milliseconds: 800),
  }) : _playbackFactory = playbackFactory,
       _tempDirectory = tempDirectory ?? _defaultTempDirectory,
       _playingTimeout = playingTimeout;

  final OraclyAmbientPlayback Function()? _playbackFactory;
  final Future<Directory> Function() _tempDirectory;
  final Duration _playingTimeout;
  OraclyAmbientPlayback? _player;
  final _files = <ZodiacSignId, File>{};
  Directory? _ownedDirectory;
  bool _ready = false;
  bool _enabled = false;
  bool _lifecyclePaused = false;
  bool _disposed = false;
  int _epoch = 0;
  Future<void> _operationTail = Future<void>.value();
  ZodiacSignId _sign = ZodiacSignId.cancer;

  bool get enabled => _enabled;
  ZodiacSignId get sign => _sign;

  Future<bool> ensureReady() async {
    if (_ready) return true;
    try {
      _player ??=
          _playbackFactory?.call() ?? _AudioPlayersAmbientPlayback(this);
      await _player!.initialize();
      _ready = true;
      return true;
    } catch (e) {
      await _discardPlayer();
      debugPrint('[ORACLY] ambient init failed: $e');
      return false;
    }
  }

  Future<OraclyApplyOutcome> setEnabled(bool enabled) async {
    if (_disposed) return OraclyApplyOutcome.failure;
    _epoch++;
    final epoch = _epoch;
    if (!enabled) {
      final outcome = await stop();
      if (outcome.isSuccess) _enabled = false;
      return outcome;
    }
    _enabled = true;
    return refresh(epoch: epoch);
  }

  Future<OraclyApplyOutcome> setSign(ZodiacSignId sign) async {
    if (_sign == sign) return OraclyApplyOutcome.success;
    _epoch++;
    _sign = sign;
    return _enabled ? refresh(epoch: _epoch) : OraclyApplyOutcome.success;
  }

  Future<OraclyApplyOutcome> refresh({int? epoch}) =>
      _enqueue(() => _refreshNow(epoch: epoch));

  Future<OraclyApplyOutcome> _refreshNow({int? epoch}) async {
    final token = epoch ?? _epoch;
    if (_disposed) return OraclyApplyOutcome.failure;
    if (!await ensureReady()) return OraclyApplyOutcome.failure;
    if (token != _epoch) return OraclyApplyOutcome.success;
    if (!_enabled || _lifecyclePaused) return _stopNow();
    final player = _player;
    if (player == null) return OraclyApplyOutcome.failure;
    try {
      final file = await _fileFor(_sign);
      await player.stop();
      if (token != _epoch || !_enabled) return OraclyApplyOutcome.success;
      await player.setVolume(0);
      await player.playFile(file.path);
      if (!await _provePlaying(player, token)) {
        if (token == _epoch) await player.stop();
        return OraclyApplyOutcome.failure;
      }
      await _fadeIn(epoch: token);
      return OraclyApplyOutcome.success;
    } catch (e) {
      debugPrint('[ORACLY] ambient play failed ($_sign): $e');
      if (token == _epoch) await _stopNow();
      return OraclyApplyOutcome.failure;
    }
  }

  Future<void> pauseForBackground() async {
    if (_disposed) return;
    _lifecyclePaused = true;
    _epoch++;
    await _enqueue(() async {
      try {
        await _player?.pause();
        return OraclyApplyOutcome.success;
      } catch (e) {
        debugPrint('[ORACLY] ambient pause failed: $e');
        return OraclyApplyOutcome.failure;
      }
    });
  }

  Future<void> resumeFromBackground() async {
    if (_disposed) return;
    _lifecyclePaused = false;
    _epoch++;
    if (!_enabled) return;
    final player = _player;
    try {
      if (player?.state == PlayerState.paused) {
        await player!.resume();
        if (await _provePlaying(player, _epoch)) {
          await player.setVolume(OraclyAtmospherePalette.volume);
          return;
        }
      }
    } catch (e) {
      debugPrint('[ORACLY] ambient resume failed: $e');
    }
    await refresh();
  }

  Future<OraclyApplyOutcome> stop() => _enqueue(_stopNow);

  Future<OraclyApplyOutcome> _stopNow() async {
    try {
      await _player?.stop();
      await _player?.setVolume(0);
      return OraclyApplyOutcome.success;
    } catch (e) {
      debugPrint('[ORACLY] ambient stop failed: $e');
      return OraclyApplyOutcome.failure;
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _epoch++;
    await _enqueue(() async {
      await _stopNow();
      await _discardPlayer();
      final directory = _ownedDirectory;
      _ownedDirectory = null;
      _files.clear();
      if (directory != null) {
        try {
          await directory.delete(recursive: true);
        } catch (_) {}
      }
      return OraclyApplyOutcome.success;
    });
  }

  Future<File> _fileFor(ZodiacSignId sign) async {
    final cached = _files[sign];
    if (cached != null && await cached.exists()) return cached;
    final bytes = OraclyWavSynth.zodiacAtmosphere(sign);
    if (bytes.length <= 44) throw StateError('empty ambient WAV');
    _ownedDirectory ??= await _tempDirectory();
    final file = File(
      '${_ownedDirectory!.path}${Platform.pathSeparator}zodiac_${sign.name}.wav',
    );
    await file.writeAsBytes(bytes, flush: true);
    _files[sign] = file;
    return file;
  }

  Future<bool> _provePlaying(OraclyAmbientPlayback player, int epoch) async {
    final deadline = DateTime.now().add(_playingTimeout);
    var consecutivePlaying = 0;
    do {
      if (epoch != _epoch || !_enabled || _lifecyclePaused) return false;
      if (player.state == PlayerState.playing) {
        consecutivePlaying++;
        if (consecutivePlaying >= 3) return true;
      } else {
        consecutivePlaying = 0;
      }
      await Future<void>.delayed(const Duration(milliseconds: 25));
    } while (DateTime.now().isBefore(deadline));
    return false;
  }

  Future<void> _fadeIn({required int epoch}) async {
    final player = _player;
    if (player == null) return;
    for (var i = 1; i <= 10; i++) {
      if (epoch != _epoch || !_enabled || _lifecyclePaused) return;
      await player.setVolume(OraclyAtmospherePalette.volume * (i / 10));
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
  }

  Future<void> _discardPlayer() async {
    try {
      await _player?.dispose();
    } catch (_) {}
    _player = null;
    _ready = false;
  }

  Future<OraclyApplyOutcome> _enqueue(
    Future<OraclyApplyOutcome> Function() action,
  ) {
    final completer = Completer<OraclyApplyOutcome>();
    _operationTail = _operationTail.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  static Future<Directory> _defaultTempDirectory() =>
      Directory.systemTemp.createTemp('oracly_ambient_');
}
