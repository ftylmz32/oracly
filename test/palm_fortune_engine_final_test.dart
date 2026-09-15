/// Final palm fortune engine — 10 provider-backed hands, one spoken reading.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/openai/palm_prompt_style.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/services/palm_fortune_composer.dart';
import 'package:oracly_new/features/palm/services/palm_fortune_narration.dart';

import 'palm_fortune_engine_hands.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test(
    'BATCH 3A.2: ten provider-backed palms with raw vision-dump/short '
    'overalls all fail composition — there is no client textbook-card '
    'engine left to speak for the hand',
    () {
      for (final hand in palmFortuneEngineHands) {
        expect(_compose(hand), isNull, reason: hand.overall);
      }
    },
  );

  test(
    'BATCH 3A.2: a vision dump of card-equations is a failure, never '
    'rewritten into a reading',
    () {
      expect(_compose(palmFortuneEngineHands.first), isNull);
      final empty = PalmFortuneComposer.compose(
        PalmReading(
          id: 'blank',
          createdAt: DateTime(2026, 8, 18),
          hand: PalmHand.right,
          overall: 'Kalp = aşk. Zihin = zeka.',
        ),
      );
      expect(empty, isNull);
    },
  );

  test(
    'a valid backend overall still narrates cleanly through PalmFortuneNarration',
    () {
      final reading = PalmFortuneComposer.compose(
        PalmReading(
          id: 'valid',
          createdAt: DateTime(2026, 8, 18),
          hand: PalmHand.right,
          overall:
              'Bu avuçta kararlar genelde sessizce, uzun bir düşünme '
              'süresinin ardından alınıyor gibi görünüyor; hızlı '
              'davranmak yerine oturup tartmayı tercih eden bir yapı bu.',
          heartLine: 'Kalp çizgisi belirgin.',
        ),
      )!;
      expect(reading.heartLine, contains('belirgin'));
      final spoken = PalmFortuneNarration.body(reading);
      expect(spoken, contains(reading.overall));
      expect(spoken, isNot(contains('Kalp = aşk')));
    },
  );

  test('prompt asks for a grounded palm story', () {
    expect(PalmPromptStyle.system, contains('Tek hikâye'));
    expect(PalmPromptStyle.system, contains('kırık'));
    expect(PalmPromptStyle.userLead, contains('Kalp = aşk yazma'));
  });
}

PalmReading? _compose(PalmEngineHand hand) =>
    PalmFortuneComposer.compose(hand.toReading(), themes: hand.themes);
