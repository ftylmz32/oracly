import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/audio/oracly_ambient_bed.dart';
import 'package:oracly_new/core/experience/domain/models/experience_context.dart';
import 'package:oracly_new/core/experience/domain/models/greeting_context.dart';
import 'package:oracly_new/core/experience/domain/models/journey_context.dart';
import 'package:oracly_new/core/experience/domain/models/recommendation_context.dart';
import 'package:oracly_new/core/experience/domain/models/reflection_context.dart';
import 'package:oracly_new/core/personality/living_greeting_copy.dart';
import 'package:oracly_new/core/runtime/oracly_apply_outcome.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';

class _FakePlayback implements OraclyAmbientPlayback {
  _FakePlayback({this.provePlaying = true, this.playDelay = Duration.zero});
  final bool provePlaying;
  final Duration playDelay;
  PlayerState _state = PlayerState.stopped;
  int playCount = 0;
  int stopCount = 0;
  int pauseCount = 0;
  int resumeCount = 0;
  int disposeCount = 0;
  final paths = <String>[];

  @override
  PlayerState get state => _state;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> playFile(String path) async {
    paths.add(path);
    playCount++;
    if (playDelay > Duration.zero) await Future<void>.delayed(playDelay);
    if (provePlaying) _state = PlayerState.playing;
  }

  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> stop() async {
    stopCount++;
    _state = PlayerState.stopped;
  }

  @override
  Future<void> pause() async {
    pauseCount++;
    _state = PlayerState.paused;
  }

  @override
  Future<void> resume() async {
    resumeCount++;
    if (provePlaying) _state = PlayerState.playing;
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
  }
}

ExperienceContext _experience(GreetingTone tone, DateTime at) =>
    ExperienceContext(
      generatedAt: at,
      schemaVersion: ExperienceContext.currentSchemaVersion,
      greeting: GreetingContext(
        tone: tone,
        styleKey: 'test',
        personalizeWithJourney: false,
      ),
      reflection: const ReflectionContext(
        style: ReflectionStyle.gentle,
        surfacePersonalInsights: false,
        preferShortForm: false,
      ),
      journey: const JourneyContext(
        hasJourneyMemory: false,
        highlightTodaysRitual: false,
        ritualCompletedToday: false,
        totalReadings: 0,
        hasRecurringPatterns: false,
      ),
      recommendations: const RecommendationContext(
        primaryHighlight: ExperienceHighlight.none,
        secondaryHighlights: [],
        premium: PremiumRelevance(isRelevant: false),
        aiAvailable: true,
        featureFlags: {},
      ),
    );

void main() {
  test('returning greeting uses first name and preserves daily rotation', () {
    final returning = _experience(GreetingTone.returning, DateTime(2026, 9, 9));
    final one = LivingGreetingCopy.greetingLabel(
      experience: returning,
      asOf: DateTime(2026, 9, 9),
      userName: 'Fatih Taha',
    );
    final two = LivingGreetingCopy.greetingLabel(
      experience: returning,
      asOf: DateTime(2026, 9, 10),
      userName: 'Fatih Taha',
    );
    expect(one, contains('Fatih'));
    expect(one, isNot(contains('Taha')));
    expect(one, isNot(two));
  });

  test('invalid returning name stays bare and new journey stays unchanged', () {
    final at = DateTime(2026, 9, 9);
    final returning = _experience(GreetingTone.returning, at);
    for (final name in <String?>[null, '', 'user', 'guest', 'undefined']) {
      final label = LivingGreetingCopy.greetingLabel(
        experience: returning,
        asOf: at,
        userName: name,
      );
      expect(label.toLowerCase(), isNot(contains('user')));
      expect(label.toLowerCase(), isNot(contains('guest')));
      expect(label.toLowerCase(), isNot(contains('undefined')));
      expect(label, isNot(contains(',')));
    }
    final fresh = _experience(GreetingTone.newJourney, at);
    expect(
      LivingGreetingCopy.greetingLabel(
        experience: fresh,
        asOf: at,
        userName: 'Fatih Taha',
      ),
      LivingGreetingCopy.greetingLabel(
        experience: fresh,
        asOf: at,
        userName: null,
      ),
    );
  });

  test('Tarot result path contains one canonical retrieval', () {
    final source = File(
      'lib/features/tarot/presentation/screens/reading_screen.dart',
    ).readAsStringSync();
    expect(RegExp(r'\.forInterpretation\(').allMatches(source), hasLength(1));
  });

  test(
    'ambient proves playing, stops, pauses, resumes and changes source',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'oracly_ambient_test_',
      );
      final fake = _FakePlayback();
      final bed = OraclyAmbientBed(
        playbackFactory: () => fake,
        tempDirectory: () async => temp,
        playingTimeout: const Duration(milliseconds: 100),
      );
      expect(await bed.setEnabled(true), OraclyApplyOutcome.success);
      expect(fake.state, PlayerState.playing);
      final first = fake.paths.single;
      await bed.pauseForBackground();
      expect(fake.state, PlayerState.paused);
      await bed.resumeFromBackground();
      expect(fake.state, PlayerState.playing);
      expect(await bed.setSign(ZodiacSignId.aries), OraclyApplyOutcome.success);
      expect(fake.paths.last, isNot(first));
      expect(await bed.setEnabled(false), OraclyApplyOutcome.success);
      expect(fake.state, PlayerState.stopped);
      await bed.dispose();
      expect(fake.disposeCount, 1);
      expect(await temp.exists(), isFalse);
    },
  );

  test('ambient unproven start is a failure', () async {
    final temp = await Directory.systemTemp.createTemp('oracly_ambient_test_');
    final fake = _FakePlayback(provePlaying: false);
    final bed = OraclyAmbientBed(
      playbackFactory: () => fake,
      tempDirectory: () async => temp,
      playingTimeout: const Duration(milliseconds: 30),
    );
    expect(await bed.setEnabled(true), OraclyApplyOutcome.failure);
    await bed.dispose();
  });

  test('ambient rapid OFF, sign change, background and dispose cannot resurrect old work', () async {
    final temp = await Directory.systemTemp.createTemp('oracly_ambient_race_');
    final fake = _FakePlayback(playDelay: const Duration(milliseconds: 30));
    final bed = OraclyAmbientBed(
      playbackFactory: () => fake,
      tempDirectory: () async => temp,
      playingTimeout: const Duration(milliseconds: 120),
    );

    final enabling = bed.setEnabled(true);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final disabling = bed.setEnabled(false);
    await Future.wait([enabling, disabling]);
    expect(fake.state, PlayerState.stopped);
    expect(bed.enabled, isFalse);

    expect(await bed.setEnabled(true), OraclyApplyOutcome.success);
    final aries = bed.setSign(ZodiacSignId.aries);
    final leo = bed.setSign(ZodiacSignId.leo);
    await Future.wait([aries, leo]);
    expect(fake.paths.last, contains('zodiac_leo.wav'));

    final refresh = bed.refresh();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await bed.pauseForBackground();
    await refresh;
    expect(fake.state, PlayerState.paused);

    final resume = bed.resumeFromBackground();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await bed.dispose();
    await resume;
    expect(fake.state, isNot(PlayerState.playing));
    expect(await temp.exists(), isFalse);
  });
}
