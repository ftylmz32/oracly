/// Real tarot reading engine — story, not a card dictionary.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/insights/services/reflective_card_copy.dart';
import 'package:oracly_new/features/insights/services/reflective_intelligence.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/interpretation/models/reading_context.dart';
import 'package:oracly_new/features/tarot/reading/reading_hedge.dart';

ReadingCardContext _card({
  required int id,
  required String name,
  required int index,
  required String label,
  required String key,
  required bool reversed,
  required String upright,
  required String reversedMeaning,
  List<String> keywords = const ['odak'],
}) {
  return ReadingCardContext(
    cardId: id,
    cardName: name,
    positionIndex: index,
    positionLabel: label,
    positionKey: key,
    isReversed: reversed,
    uprightMeaning: upright,
    reversedMeaning: reversedMeaning,
    keywords: keywords,
  );
}

ReadingContext _jobQuestion({
  required String thirdName,
  required int thirdId,
  required String thirdMeaning,
}) {
  return ReadingContext(
    sessionId: 'engine_job',
    spreadType: TarotSpreadType.threeCard,
    spreadLabel: 'Üç Kart',
    deckId: 'classic',
    language: 'tr',
    readingDate: DateTime(2026, 8, 18),
    userQuestion: 'İşimi bırakmalı mıyım?',
    cards: [
      _card(
        id: 0,
        name: 'The Fool',
        index: 0,
        label: 'Geçmiş',
        key: 'past',
        reversed: false,
        upright: 'Yeni bir başlangıç.',
        reversedMeaning: 'Tereddüt.',
        keywords: ['başlangıç', 'hareket'],
      ),
      _card(
        id: 16,
        name: 'The Tower',
        index: 1,
        label: 'Şimdi',
        key: 'present',
        reversed: false,
        upright: 'Ani uyanış ve kırılma.',
        reversedMeaning: 'Ertelemeli yıkım.',
        keywords: ['kırılma', 'uyanış'],
      ),
      _card(
        id: thirdId,
        name: thirdName,
        index: 2,
        label: 'Gelecek',
        key: 'future',
        reversed: false,
        upright: thirdMeaning,
        reversedMeaning: 'Sönük yön.',
        keywords: ['yön'],
      ),
    ],
  );
}

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('reading is a story through slots, not a dictionary line', () {
    final result = ReflectiveIntelligence.synthesize(
      context: _jobQuestion(
        thirdName: 'The Star',
        thirdId: 17,
        thirdMeaning: 'Açık bir nefes ve onarım.',
      ),
      requestId: 'n',
    );
    final beat = ReflectiveCardCopy.block(
      _jobQuestion(
        thirdName: 'The Star',
        thirdId: 17,
        thirdMeaning: 'Açık bir nefes ve onarım.',
      ).cards[1],
    );
    expect(beat, contains('Şimdi'));
    expect(beat, contains('Düz'));
    expect(beat, isNot(contains('The Tower = ')));
    expect(beat.toLowerCase(), contains('ani uyanış'));
    expect(
      ReadingHedge.phrases.any(result.luckyEnergy.contains),
      isTrue,
    );
    expect(result.luckyEnergy.toLowerCase(), contains('fool'));
    expect(result.luckyEnergy.toLowerCase(), contains('tower'));
    expect(result.luckyEnergy.toLowerCase(), contains('star'));
    expect(result.luckyEnergy, contains('yan yana'));
    expect(result.luckyEnergy.toLowerCase(), contains('eğilim'));
    expect(result.luckyEnergy, isNot(contains('everything will collapse')));
    expect(result.luckyEnergy, isNot(contains('holding the old structure')));
  });

  test('the asked job question stays in the reading', () {
    final result = ReflectiveIntelligence.synthesize(
      context: _jobQuestion(
        thirdName: 'The Star',
        thirdId: 17,
        thirdMeaning: 'Açık bir nefes ve onarım.',
      ),
      requestId: 'q',
    );
    expect(result.summary, contains('İşimi bırakmalı mıyım?'));
    expect(result.luckyEnergy, contains('İşimi bırakmalı mıyım?'));
    expect(result.health, contains('İşimi bırakmalı mıyım?'));
    expect(result.closingMessage, contains('Bu açılımın sana bıraktığı yön'));
    expect(result.warnings, contains('İşimi bırakmalı mıyım?'));
    expect(result.warnings, contains('?'));
  });

  test('different cards write different stories — no canned example', () {
    final star = ReflectiveIntelligence.synthesize(
      context: _jobQuestion(
        thirdName: 'The Star',
        thirdId: 17,
        thirdMeaning: 'Açık bir nefes ve onarım.',
      ),
      requestId: 'a',
    );
    final world = ReflectiveIntelligence.synthesize(
      context: _jobQuestion(
        thirdName: 'The World',
        thirdId: 21,
        thirdMeaning: 'Bir döngünün tamamlanması.',
      ),
      requestId: 'b',
    );
    expect(star.luckyEnergy, isNot(equals(world.luckyEnergy)));
    expect(star.luckyEnergy.toLowerCase(), contains('star'));
    expect(world.luckyEnergy.toLowerCase(), contains('world'));
    expect(world.luckyEnergy.toLowerCase(), isNot(contains('star')));
  });

  test('no deterministic prophecy language', () {
    final result = ReflectiveIntelligence.synthesize(
      context: _jobQuestion(
        thirdName: 'The Star',
        thirdId: 17,
        thirdMeaning: 'Açık bir nefes ve onarım.',
      ),
      requestId: 'p',
    );
    final blob = '${result.summary} ${result.luckyEnergy} '
        '${result.health} ${result.dailyFocus} ${result.closingMessage}';
    expect(blob.toLowerCase(), isNot(contains('kesin olacak')));
    expect(blob.toLowerCase(), isNot(contains('mutlaka')));
    expect(blob.toLowerCase(), isNot(contains('kesinlikle başına gelecek')));
    expect(ReflectiveIntelligence.containsForbiddenTone(blob), isFalse);
  });
}
