/// Intelligent directness — kind, honest, never patronizing.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/personality/or_core.dart';
import 'package:oracly_new/core/personality/or_intelligent_directness.dart';
import 'package:oracly_new/core/personality/or_persona_contract.dart';
import 'package:oracly_new/features/ai/services/conversation_response_guard.dart';
import 'package:oracly_new/features/companion/data/companion_directness.dart';
import 'package:oracly_new/features/companion/models/insight_request.dart';
import 'package:oracly_new/features/companion/models/reflection_context.dart';
import 'package:oracly_new/features/companion/services/companion_responder.dart';

void main() {
  const or = CompanionResponder();
  setUp(() => OraclyL10n.bind('tr'));

  String say(String text) => or
      .respond(
        request: InsightRequest(text: text),
        context: const ReflectionContext(),
        personality: 'mystical',
      )
      .body;

  test('persona encodes kind honest intelligent directness', () {
    final id = OrPersonaContract.identityTr.toLowerCase();
    expect(id, contains('nazik'));
    expect(id, contains('dürüst'));
    expect(id, contains('zeki'));
    expect(id, contains('varsayım'));
    expect(id, contains('patronaj'));
    expect(OrPersonaContract.never, contains('insulting'));
    expect(OrPersonaContract.never, contains('patronizing'));
    expect(OrIntelligentDirectness.promptTr.toLowerCase(), contains('hakaret'));
  });

  test('local beats: disagree, slow, overthink, unconvincing', () {
    expect(
      CompanionDirectness.detect('Herkes iş değiştirmeli.'),
      CompanionDirectnessKind.disagree,
    );
    expect(
      CompanionDirectness.detect('Yarın hemen istifa edeceğim.'),
      CompanionDirectnessKind.slowDown,
    );
    expect(
      CompanionDirectness.detect(
        'Sürekli düşünüyorum, kafamda dönüp duruyor.',
      ),
      CompanionDirectnessKind.overthink,
    );
    expect(
      CompanionDirectness.detect('Hiç şüphem yok, kesinlikle haklıyım.'),
      CompanionDirectnessKind.unconvincing,
    );
  });

  test('router returns respectful disagreement without patronizing', () {
    final disagree = say('Herkes iş değiştirmeli.');
    expect(disagree, contains('Katılmıyorum'));
    expect(OrCore.looksPatronizing(disagree), isFalse);

    final slow = say('Yarın hemen istifa edeceğim.');
    expect(slow.toLowerCase(), contains('acele'));
    expect(OrCore.looksPatronizing(slow), isFalse);

    final over = say('Sürekli düşünüyorum, kafamda dönüp duruyor.');
    expect(over.toLowerCase(), contains('düşün'));
  });

  test('polish strips patronizing stock and keeps honest noticing', () {
    final out = ConversationResponseGuard.polish(
      'Aslında çok basit. Mesafe tarafı net duruyor.',
      userMessage: 'Kararsızım.',
    );
    expect(out.toLowerCase(), isNot(contains('aslında çok basit')));
    expect(out.toLowerCase(), contains('mesafe'));
    expect(OrCore.looksPatronizing('Sakin ol. Sen anlamıyorsun.'), isTrue);
  });
}
