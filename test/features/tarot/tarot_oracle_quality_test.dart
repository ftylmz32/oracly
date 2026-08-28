/// Human-oracle quality gate — 30 readings, TR / EN / RU.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/reading/human_reader.dart';
import 'package:oracly_new/features/insights/models/journey_personalization_hints.dart';
import 'package:oracly_new/features/insights/services/reflective_intelligence.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/interpretation/models/reading_context.dart';
import 'package:oracly_new/features/tarot/reading/reading_length.dart';

ReadingCardContext _card({
  required int id,
  required String name,
  required int index,
  required String label,
  required String key,
  bool reversed = false,
  required String upright,
  String reversedMeaning = 'Ters.',
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

ReadingContext _ctx({
  required String lang,
  required String question,
  required List<ReadingCardContext> cards,
  JourneyPersonalizationHints? hints,
  int seed = 0,
}) {
  return ReadingContext(
    sessionId: 'oracle_${question.hashCode}',
    spreadType: cards.length == 1
        ? TarotSpreadType.single
        : cards.length <= 3
            ? TarotSpreadType.threeCard
            : TarotSpreadType.sevenCard,
    spreadLabel: 'Spread',
    deckId: 'classic',
    language: lang,
    readingDate: DateTime(2026, 8, 19),
    userQuestion: question,
    readingTheme: _theme(question),
    shuffleSeed: seed,
    journeyHints: hints,
    cards: cards,
  );
}

String? _theme(String q) {
  final lower = q.toLowerCase();
  if (lower.contains('ilişki') ||
      lower.contains('relationship') ||
      lower.contains('отношен') ||
      lower.contains('intention') ||
      lower.contains('niyet')) {
    return 'love';
  }
  if (lower.contains('iş') ||
      lower.contains('job') ||
      lower.contains('work') ||
      lower.contains('работ')) {
    return 'career';
  }
  return 'general';
}

String _narrative(ReadingContext ctx) {
  final r = ReflectiveIntelligence.synthesize(
    context: ctx,
    requestId: 'q',
  );
  return r.luckyEnergy;
}

void _assertOracle(String text, {required String question}) {
  expect(text.trim().isNotEmpty, isTrue);
  expect(ReflectiveIntelligence.containsForbiddenTone(text), isFalse);
  expect(HumanReader.looksGeneric(text), isFalse);
  expect(text.toLowerCase(), isNot(contains(' = ')));
  expect(text.toLowerCase(), isNot(contains('the tower represents')));
  expect(question.trim().isNotEmpty, isTrue);
}

List<ReadingCardContext> _three({
  required int a,
  required String aName,
  required int b,
  required String bName,
  required int c,
  required String cName,
  required String l0,
  required String l1,
  required String l2,
  required String k0,
  required String k1,
  required String k2,
}) {
  return [
    _card(id: a, name: aName, index: 0, label: l0, key: k0, upright: 'A.'),
    _card(id: b, name: bName, index: 1, label: l1, key: k1, upright: 'B.'),
    _card(id: c, name: cName, index: 2, label: l2, key: k2, upright: 'C.'),
  ];
}

void main() {
  tearDown(() => OraclyL10n.bind('tr'));

  test('30 oracle readings stay specific across TR EN RU', () {
    final relationship = [
      ('tr', 'Bu ilişki nereye gidiyor?', _three(a: 6, aName: 'The Lovers', b: 18, bName: 'The Moon', c: 2, cName: 'The High Priestess', l0: 'Geçmiş', l1: 'Şimdi', l2: 'Gelecek', k0: 'past', k1: 'present', k2: 'direction'), null),
      ('en', 'What is this person\'s intention?', _three(a: 7, aName: 'The Chariot', b: 15, bName: 'The Devil', c: 19, cName: 'The Sun', l0: 'Past', l1: 'Present', l2: 'Future', k0: 'past', k1: 'present', k2: 'direction'), null),
      ('ru', 'Куда идут наши отношения?', _three(a: 3, aName: 'The Empress', b: 16, bName: 'The Tower', c: 17, cName: 'The Star', l0: 'Прошлое', l1: 'Сейчас', l2: 'Будущее', k0: 'past', k1: 'present', k2: 'direction'), null),
      ('tr', 'Partnerim beni hâlâ seviyor mu?', _three(a: 19, aName: 'The Sun', b: 18, bName: 'The Moon', c: 6, cName: 'The Lovers', l0: 'Geçmiş', l1: 'Şimdi', l2: 'Gelecek', k0: 'past', k1: 'present', k2: 'direction'), null),
      ('en', 'Where is this relationship going?', _three(a: 2, aName: 'The High Priestess', b: 3, bName: 'The Empress', c: 14, cName: 'Temperance', l0: 'Past', l1: 'Present', l2: 'Direction', k0: 'past', k1: 'present', k2: 'direction'), null),
      ('ru', 'Какие у него намерения?', _three(a: 15, aName: 'The Devil', b: 6, bName: 'The Lovers', c: 11, cName: 'Justice', l0: 'Прошлое', l1: 'Сейчас', l2: 'Путь', k0: 'past', k1: 'present', k2: 'direction'), null),
      ('tr', 'Bu bağ bana mı ait?', _three(a: 5, aName: 'The Hierophant', b: 18, bName: 'The Moon', c: 17, cName: 'The Star', l0: 'Geçmiş', l1: 'Şimdi', l2: 'Gelecek', k0: 'past', k1: 'present', k2: 'direction'), null),
      ('en', 'Should I trust them again?', _three(a: 16, aName: 'The Tower', b: 17, bName: 'The Star', c: 19, cName: 'The Sun', l0: 'Past', l1: 'Present', l2: 'Direction', k0: 'past', k1: 'present', k2: 'direction'), null),
      ('ru', 'Стоит ли мне остаться в этих отношениях?', _three(a: 13, aName: 'Death', b: 10, bName: 'Wheel of Fortune', c: 21, cName: 'The World', l0: 'Прошлое', l1: 'Сейчас', l2: 'Путь', k0: 'past', k1: 'present', k2: 'direction'), null),
      ('tr', 'Onun niyeti ne?', _three(a: 1, aName: 'The Magician', b: 7, bName: 'The Chariot', c: 2, cName: 'The High Priestess', l0: 'Geçmiş', l1: 'Şimdi', l2: 'Gelecek', k0: 'past', k1: 'present', k2: 'direction'), null),
    ];

    final career = [
      ('tr', 'İşimi bırakmalı mıyım?', _three(a: 0, aName: 'The Fool', b: 16, bName: 'The Tower', c: 4, cName: 'The Emperor', l0: 'Geçmiş', l1: 'Engel', l2: 'Gelecek', k0: 'past', k1: 'obstacle', k2: 'direction'), const JourneyPersonalizationHints(recurringThemeLabels: ['Değişim', 'Kariyer'], priorReadingCount: 3)),
      ('en', 'Should I leave this job?', _three(a: 8, aName: 'Strength', b: 10, bName: 'Wheel of Fortune', c: 21, cName: 'The World', l0: 'Past', l1: 'Present', l2: 'Direction', k0: 'past', k1: 'present', k2: 'direction'), null),
      ('ru', 'Стоит ли мне уйти с работы?', _three(a: 1, aName: 'The Magician', b: 13, bName: 'Death', c: 11, cName: 'Justice', l0: 'Прошлое', l1: 'Препятствие', l2: 'Путь', k0: 'past', k1: 'obstacle', k2: 'direction'), null),
      ('tr', 'Terfi mi istemeliyim?', _three(a: 4, aName: 'The Emperor', b: 1, bName: 'The Magician', c: 7, cName: 'The Chariot', l0: 'Geçmiş', l1: 'Şimdi', l2: 'Gelecek', k0: 'past', k1: 'present', k2: 'direction'), null),
      ('en', 'Is it time to change careers?', _three(a: 13, aName: 'Death', b: 0, bName: 'The Fool', c: 21, cName: 'The World', l0: 'Past', l1: 'Present', l2: 'Direction', k0: 'past', k1: 'present', k2: 'direction'), null),
      ('ru', 'Пора ли менять работу?', _three(a: 16, aName: 'The Tower', b: 4, bName: 'The Emperor', c: 8, cName: 'Strength', l0: 'Прошлое', l1: 'Сейчас', l2: 'Путь', k0: 'past', k1: 'present', k2: 'direction'), null),
      ('tr', 'Bu teklifi kabul etmeli miyim?', _three(a: 11, aName: 'Justice', b: 15, bName: 'The Devil', c: 19, cName: 'The Sun', l0: 'Geçmiş', l1: 'Engel', l2: 'Gelecek', k0: 'past', k1: 'obstacle', k2: 'direction'), null),
      ('en', 'Should I ask for a raise?', _three(a: 4, aName: 'The Emperor', b: 8, bName: 'Strength', c: 10, cName: 'Wheel of Fortune', l0: 'Past', l1: 'Present', l2: 'Direction', k0: 'past', k1: 'present', k2: 'direction'), null),
      ('ru', 'Стоит ли принять это предложение?', _three(a: 5, aName: 'The Hierophant', b: 16, bName: 'The Tower', c: 17, cName: 'The Star', l0: 'Прошлое', l1: 'Препятствие', l2: 'Путь', k0: 'past', k1: 'obstacle', k2: 'direction'), null),
      ('tr', 'Patronumla konuşmalı mıyım?', _three(a: 9, aName: 'The Hermit', b: 7, bName: 'The Chariot', c: 14, cName: 'Temperance', l0: 'Geçmiş', l1: 'Şimdi', l2: 'Gelecek', k0: 'past', k1: 'present', k2: 'direction'), null),
    ];

    final general = [
      ('tr', 'Önümdeki dönemde neye dikkat etmeliyim?', [_card(id: 9, name: 'The Hermit', index: 0, label: 'Şimdi', key: 'present', upright: 'İçe dönüş.')], null),
      ('en', 'What should I watch for in the coming weeks?', _three(a: 12, aName: 'The Hanged Man', b: 5, bName: 'The Hierophant', c: 14, cName: 'Temperance', l0: 'Past', l1: 'Present', l2: 'Direction', k0: 'past', k1: 'present', k2: 'direction'), null),
      ('ru', 'На что обратить внимание в ближайшее время?', [_card(id: 20, name: 'Judgement', index: 0, label: 'Сейчас', key: 'present', upright: 'Пробуждение.'), _card(id: 50, name: 'Ten of Swords', index: 1, label: 'Препятствие', key: 'obstacle', upright: 'Тяжёлая точка.', keywords: ['ten of swords'])], null),
      ('tr', 'Bu dönemde nasıl ilerlemeliyim?', _three(a: 10, aName: 'Wheel of Fortune', b: 9, bName: 'The Hermit', c: 19, cName: 'The Sun', l0: 'Geçmiş', l1: 'Şimdi', l2: 'Gelecek', k0: 'past', k1: 'present', k2: 'direction'), null),
      ('en', 'What guidance do I need right now?', _three(a: 17, aName: 'The Star', b: 18, bName: 'The Moon', c: 19, cName: 'The Sun', l0: 'Past', l1: 'Present', l2: 'Direction', k0: 'past', k1: 'present', k2: 'direction'), null),
      ('ru', 'Куда направить внимание сейчас?', _three(a: 2, aName: 'The High Priestess', b: 20, bName: 'Judgement', c: 21, cName: 'The World', l0: 'Прошлое', l1: 'Сейчас', l2: 'Путь', k0: 'past', k1: 'present', k2: 'direction'), null),
      ('tr', 'Önümde ne var?', _three(a: 0, aName: 'The Fool', b: 10, bName: 'Wheel of Fortune', c: 21, cName: 'The World', l0: 'Geçmiş', l1: 'Şimdi', l2: 'Gelecek', k0: 'past', k1: 'present', k2: 'direction'), null),
      ('en', 'What is opening for me ahead?', _three(a: 3, aName: 'The Empress', b: 13, bName: 'Death', c: 0, cName: 'The Fool', l0: 'Past', l1: 'Present', l2: 'Direction', k0: 'past', k1: 'present', k2: 'direction'), null),
      ('ru', 'Что ждёт меня впереди?', _three(a: 18, aName: 'The Moon', b: 17, bName: 'The Star', c: 19, cName: 'The Sun', l0: 'Прошлое', l1: 'Сейчас', l2: 'Путь', k0: 'past', k1: 'present', k2: 'direction'), null),
      ('tr', 'Bu hafta kendime nasıl bakmalıyım?', [_card(id: 14, name: 'Temperance', index: 0, label: 'Şimdi', key: 'present', upright: 'Denge.')], null),
    ];

    final all = [...relationship, ...career, ...general];
    expect(all.length, 30);

    for (var i = 0; i < all.length; i++) {
      final row = all[i];
      final lang = row.$1;
      final question = row.$2;
      final cards = row.$3;
      final hints = row.$4;
      OraclyL10n.bind(lang);
      final text = _narrative(
        _ctx(
          lang: lang,
          question: question,
          cards: cards,
          hints: hints,
          seed: i,
        ),
      );
      _assertOracle(text, question: question);
      expect(
        ReadingLength.sentences(text).length,
        lessThanOrEqualTo(ReadingLength.narrativeMax(cards.length) + 1),
      );
      if (cards.any((c) => c.positionKey == 'direction' || c.positionLabel.toLowerCase().contains('yön') || c.positionLabel.toLowerCase().contains('direction') || c.positionLabel.toLowerCase().contains('путь'))) {
        final marker = lang == 'tr'
            ? 'eğilim'
            : lang == 'en'
                ? 'trend'
                : 'тенденция';
        expect(text.toLowerCase(), contains(marker));
      }
    }
  });

  test('tower in obstacle is contextual, not prophecy', () {
    OraclyL10n.bind('tr');
    final text = _narrative(
      _ctx(
        lang: 'tr',
        question: 'İşimi bırakmalı mıyım?',
        cards: [
          _card(
            id: 16,
            name: 'The Tower',
            index: 0,
            label: 'Engel',
            key: 'obstacle',
            upright: 'Yapının sarsılması.',
          ),
        ],
        seed: 1,
      ),
    );
    expect(text.toLowerCase(), isNot(contains('kesin olacak')));
    expect(text.toLowerCase(), contains('engel'));
  });

  test('journey preface only with real history', () {
    const hints = JourneyPersonalizationHints(
      recurringThemeLabels: ['Aşk'],
      priorReadingCount: 4,
    );
    OraclyL10n.bind('tr');
    expect(hints.observationalPreface(), isNotNull);
    OraclyL10n.bind('en');
    expect(hints.observationalPreface(), contains('love'));
    const empty = JourneyPersonalizationHints(priorReadingCount: 1);
    expect(empty.observationalPreface(), isNull);
  });
}
