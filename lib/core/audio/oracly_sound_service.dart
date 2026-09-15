/// EPIC-015 / Phase 5 — SFX + optional personal atmospheric music.
library;

import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../features/birth_chart/models/zodiac_sign_id.dart';
import '../../features/tarot/presentation/widgets/card_reveal/reveal_sound_callbacks.dart';
import '../runtime/oracly_apply_outcome.dart';
import 'oracly_ambient_bed.dart';
import 'oracly_sfx_cues.dart';
import 'oracly_sound_chamber.dart';

class OraclySoundService {
  OraclySoundService();

  final OraclyAmbientBed _ambient = OraclyAmbientBed();
  AudioPlayer? _sfx;
  final _rng = Random();
  final _lastCueAt = <OraclySoundCue, DateTime>{};

  bool _sfxEnabled = true;
  bool _sfxReady = false;

  static const _cooldowns = {
    OraclySoundCue.softTap: Duration(milliseconds: 140),
    OraclySoundCue.buttonTap: Duration(milliseconds: 140),
    OraclySoundCue.selection: Duration(milliseconds: 100),
    OraclySoundCue.cardSlide: Duration(milliseconds: 220),
    OraclySoundCue.orbHum: Duration(milliseconds: 900),
    OraclySoundCue.cardFlip: Duration(milliseconds: 450),
    OraclySoundCue.revealTone: Duration(milliseconds: 700),
    OraclySoundCue.magicalReveal: Duration(milliseconds: 1200),
    OraclySoundCue.journeyComplete: Duration(seconds: 8),
    OraclySoundCue.premiumPurchase: Duration(seconds: 6),
  };

  bool get ambientEnabled => _ambient.enabled;
  ZodiacSignId get atmosphere => _ambient.sign;
  bool get sfxReady => _sfxReady;

  Future<void> initialize() async {
    await ensureSfxReady();
    await _ambient.ensureReady();
  }

  Future<void> ensureSfxReady() async {
    if (_sfxReady) return;
    try {
      _sfx ??= AudioPlayer(playerId: 'oracly_sfx');
      await _sfx!.setPlayerMode(PlayerMode.mediaPlayer);
      await _sfx!.setReleaseMode(ReleaseMode.stop);
      await _sfx!.setVolume(0.68);
      await _sfx!.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
      _sfxReady = true;
    } catch (e) {
      await _resetSfxPlayer();
      // Always logged (not assert-gated) — a release build must still
      // leave a diagnosable trace instead of the failure vanishing.
      debugPrint('[ORACLY] sfx init failed: $e');
    }
  }

  /// Drops a possibly-broken player so the next attempt starts fresh —
  /// a single failed init/play must never permanently poison SFX.
  Future<void> _resetSfxPlayer() async {
    _sfxReady = false;
    final broken = _sfx;
    _sfx = null;
    if (broken != null) {
      try {
        await broken.dispose();
      } catch (_) {}
    }
  }

  void syncSfxEnabled(bool enabled) => _sfxEnabled = enabled;

  Future<void> stopSfx() async {
    try {
      await _sfx?.stop();
    } catch (e) {
      debugPrint('[ORACLY] sfx stop failed: $e');
    }
  }

  Future<OraclyApplyOutcome> syncAmbientEnabled(bool enabled) =>
      _ambient.setEnabled(enabled);

  Future<OraclyApplyOutcome> setAtmosphere(ZodiacSignId sign) =>
      _ambient.setSign(sign);

  Future<OraclyApplyOutcome> setChamber(OraclySoundChamber chamber) async {
    if (!_ambient.enabled) {
      return _ambient.stop();
    }
    if (chamber == OraclySoundChamber.silence) {
      return _ambient.stop();
    }
    return _ambient.refresh();
  }

  Future<OraclyApplyOutcome> refreshAmbient() => _ambient.refresh();

  Future<void> pauseAmbientForBackground() => _ambient.pauseForBackground();

  Future<void> resumeAmbientFromBackground() =>
      _ambient.resumeFromBackground();

  Future<OraclyApplyOutcome> stopAmbient() => _ambient.stop();

  void syncEnabled(bool enabled) => syncSfxEnabled(enabled);

  /// Plays [cue]. Disabled and cooldown-skipped attempts count as success —
  /// only a real, attempted playback failure is reported as [OraclyApplyOutcome.failure].
  /// A failure never poisons future taps: the next call is always retried.
  Future<OraclyApplyOutcome> play(OraclySoundCue cue) async {
    if (!_sfxEnabled) return OraclyApplyOutcome.success;
    await ensureSfxReady();
    if (!_sfxEnabled) return OraclyApplyOutcome.success;
    if (!_sfxReady) return OraclyApplyOutcome.failure;
    final sfx = _sfx;
    if (sfx == null) return OraclyApplyOutcome.failure;

    final cooldown = _cooldowns[cue];
    if (cooldown != null) {
      final last = _lastCueAt[cue];
      if (last != null && DateTime.now().difference(last) < cooldown) {
        return OraclyApplyOutcome.success;
      }
    }
    _lastCueAt[cue] = DateTime.now();

    final detune = 0.98 + _rng.nextDouble() * 0.04;
    final bytes = OraclySfxCues.bytesFor(cue, detune);
    if (bytes.length <= 44) return OraclyApplyOutcome.failure;

    try {
      final source = BytesSource(bytes, mimeType: 'audio/wav');
      await sfx.stop();
      await sfx.play(source);
      return OraclyApplyOutcome.success;
    } catch (e) {
      debugPrint('[ORACLY] sfx play failed ($cue): $e');
      // Drop the possibly-broken player so the very next tap gets a fresh
      // one instead of repeating the same failure forever.
      await _resetSfxPlayer();
      return OraclyApplyOutcome.failure;
    }
  }

  RevealSoundCallbacks get revealCallbacks => RevealSoundCallbacks(
        onRevealStart: () => play(OraclySoundCue.cardSlide),
        onFlipStart: () => play(OraclySoundCue.cardFlip),
        onBloomPeak: () => play(OraclySoundCue.revealTone),
      );

  Future<void> dispose() async {
    await _ambient.dispose();
    await _sfx?.dispose();
    _sfxReady = false;
  }
}
