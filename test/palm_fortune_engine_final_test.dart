/// Final palm fortune engine — 10 provider-backed hands, one spoken reading.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/fortune_voice.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/reading/human_reader.dart';
import 'package:oracly_new/features/ai/production/openai/palm_prompt_style.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/services/palm_fortune_composer.dart';
import 'package:oracly_new/features/palm/services/palm_fortune_narration.dart';

import 'palm_fortune_engine_hands.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('ten provider-backed palms read as one hand, not textbook cards', () {
    final readings = [
      for (final hand in palmFortuneEngineHands) _compose(hand),
    ];
    expect(readings, hasLength(10));
    final openings = <String>{};
    for (var i = 0; i < readings.length; i++) {
      final reading = readings[i];
      final text = reading.overall;
      final spoken = PalmFortuneNarration.body(reading);
      final lower = spoken.toLowerCase();
      final spec = palmFortuneEngineHands[i];
      expect(text.trim(), isNotEmpty);
      expect(text.contains('='), isFalse, reason: text);
      expect(lower, isNot(contains('kalp = ')));
      expect(lower, isNot(contains('temsil eder')));
      expect(HumanReader.looksGeneric(text), isFalse, reason: text);
      expect(FortuneVoice.looksRobotic(text), isFalse, reason: text);
      expect(FortuneVoice.claimsCertainty(text), isFalse, reason: text);
      expect(FortuneVoice.claimsMedical(spoken), isFalse, reason: spoken);
      expect(text.contains('...'), isFalse, reason: text);
      expect(
        text.split(RegExp(r'[.!?]+')).where((p) => p.trim().isNotEmpty).length,
        greaterThanOrEqualTo(2),
        reason: text,
      );
      openings.add(text.split('.').first.trim());
      for (final word in spec.mustContain) {
        expect(lower, contains(word), reason: spoken);
      }
      for (final word in spec.mustNot) {
        expect(lower, isNot(contains(word)), reason: spoken);
      }
      final lines = [
        spec.heart,
        spec.head,
        spec.life,
        spec.fate,
      ].where((l) => l.trim().isNotEmpty).length;
      if (lines >= 2) {
        expect(
          lower.contains('birlikte') ||
              lower.contains('yanındaki') ||
              lower.contains('yanında') ||
              lower.contains('yan yana'),
          isTrue,
          reason: text,
        );
      }
    }
    expect(openings.length, greaterThanOrEqualTo(5));
    expect(
      readings.map((r) => r.overall).toSet().length,
      greaterThanOrEqualTo(8),
    );
  });

  test('vision dump of card-equations is rewritten and missing stays missing', () {
    final first = _compose(palmFortuneEngineHands.first);
    expect(first.overall.toLowerCase(), contains('belirgin'));
    expect(first.heartLine, contains('belirgin'));
    expect(first.headLine, contains('net'));
    expect(first.lifeLine, isEmpty);
    expect(first.fateLine, isEmpty);
    expect(PalmFortuneNarration.body(first), contains(first.overall));
    expect(PalmFortuneNarration.body(first), isNot(contains('Kalp = aşk')));
    final empty = PalmFortuneComposer.compose(
      PalmReading(
        id: 'blank',
        createdAt: DateTime(2026, 8, 18),
        hand: PalmHand.right,
        overall: 'Kalp = aşk. Zihin = zeka.',
      ),
    );
    expect(empty.heartLine, isEmpty);
    expect(empty.headLine, isEmpty);
    expect(empty.overall.toLowerCase(), isNot(contains('kalp çizgisi')));
    expect(empty.overall.toLowerCase(), contains('net değil'));
  });

  test('career theme does not attach without a real path or mind line', () {
    final composed = PalmFortuneComposer.compose(
      PalmReading(
        id: 'no-path',
        createdAt: DateTime(2026, 8, 18),
        hand: PalmHand.right,
        overall: 'Avuç sakin duruyor.',
        heartLine: 'Kalp çizgisi belirgin.',
      ),
      themes: const ['kariyer'],
    );
    expect(composed.overall.toLowerCase(), contains('belirgin'));
    expect(composed.overall.toLowerCase(), isNot(contains('kariyer')));
    expect(composed.fateLine, isEmpty);
  });

  test('prompt asks for a grounded palm story', () {
    expect(PalmPromptStyle.system, contains('Tek hikâye'));
    expect(PalmPromptStyle.system, contains('kırık'));
    expect(PalmPromptStyle.userLead, contains('Kalp = aşk yazma'));
  });
}

PalmReading _compose(PalmEngineHand hand) =>
    PalmFortuneComposer.compose(hand.toReading(), themes: hand.themes);
