/// Atmospheric music bed — deterministic file-backed zodiac loop.
library;

import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../features/birth_chart/models/zodiac_sign_id.dart';
import '../runtime/oracly_apply_outcome.dart';
import 'oracly_ambient_audio_context.dart';
import 'oracly_ambient_interruptions.dart';
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
    OraclyAudioInterruptions interruptions =
        const OraclyPlatformAudioInterruptions(),
    Duration guardInterval = const Duration(seconds: 3),
    Duration fadeStep = const Duration(milliseconds: 45),
  }) : _playbackFactory = playbackFactory,
       _tempDirectory = tempDirectory ?? _defaultTempDirectory,
       _playingTimeout = playingTimeout,
       _interruptions = interruptions,
       _guardInterval = guardInterval,
       _fadeStep = fadeStep;

  final OraclyAmbientPlayback Function()? _playbackFactory;
  final Future<Directory> Function() _tempDirectory;
  final Duration _playingTimeout;
  final OraclyAudioInterruptions _interruptions;
  final Duration _guardInterval;
  final Duration _fadeStep;
  OraclyAmbientPlayback? _player;
  Timer? _guard;
  final _files = <ZodiacSignId, File>{};
  Directory? _ownedDirectory;
  bool _ready = false;
  bool _enabled = false;
  bool _lifecyclePaused = false;
  bool _disposed = false;
  bool _ducked = false;
  bool _held = false;
  double _level = OraclyAtmospherePalette.volume /
      OraclyAtmospherePalette.maxVolume;
  double _gain = 0;
  int _epoch = 0;
  Future<void> _operationTail = Future<void>.value();
  ZodiacSignId _sign = ZodiacSignId.cancer;

  bool get enabled => _enabled;
  ZodiacSignId get sign => _sign;

  /// User level 0…1 (Settings slider).
  double get level => _level;

  /// ON, but waiting silently for a call or another app's audio to end.
  bool get held => _held;

  /// Last gain sent to the player.
  double get gain => _gain;

  double get _target =>
      OraclyAtmospherePalette.gainFor(_level) *
      (_ducked ? OraclyAtmospherePalette.speechDuck : 1);

  bool get _audible =>
      !_held && !_lifecyclePaused && _player?.state == PlayerState.playing;

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
    if (!enabled) {
      _epoch++;
      final outcome = await stop();
      if (outcome.isSuccess) _enabled = false;
      return outcome;
    }
    // Re-saving Settings must not restart a bed that is already sounding.
    if (_enabled && (_audible || _held)) return OraclyApplyOutcome.success;
    _epoch++;
    _enabled = true;
    return refresh(epoch: _epoch);
  }

  Future<OraclyApplyOutcome> setSign(ZodiacSignId sign) async {
    if (_sign == sign) return OraclyApplyOutcome.success;
    _epoch++;
    _sign = sign;
    return _enabled ? refresh(epoch: _epoch) : OraclyApplyOutcome.success;
  }

  /// New user level; a sounding bed glides there instead of jumping.
  Future<void> setLevel(double level) async {
    final next = level.clamp(0.0, 1.0).toDouble();
    if (next == _level) return;
    _level = next;
    await _glideIfAudible();
  }

  /// Steps back under OR's voice, and returns when it stops.
  Future<void> setDucked(bool ducked) async {
    if (ducked == _ducked) return;
    _ducked = ducked;
    await _glideIfAudible();
  }

  Future<void> _glideIfAudible() async {
    if (_disposed || !_enabled || !_audible) return;
    await _enqueue(() async {
      if (_audible) await _rampTo(_target, steps: 6);
      return OraclyApplyOutcome.success;
    });
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
      // A call or another app's music comes first: stay ON, wait silently.
      if (await _busy(includeOtherAudio: player.state != PlayerState.playing)) {
        if (player.state == PlayerState.playing) await _fadeOutAndStop();
        _held = true;
        _startGuard();
        return OraclyApplyOutcome.success;
      }
      if (token != _epoch || !_enabled) return OraclyApplyOutcome.success;
      final file = await _fileFor(_sign);
      if (player.state == PlayerState.playing) await _rampTo(0, steps: 5);
      await player.stop();
      if (token != _epoch || !_enabled) return OraclyApplyOutcome.success;
      await _setGain(0);
      await player.playFile(file.path);
      if (!await _provePlaying(player, token)) {
        if (token == _epoch) await player.stop();
        return OraclyApplyOutcome.failure;
      }
      _held = false;
      await _fadeIn(epoch: token);
      _startGuard();
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
    _stopGuard();
    await _enqueue(() async {
      try {
        if (_player?.state == PlayerState.playing) {
          await _rampTo(0, steps: 3);
        }
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
    final epoch = _epoch;
    final player = _player;
    try {
      if (!_held &&
          player?.state == PlayerState.paused &&
          !await _busy(includeOtherAudio: false)) {
        await player!.resume();
        if (await _provePlaying(player, epoch)) {
          await _fadeIn(epoch: epoch);
          _startGuard();
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
    _stopGuard();
    _held = false;
    try {
      await _fadeOutAndStop();
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
    _stopGuard();
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

  /// Soft arrival (~0.5 s) — never an intro sting.
  Future<void> _fadeIn({required int epoch}) async {
    if (_player == null) return;
    final from = _gain;
    const steps = 12;
    for (var i = 1; i <= steps; i++) {
      if (epoch != _epoch || !_enabled || _lifecyclePaused) return;
      await _setGain(from + (_target - from) * (i / steps));
      await Future<void>.delayed(_fadeStep);
    }
  }

  /// Short glide to [to]; used for level, ducking and soft exits.
  Future<void> _rampTo(double to, {required int steps}) async {
    final from = _gain;
    for (var i = 1; i <= steps; i++) {
      await _setGain(from + (to - from) * (i / steps));
      await Future<void>.delayed(_fadeStep);
    }
  }

  Future<void> _fadeOutAndStop() async {
    final player = _player;
    if (player == null) return;
    if (player.state == PlayerState.playing && _gain > 0) {
      await _rampTo(0, steps: 6);
    }
    await player.stop();
    await _setGain(0);
  }

  Future<void> _setGain(double value) async {
    final player = _player;
    if (player == null) return;
    await player.setVolume(value);
    _gain = value;
  }

  Future<bool> _busy({required bool includeOtherAudio}) async {
    if (await _interruptions.callActive()) return true;
    return includeOtherAudio && await _interruptions.otherAudioActive();
  }

  /// While ON in the foreground: yield to a call, come back once the device
  /// is quiet again. Only ever pauses ourselves — never another app.
  void _startGuard() {
    if (_disposed || !_enabled || _lifecyclePaused) return;
    _guard ??= Timer.periodic(_guardInterval, (_) => _onGuardTick());
  }

  void _stopGuard() {
    _guard?.cancel();
    _guard = null;
  }

  Future<void> _onGuardTick() async {
    if (_disposed || !_enabled || _lifecyclePaused) {
      _stopGuard();
      return;
    }
    if (_audible) {
      if (!await _interruptions.callActive()) return;
      await _enqueue(() async {
        if (!_audible) return OraclyApplyOutcome.success;
        await _rampTo(0, steps: 4);
        await _player?.pause();
        _held = true;
        return OraclyApplyOutcome.success;
      });
      return;
    }
    if (_held && !await _busy(includeOtherAudio: true)) {
      await refresh();
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
