/// OR knowledge depth — provider path, no topic FAQs.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/personality/or_knowledge_depth.dart';
import 'package:oracly_new/features/ai/production/openai/chat_prompt_builder.dart';
import 'package:oracly_new/features/companion/models/insight_request.dart';
import 'package:oracly_new/features/companion/models/reflection_context.dart';
import 'package:oracly_new/features/companion/services/companion_responder.dart';
import 'package:oracly_new/features/companion/services/companion_turn_router.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('live system prompt invites broad domains without scripts', () {
    final system = ChatPromptBuilder.system;
    expect(system, contains(OrKnowledgeDepth.promptTr));
    expect(system.toLowerCase(), contains('ilişki'));
    expect(system.toLowerCase(), contains('bilim'));
    expect(system.toLowerCase(), contains('teknoloji'));
    expect(system.toLowerCase(), contains('oracly'));
    expect(system.toLowerCase(), contains('konu-bazlı hazır cevap'));
  });

  test('local router does not ship hardcoded knowledge FAQs', () {
    const or = CompanionResponder();
    final python = or.respond(
      request: InsightRequest(text: "Python'da async nasil calisiyor?"),
      context: const ReflectionContext(),
    );
    expect(python.body.toLowerCase(), isNot(contains('event loop')));
    expect(python.body.toLowerCase(), isNot(contains('async def')));

    final boss = or.respond(
      request: InsightRequest(text: 'Patronumla tartistim.'),
      context: const ReflectionContext(),
    );
    expect(boss.body, isNot(equals(OraclyL10n.t('or.boss'))));

    final handoff = CompanionTurnRouter.handoffOrListen(
      InsightRequest(
        text: 'Bu kart?',
        kind: InsightRequestKind.tarot,
      ),
      'direct',
    );
    expect(handoff.trim(), isNotEmpty);
  });
}
