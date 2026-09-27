/// Dream Phase 2 — local readings speak the operation language.
/// The development local fallback composes on-device text only, and EN / RU
/// sections never carry Turkish scaffolding or Turkish labels. (Phase 4B: a
/// configured provider reply is never completed with this text.)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/dream/models/dream_emotion.dart';
import 'package:oracly_new/features/dream/models/dream_insight.dart';
import 'package:oracly_new/features/dream/models/dream_provenance.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';
import 'package:oracly_new/features/dream/services/dream_reading_provenance.dart';

import '../../support/dream_test_owner.dart';
import 'dream_honesty_fakes.dart';
import 'dream_phase2_support.dart';

const _enTold =
    'Every evening I walked with my mother to an old house, and a door opened by the sea.';
const _ruTold =
    'Мне снилось, что мы с мамой шли к старому дому, и у моря открылась дверь.';

const _fearful = [DreamEmotion(id: DreamEmotionId.fearful)];

/// Development build: no provider, explicit local fallback.
class _DevLocalAi extends LiveDreamAiStub {
  const _DevLocalAi();

  @override
  bool get isConfigured => false;

  @override
  bool get allowsLocalFallback => true;
}

Future<List<DreamInsight>> _localReading(String told, String app) async {
  OraclyL10n.bind(app);
  final result = await DreamExperienceService(
    repository: MemDreamRepository(),
    owner: testDreamOwner(),
    ai: const _DevLocalAi(),
  ).analyze(narrative: told, selectedEmotions: _fearful);
  expect(DreamReadingProvenance.of(result.dream), DreamProvenance.localOnly);
  expect(
    result.dream.insights.map((i) => i.source).toSet(),
    {DreamInsightSource.local},
  );
  return result.dream.insights;
}

String _bodies(List<DreamInsight> insights) =>
    insights.map((i) => i.body).join('\n');

/// Turkish glue, templates and labels the dreamer never wrote.
const _turkishScaffold = [
  'içinde',
  ' ve ',
  'bu sahne',
  'Korkulu',
  'Kapı',
  'Deniz',
  'Anne',
  'Rüya',
];

void _expectSentences(List<DreamInsight> insights) {
  for (final i in insights.where((i) => i.kind != DreamInsightKind.symbols)) {
    expect(i.body[0], i.body[0].toUpperCase(), reason: i.kind.name);
  }
}

void _expectNoTurkish(String text) {
  for (final leak in _turkishScaffold) {
    expect(text, isNot(contains(leak)), reason: leak);
  }
  expect(text, isNot(matches(RegExp(r'\bEv\b'))));
  expect(text, isNot(matches(RegExp('[çğışöüİÇĞŞÖÜ]'))));
}

void main() {
  tearDown(() => OraclyL10n.bind('tr'));

  test('LOCAL TR: Turkish scaffolding and labels are unchanged', () async {
    final insights = await _localReading(phase2Narrative, 'en');
    expect(insights, isNotEmpty);
    final text = _bodies(insights);
    expect(text.toLowerCase(), contains('korkulu'));
    expect(text, matches(RegExp('[çğışöüİ]')));
  });

  test('LOCAL EN: English sections, no Turkish scaffold leak', () async {
    final insights = await _localReading(_enTold, 'tr');
    expect(insights, isNotEmpty);
    final text = _bodies(insights);
    _expectNoTurkish(text);
    _expectSentences(insights);
    expect(text.toLowerCase(), contains('fearful'));
  });

  test('LOCAL EN: "every" never yields the Turkish place "Ev"', () async {
    final text = _bodies(
      await _localReading('Every evening a door opened slowly.', 'en'),
    );
    expect(text, isNot(matches(RegExp(r'\bEv\b'))));
    expect(text.toLowerCase(), contains('door'));
  });

  test('LOCAL RU: Russian sections, no Turkish scaffold leak', () async {
    final insights = await _localReading(_ruTold, 'en');
    expect(insights, isNotEmpty);
    final text = _bodies(insights);
    _expectNoTurkish(text);
    _expectSentences(insights);
    expect(text, contains('испуганный'));
    expect(text, matches(RegExp('[а-яё]')));
  });
}
