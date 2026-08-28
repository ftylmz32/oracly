/// Natural OR opening — conversation entry, not a chatbot launch.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/personality/or_conversation_opening.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('openings stay personal and never help-desk', () {
    final lines = {
      for (final style in AiPersonality.values)
        for (var day = 1; day <= 12; day++)
          OrConversationOpening.line(
            personality: style.name,
            moment: DateTime(2026, 5, day, 10),
          ),
    };
    expect(lines.length, greaterThan(3));
    for (final line in lines) {
      final lower = line.toLowerCase();
      expect(lower, isNot(contains('nasıl yardımcı')));
      expect(lower, isNot(contains('how can i help')));
      expect(lower, isNot(contains('size bugün')));
      expect(line.trim(), isNotEmpty);
      expect(line.length, lessThan(90));
    }
    // Not every opening is a question.
    expect(lines.any((l) => !l.trim().endsWith('?')), isTrue);
  });

  test('named open stays a greeting, not a service script', () {
    final line = CompanionCopy.welcomeLine(
      name: 'Fatih',
      moment: DateTime(2026, 5, 3),
    );
    expect(line, contains('Fatih'));
    expect(line.toLowerCase(), isNot(contains('nasıl yardımcı')));
    expect(line, isNot(contains('\n')));
  });

  test('idle caption matches the opening contract', () {
    final moment = DateTime(2026, 5, 4, 9);
    expect(
      CompanionCopy.idleCaption(moment: moment),
      OrConversationOpening.line(moment: moment),
    );
    expect(
      CompanionCopy.welcome(moment: moment),
      CompanionCopy.idleCaption(moment: moment),
    );
  });
}
