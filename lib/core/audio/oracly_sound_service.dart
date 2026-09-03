/// EPIC-015 / Phase 5 — SFX + optional personal atmospheric music.
library;

import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../features/birth_chart/models/zodiac_sign_id.dart';
import '../../features/tarot/presentation/widgets/card_reveal/reveal_sound_callbacks.dart';
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
    try {
      await _ambient.ensureReady();
    } catch (_) {}
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
      _sfxReady = false;
      assert(() {
        debugPrint('[ORACLY] sfx init failed: $e');
        return true;
      }());
    }
  }

  void syncSfxEnabled(bool enabled) => _sfxEnabled = enabled;

  Future<void> stopSfx() async {
    try {
      await _sfx?.stop();
    } catch (_) {}
  }

  Future<void> syncAmbientEnabled(bool enabled) => _ambient.setEnabled(enabled);

  Future<void> setAtmosphere(ZodiacSignId sign) => _ambient.setSign(sign);

  Future<void> setChamber(OraclySoundChamber chamber) async {
    if (!_ambient.enabled) {
      await _ambient.stop();
      return;
    }
    if (chamber == OraclySoundChamber.silence) {
      await _ambient.stop();
      return;
    }
    await _ambient.refresh();
  }

  Future<void> refreshAmbient() => _ambient.refresh();

  Future<void> pauseAmbientForBackground() => _ambient.pauseForBackground();

  Future<void> resumeAmbientFromBackground() =>
      _ambient.resumeFromBackground();

  Future<void> stopAmbient() => _ambient.stop();

  void syncEnabled(bool enabled) => syncSfxEnabled(enabled);

  Future<void> play(OraclySoundCue cue) async {
    if (!_sfxEnabled) return;
    await ensureSfxReady();
    if (!_sfxEnabled || !_sfxReady) return;
    final sfx = _sfx;
    if (sfx == null) return;

    final cooldown = _cooldowns[cue];
    if (cooldown != null) {
      final last = _lastCueAt[cue];
      if (last != null && DateTime.now().difference(last) < cooldown) return;
    }
    _lastCueAt[cue] = DateTime.now();

    final detune = 0.98 + _rng.nextDouble() * 0.04;
    final bytes = OraclySfxCues.bytesFor(cue, detune);
    if (bytes.length <= 44) return;

    try {
      final source = BytesSource(bytes, mimeType: 'audio/wav');
      await sfx.stop();
      await sfx.play(source);
    } catch (e) {
      assert(() {
        debugPrint('[ORACLY] sfx play failed ($cue): $e');
        return true;
      }());
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
