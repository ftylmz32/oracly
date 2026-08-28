/// Locale-selected tarot prompt persona and output format.
library;

import 'tarot_prompt_format.dart';
import 'tarot_prompt_oracle.dart';
import 'tarot_prompt_persona.dart';

abstract final class TarotPromptLocale {
  TarotPromptLocale._();

  static String persona(String locale) => switch (locale) {
        'en' => TarotPromptPersona.en,
        'ru' => TarotPromptPersona.ru,
        _ => TarotPromptPersona.tr,
      };

  static String format(String locale) => switch (locale) {
        'en' => '${TarotPromptFormat.en}\n\n${TarotPromptOracle.en}',
        'ru' => '${TarotPromptFormat.ru}\n\n${TarotPromptOracle.ru}',
        _ => '${TarotPromptFormat.tr}\n\n${TarotPromptOracle.tr}',
      };
}
