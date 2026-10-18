/// Atmospheric audio remediation — silent by default, user-controlled,
/// polite to calls and other apps, seamless loop, safe on broken audio.
/// Fake player only: no device audio, no provider call.
library;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/audio/oracly_ambient_bed.dart';
import 'package:oracly_new/core/audio/oracly_ambient_interruptions.dart';
import 'package:oracly_new/core/audio/oracly_atmosphere_palette.dart';
import 'package:oracly_new/core/audio/oracly_wav_synth.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_settings_repository.dart';
import 'package:oracly_new/core/runtime/oracly_apply_outcome.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePlayback implements OraclyAmbientPlayback {
  PlayerState _state = PlayerState.stopped;
  final volumes = <double>[];
  final played = <String>[];
  int stops = 0;
  bool breakPlay = false;

  @override
  PlayerState get state => _state;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> playFile(String path) async {
    if (breakPlay) throw StateError('corrupt audio');
    if (!File(path).existsSync()) throw StateError('missing audio');
    played.add(path);
    _state = PlayerState.playing;
  }

  @override
  Future<void> setVolume(double volume) async => volumes.add(volume);
  @override
  Future<void> stop() async {
    stops++;
    _state = PlayerState.stopped;
  }

  @override
  Future<void> pause() async => _state = PlayerState.paused;
  @override
  Future<void> resume() async => _state = PlayerState.playing;
  @override
  Future<void> dispose() async => _state = PlayerState.disposed;
}

class _FakeInterruptions implements OraclyAudioInterruptions {
  bool call = false;
  bool other = false;
  @override
  Future<bool> callActive() async => call;
  @override
  Future<bool> otherAudioActive() async => other;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakePlayback player;
  late _FakeInterruptions busy;
  late int created;

  OraclyAmbientBed bed() {
    created = 0;
    final b = OraclyAmbientBed(
      playbackFactory: () {
        created++;
        return player;
      },
      tempDirectory: () => Directory.systemTemp.createTemp('oracly_amb_t_'),
      interruptions: busy,
      guardInterval: const Duration(milliseconds: 30),
      fadeStep: Duration.zero,
    );
    addTearDown(b.dispose);
    return b;
  }

  Future<void> wait([int ms = 160]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  setUp(() {
    player = _FakePlayback();
    busy = _FakeInterruptions();
  });

  group('silent by default, remembered', () {
    test('fresh install: music OFF at level 0.7', () async {
      SharedPreferences.setMockInitialValues({});
      final settings =
          await LocalSettingsRepository(await LocalStorage.open()).load();
      expect(settings.ambientMusicEnabled, isFalse);
      expect(settings.ambientMusicLevel, 0.7);
      expect(
        OraclyAtmospherePalette.gainFor(settings.ambientMusicLevel),
        closeTo(OraclyAtmospherePalette.volume, 1e-9),
      );
    });

    test('a bed that was never enabled never plays', () async {
      final b = bed();
      await b.setSign(ZodiacSignId.leo);
      await b.refresh();
      await b.resumeFromBackground();
      expect(player.played, isEmpty);
    });

    test('on/off and level survive an app restart', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = LocalSettingsRepository(await LocalStorage.open());
      await repo.save(
        (await repo.load()).copyWith(
          ambientMusicEnabled: true,
          ambientMusicLevel: 0.35,
        ),
      );
      var reopened =
          await LocalSettingsRepository(await LocalStorage.open()).load();
      expect(reopened.ambientMusicEnabled, isTrue);
      expect(reopened.ambientMusicLevel, 0.35);

      await repo.save(reopened.copyWith(ambientMusicEnabled: false));
      reopened = await LocalSettingsRepository(await LocalStorage.open()).load();
      expect(reopened.ambientMusicEnabled, isFalse);
      expect(reopened.ambientMusicLevel, 0.35);
    });

    test('level is clamped to 0…1', () {
      const s = PersonalizationSettings();
      expect(s.copyWith(ambientMusicLevel: 3).ambientMusicLevel, 1);
      expect(s.copyWith(ambientMusicLevel: -1).ambientMusicLevel, 0);
    });
  });

  group('on / off / level', () {
    test('ON fades in smoothly from silence to the user level', () async {
      final b = bed();
      expect(await b.setEnabled(true), OraclyApplyOutcome.success);
      expect(player.played, hasLength(1));
      expect(player.volumes.first, 0);
      for (var i = 1; i < player.volumes.length; i++) {
        expect(player.volumes[i], greaterThanOrEqualTo(player.volumes[i - 1]));
      }
      expect(b.gain, closeTo(OraclyAtmospherePalette.volume, 1e-9));
    });

    test('OFF fades out before stopping — no cut', () async {
      final b = bed();
      await b.setEnabled(true);
      player.volumes.clear();
      expect(await b.setEnabled(false), OraclyApplyOutcome.success);
      expect(player.state, PlayerState.stopped);
      expect(player.volumes.length, greaterThan(2));
      for (var i = 1; i < player.volumes.length; i++) {
        expect(player.volumes[i], lessThanOrEqualTo(player.volumes[i - 1]));
      }
      expect(player.volumes.last, 0);
    });

    test('level glides live and is kept for the next start', () async {
      final b = bed();
      await b.setLevel(0.25);
      expect(player.volumes, isEmpty);
      await b.setEnabled(true);
      expect(b.gain, closeTo(OraclyAtmospherePalette.gainFor(0.25), 1e-9));
      await b.setLevel(1);
      expect(b.gain, closeTo(OraclyAtmospherePalette.maxVolume, 1e-9));
    });

    test('OR speech ducks the bed and releases it', () async {
      final b = bed();
      await b.setEnabled(true);
      await b.setDucked(true);
      expect(
        b.gain,
        closeTo(
          OraclyAtmospherePalette.volume * OraclyAtmospherePalette.speechDuck,
          1e-9,
        ),
      );
      await b.setDucked(false);
      expect(b.gain, closeTo(OraclyAtmospherePalette.volume, 1e-9));
    });
  });

