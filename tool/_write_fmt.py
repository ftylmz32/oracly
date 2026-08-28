from pathlib import Path
Path(r'c:\Dev\oracly_new\lib\features\prompt_engine\formatters\output_format_locale.dart').write_bytes('''/// Locale-native output format instructions — same craft, native wording.
library;

import 'output_format_catalogue.dart';

abstract final class OutputFormatLocale {
  OutputFormatLocale._();

  static String instruction(String formatId, String locale) {
    final code = locale.toLowerCase();
    if (code.startsWith('en')) {
      return switch (formatId) {
        'astrology' => _astrologyEn,
        'dream' => _dreamEn,
        'standard' => _standardEn,
        _ => OutputFormatCatalogue.byId(formatId)?.instructionTemplate ??
            _standardEn,
      };
    }
    if (code.startsWith('ru')) {
      return switch (formatId) {
        'astrology' => _astrologyRu,
        'dream' => _dreamRu,
        'standard' => _standardRu,
        _ => OutputFormatCatalogue.byId(formatId)?.instructionTemplate ??
            _standardRu,
      };
    }
    return OutputFormatCatalogue.byId(formatId)?.instructionTemplate ??
        OutputFormatCatalogue.standard.instructionTemplate;
  }

  static const _standardEn = '''
Write a natural reading. No mandatory heading skeleton.
It may be short or longer when needed. Do not force bullet lists.
No certainty and no prophecy. If data is thin, write less.
''';

  static const _standardRu = '''
Пиши естественное чтение. Без обязательного каркаса заголовков.
Может быть коротким или длиннее, если нужно. Не навязывай списки.
Нет уверенности и пророчества. Мало данных — пиши меньше.
''';

  static const _astrologyEn = '''
Give clear observation. Do not end with a question. Do not hand the work back.
No certainty; explain the chart plainly. Do not repeat "maybe" in every sentence.
Do not invent planets or transits. No stock horoscope template.
Do not spam energy / journey / universe filler.

## Today's reading
The real issue today — 2-3 sentences. Clear at first glance.

## Love
A real reading. Not only questions.

## Career
A real reading.

## Money
A real reading.

## Suggestion
One clear, usable takeaway.
''';

  static const _astrologyRu = '''
Дай ясное наблюдение. Не заканчивай вопросом. Не оставляй работу человеку.
Нет уверенности; объясняй карту понятно. Не повторяй «может» в каждом предложении.
Не выдумывай планеты и транзиты. Без шаблонного гороскопа.
Не лей «энергию / путь / вселенную».

## Сегодняшнее толкование
Настоящее дело дня — 2-3 предложения. Понятно с первого взгляда.

## Любовь
Настоящее толкование. Не только вопросы.

## Карьера
Настоящее толкование.

## Деньги
Настоящее толкование.

## Совет
Один ясный, применимый вывод.
''';

  static const _dreamEn = '''
Write one story. No mandatory heading rain.
Visible image → possible link → soft reading. No glossary entry.
No certainty. Do not end every reply with a question.
''';

  static const _dreamRu = '''
Пиши одну историю. Без обязательного дождя заголовков.
Видимый образ → возможная связь → мягкое толкование. Без словарной статьи.
Нет уверенности. Не заканчивай каждый ответ вопросом.
''';
}
'''.encode('utf-8'))
print('format locale ok')
