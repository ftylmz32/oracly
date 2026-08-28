/// EN/RU prompts stay native - same personality, no Turkish system dump.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/personality/or_prompt_locale.dart';
import 'package:oracly_new/features/ai/production/openai/chat_prompt_builder.dart';
import 'package:oracly_new/features/prompt_engine/formatters/output_format_locale.dart';
import 'package:oracly_new/features/prompt_engine/templates/sections/shared_sections.dart';

void main() {
  tearDown(() => OraclyL10n.bind('tr'));

  test('English chat system is English, not Turkish craft rules', () {
    OraclyL10n.bind('en');
    final system = ChatPromptBuilder.system.toLowerCase();
    expect(system, contains('you are or'));
    expect(system, contains('natural english'));
    expect(system, isNot(contains('sohbeti')));
    expect(OrPromptLocale.systemIdentity.toLowerCase(), contains('you are or'));
    expect(
      SharedTemplateSections.basePersona.toLowerCase(),
      contains('natural english'),
    );
  });

  test('Russian chat system is Russian', () {
    OraclyL10n.bind('ru');
    final system = ChatPromptBuilder.system;
    expect(system.startsWith('Ты OR'), isTrue);
    expect(system.contains('Естественный русский'), isTrue);
    expect(system, isNot(contains('Sohbeti')));
    expect(
      SharedTemplateSections.basePersona.contains('Отвечай полностью'),
      isTrue,
    );
  });

  test('astrology format localizes for en and ru', () {
    expect(
      OutputFormatLocale.instruction('astrology', 'en').toLowerCase(),
      contains("today's reading"),
    );
    expect(
      OutputFormatLocale.instruction('astrology', 'ru').contains('Сегодняшнее'),
      isTrue,
    );
    expect(
      OutputFormatLocale.instruction('astrology', 'tr'),
      contains('Bugünün'),
    );
  });
}