  group('one player, no restarts', () {
    test('re-saving Settings or rapid screen changes never restart it', () async {
      final b = bed();
      await b.setEnabled(true);
      await Future.wait([
        b.setEnabled(true),
        b.setEnabled(true),
        b.setSign(ZodiacSignId.cancer),
        b.setEnabled(true),
      ]);
      expect(player.played, hasLength(1));
      expect(created, 1);
    });

    test('changing atmosphere replaces the loop on the same player', () async {
      final b = bed();
      await b.setEnabled(true);
      await b.setSign(ZodiacSignId.pisces);
      expect(player.played, hasLength(2));
      expect(player.played.last, contains('pisces'));
      expect(created, 1);
    });
  });

  group('background and interruptions', () {
    test('background pauses quietly; foreground resumes at the level', () async {
      final b = bed();
      await b.setEnabled(true);
      await b.pauseForBackground();
      expect(player.state, PlayerState.paused);
      expect(b.gain, 0);
      await b.resumeFromBackground();
      expect(player.state, PlayerState.playing);
      expect(b.gain, closeTo(OraclyAtmospherePalette.volume, 1e-9));
      expect(player.played, hasLength(1));
    });

    test('another app playing: stays ON but silent, starts once quiet', () async {
      busy.other = true;
      final b = bed();
      expect(await b.setEnabled(true), OraclyApplyOutcome.success);
      expect(b.enabled, isTrue);
      expect(b.held, isTrue);
      expect(player.played, isEmpty);

      busy.other = false;
      await wait();
      expect(b.held, isFalse);
      expect(player.state, PlayerState.playing);
    });

    test('a call pauses the bed; it returns after the call', () async {
      final b = bed();
      await b.setEnabled(true);
      busy.call = true;
      await wait();
      expect(b.held, isTrue);
      expect(player.state, isNot(PlayerState.playing));

      busy.call = false;
      await wait();
      expect(b.held, isFalse);
      expect(player.state, PlayerState.playing);
    });

    test('never resumes into a ringing call after foreground', () async {
      final b = bed();
      await b.setEnabled(true);
      await b.pauseForBackground();
      busy.call = true;
      await b.resumeFromBackground();
      expect(player.state, isNot(PlayerState.playing));
      expect(b.held, isTrue);
    });
  });

  group('broken or missing audio', () {
    test('a corrupt loop fails honestly and stays silent', () async {
      player.breakPlay = true;
      final b = bed();
      expect(await b.setEnabled(true), OraclyApplyOutcome.failure);
      expect(player.state, isNot(PlayerState.playing));
    });

    test('a deleted loop file is regenerated, not crashed on', () async {
      final b = bed();
      await b.setEnabled(true);
      final first = player.played.single;
      await b.setEnabled(false);
      File(first).deleteSync();
      expect(await b.setEnabled(true), OraclyApplyOutcome.success);
      expect(File(player.played.last).existsSync(), isTrue);
    });
  });

  group('seamless loop', () {
    List<int> pcm(Uint8List wav) {
      final data = ByteData.sublistView(wav, 44);
      return [
        for (var i = 0; i < data.lengthInBytes ~/ 2; i++)
          data.getInt16(i * 2, Endian.little),
      ];
    }

    double rms(List<int> s) =>
        sqrt(s.fold<double>(0, (a, v) => a + v * v) / s.length);

    for (final sign in ZodiacSignId.values) {
      test('${sign.name}: no seam dip and no jump at the loop point', () {
        final s = pcm(OraclyWavSynth.zodiacAtmosphere(sign));
        expect(s.length, (22050 * OraclyWavSynth.droneLoopSeconds).round());
        const edge = 1102; // 50 ms
        final whole = rms(s);
        expect(rms(s.sublist(0, edge)) / whole, greaterThan(0.6));
        expect(rms(s.sublist(s.length - edge)) / whole, greaterThan(0.6));
        // Wrap-around step is no larger than an ordinary step in the loop.
        var maxStep = 0;
        for (var i = 1; i < s.length; i++) {
          maxStep = max(maxStep, (s[i] - s[i - 1]).abs());
        }
        expect((s.first - s.last).abs(), lessThanOrEqualTo(maxStep));
      });
    }
  });
}
