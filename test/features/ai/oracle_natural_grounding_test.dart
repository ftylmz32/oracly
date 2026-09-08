import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/services/conversation_response_guard.dart';

void main() {
  tearDown(() => OraclyL10n.bind(AppLocale.tr));

  test('does not leak Turkish grounding copy into English replies', () {
    OraclyL10n.bind(AppLocale.en);

    final shaped = ConversationResponseGuard.polish(
      'A slower pace may help.',
      userMessage: 'This situation feels confusing today.',
    );

    expect(shaped, isNot(contains('dediğin yer duruyor')));
    expect(shaped, isNot(contains('“this”')));
  });

  test('skips generic Turkish filler words when grounding short replies', () {
    OraclyL10n.bind(AppLocale.tr);

    final shaped = ConversationResponseGuard.polish(
      'Bir süre dışarıdan bakmak iyi olabilir.',
      userMessage: 'Bunu neden böyle yaptığımı anlayamıyorum.',
    );

    expect(shaped, isNot(startsWith('“bunu”')));
    expect(shaped, isNot(startsWith('“neden”')));
    expect(shaped, isNot(startsWith('“böyle”')));
    expect(shaped, contains('“yaptığımı”'));
  });
}
