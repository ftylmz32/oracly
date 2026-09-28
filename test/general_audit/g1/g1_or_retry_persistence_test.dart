/// G1 — OR quality re-generation never reuses the turn's idempotency key,
/// which would make the server replay the reply the gate just rejected.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/companion/services/companion_ai_bridge.dart';
import 'package:oracly_new/features/companion/services/or_operation_id.dart';

import 'g1_or_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('en'));

  test('the first attempt keeps the turn key; a re-generation gets its own',
      () async {
    final first = await OrOperationId.run(
      'or-chat-1',
      () => OrOperationId.runQualityAttempt(1, () async => OrOperationId.current),
    );
    final second = await OrOperationId.run(
      'or-chat-1',
      () => OrOperationId.runQualityAttempt(2, () async => OrOperationId.current),
    );

    expect(first, 'or-chat-1');
    expect(second, startsWith('or-chat-1.q2.'));
  });

  test('a rejected reply is re-generated under a distinct key', () async {
    final ai = G1ScriptedAi(replies: const ['', 'A calm, grounded reply.']);

    final text = await OrOperationId.run(
      'or-chat-7',
      () => CompanionAiBridge(ai).tryLive(userMessage: 'How do I slow down?'),
    );

    expect(text, contains('calm'));
    expect(ai.operationIds, hasLength(2));
    expect(ai.operationIds.first, 'or-chat-7');
    expect(ai.operationIds.last, isNot('or-chat-7'));
    expect(ai.operationIds.last, startsWith('or-chat-7.q2.'));
  });

  test('a retry of the same failed turn still reuses the turn key', () async {
    final ai = G1ScriptedAi();
    final bridge = CompanionAiBridge(ai);

    await OrOperationId.run('or-chat-9', () => bridge.tryLive(userMessage: 'a'));
    await OrOperationId.run('or-chat-9', () => bridge.tryLive(userMessage: 'a'));

    expect(ai.operationIds, ['or-chat-9', 'or-chat-9']);
  });
}
