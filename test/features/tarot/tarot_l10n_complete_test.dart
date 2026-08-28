/// Tarot localization complete — TR / EN / RU, no mixed fallback.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/gems/copy/gems_copy.dart';
import 'package:oracly_new/features/insights/services/reflective_intelligence.dart';
import 'package:oracly_new/features/prompt_engine/models/prompt_template.dart';
import 'package:oracly_new/features/prompt_engine/templates/catalogues/prompt_template_catalogue.dart';
import 'package:oracly_new/features/tarot/copy/tarot_l10n.dart';
import 'package:oracly_new/features/tarot/copy/tarot_polish_copy.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/interpretation/models/reading_context.dart';
import 'package:oracly_new/features/tarot/interpretation/services/interpretation_prompt_adapter.dart';
import 'package:oracly_new/features/tarot/reading/reading_hedge.dart';

ReadingCardContext _card(String language) {
  return ReadingCardContext(
    cardId: 0,
    cardName: TarotL10n.cardName(0, language: language),
    positionIndex: 0,
    positionLabel: OraclyL10n.t('tarot.pos.present', languageCode: language),
    positionKey: 'present',
    isReversed: false,
    uprightMeaning: 'A new beginning.',
    reversedMeaning: 'Hesitation.',
    keywords: const ['start'],
  );
}

ReadingContext _ctx(String language) {
  return ReadingContext(
    sessionId: 'loc',
    spreadType: TarotSpreadType.threeCard,
    spreadLabel: TarotL10n.spread(TarotSpreadType.threeCard),
    deckId: 'classic',
    language: language,
    readingDate: DateTime(2026, 8, 19),
    userQuestion: 'Should I stay?',
    cards: [_card(language)],
  );
}

void main() {
  tearDown(() => OraclyL10n.bind('tr'));

  test('TR chrome, names, gems, premium stay Turkish', () {
    OraclyL10n.bind('tr');
    expect(TarotL10n.cardName(0), 'Deli');
    expect(TarotL10n.cardName(22), contains('Kupa'));
    expect(TarotL10n.spread(TarotSpreadType.single), 'Tek Kart');
    expect(TarotL10n.position('past'), 'Geçmiş');
    expect(TarotPolishCopy.retry, 'TEKRAR DENE');
    expect(TarotL10n.deckName, 'Klasik Tarot');
    expect(GemsCopy.gemUnit, 'Mücevher');
    expect(PremiumCopy.exclusiveLabel, 'Premium');
    expect(TarotSpreadType.threeCard.label, 'Üç Kart');
  });

  test('EN chrome is English, not leftover Turkish', () {
    OraclyL10n.bind('en');
    expect(TarotL10n.cardName(0), 'The Fool');
    expect(TarotL10n.cardName(22), 'Ace of Cups');
    expect(TarotL10n.spread(TarotSpreadType.single), 'One Card');
    expect(TarotL10n.position('past'), 'Past');
    expect(TarotL10n.position('direction'), 'Direction');
    expect(TarotL10n.position('future'), 'Future');
    expect(TarotPolishCopy.retry, isNot(contains('TEKRAR')));
    expect(TarotL10n.deckName, 'Classic Tarot');
    expect(TarotL10n.fallbackLoad, isNot(contains('Yorum')));
    expect(GemsCopy.gemUnit, 'Gem');
    final reading = ReflectiveIntelligence.synthesize(
      context: _ctx('en'),
      requestId: 'en',
    );
    expect(reading.summary, isNot(contains('işaret ediyor olabilir')));
    expect(reading.summary, isNot(contains('Açılım')));
    expect(reading.sections.first.title, 'Main theme');
  });

  test('RU chrome is Russian, not leftover Turkish', () {
    OraclyL10n.bind('ru');
    expect(TarotL10n.cardName(0), 'Шут');
    expect(TarotL10n.cardName(22), contains('Кубк'));
    expect(TarotL10n.spread(TarotSpreadType.single), 'Одна карта');
    expect(TarotL10n.position('past'), 'Прошлое');
    expect(TarotPolishCopy.retry, isNot(contains('TEKRAR')));
    expect(TarotL10n.deckName, contains('Таро'));
    expect(GemsCopy.gemUnit, 'Кристалл');
    final reading = ReflectiveIntelligence.synthesize(
      context: _ctx('ru'),
      requestId: 'ru',
    );
    expect(reading.summary, isNot(contains('işaret ediyor olabilir')));
    expect(reading.summary, isNot(contains('Açılım')));
    expect(reading.sections.first.title, 'Главная тема');
  });

  test('tarot prompt stays in the selected language', () {
    OraclyL10n.bind('en');
    final en = InterpretationPromptAdapter().buildPrompt(_ctx('en'));
    expect(en.system, contains('Write the entire reading in natural English'));
    expect(en.system, isNot(contains('Yanıtı tamamen Türkçe')));
    expect(en.user, contains('Spread:'));
    expect(en.user, isNot(contains('Açılım:')));

    OraclyL10n.bind('ru');
    final ru = InterpretationPromptAdapter().buildPrompt(_ctx('ru'));
    expect(ru.system, contains('Пиши всё толкование на естественном русском'));
    expect(ru.system, isNot(contains('Yanıtı tamamen Türkçe')));
    expect(ru.user, contains('Расклад:'));
    expect(ru.user, isNot(contains('Açılım:')));

    OraclyL10n.bind('tr');
    final tr = InterpretationPromptAdapter().buildPrompt(_ctx('tr'));
    expect(tr.system, contains('Yanıtı tamamen doğal Türkçe yaz'));
    expect(tr.user, contains('Açılım:'));
  });

  test('tarot template does not fall back to Turkish for EN/RU', () {
    final template = PromptTemplateCatalogue.tarotReading;
    expect(template.localization('en', 'spread_label'), 'Spread');
    expect(template.localization('ru', 'spread_label'), 'Расклад');
    expect(template.localization('en', 'missing_key'), isNull);
    expect(
      PromptTemplate(
        id: 'x',
        version: '1',
        domain: 'tarot',
        systemBody: '',
        userBody: '',
        localizations: {
          'tr': {'role': 'TR'},
          'en': {'role': 'EN'},
        },
      ).localization('en', 'absent'),
      isNull,
    );
  });

  test('hedges follow the bound language', () {
    OraclyL10n.bind('tr');
    expect(ReadingHedge.phrases, contains('işaret ediyor olabilir'));
    OraclyL10n.bind('en');
    expect(ReadingHedge.phrases, contains('may be pointing here'));
    expect(ReadingHedge.phrases, isNot(contains('işaret ediyor olabilir')));
    OraclyL10n.bind('ru');
    expect(ReadingHedge.phrases, contains('может указывать на это'));
  });
}
