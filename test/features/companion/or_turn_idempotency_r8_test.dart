/// R8 — OR turn identity: retry reuses id; regenerate/new send creates new.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/domain/models/ai_message.dart';
import 'package:oracly_new/features/companion/services/or_operation_id.dart';
import 'package:oracly_new/features/gems/services/paid_ai_operation_binder.dart';

void main() {
  test('OrOperationId.run binds PaidAiOperationBinder for the turn', () async {
    const id = 'or-chat-r8-turn';
    String? seenZone;
    String? seenBinder;
    await OrOperationId.run(id, () async {
      seenZone = OrOperationId.current;
      seenBinder = PaidAiOperationBinder.idempotencyKey;
    });
    expect(seenZone, id);
    expect(seenBinder, id);
    expect(OrOperationId.current, isNull);
    expect(PaidAiOperationBinder.idempotencyKey, isNull);
  });

  test('pendingId only returns pending user turns', () {
    final pending = AIMessage(
      id: 'u1',
      role: AIMessageRole.user,
      content: 'hello',
      createdAt: DateTime(2026, 1, 1),
      metadata: {
        OrOperationId.metadataKey: 'or-chat-1',
        OrOperationId.stateKey: OrOperationId.pending,
      },
    );
    final done = OrOperationId.withState(pending, OrOperationId.completed);
    expect(OrOperationId.pendingId(pending), 'or-chat-1');
    expect(OrOperationId.pendingId(done), isNull);
  });

  test('abandon then new send is a distinct intent identity', () {
    final first = AIMessage(
      id: 'u1',
      role: AIMessageRole.user,
      content: 'same words',
      createdAt: DateTime(2026, 1, 1),
      metadata: {
        OrOperationId.metadataKey: 'or-chat-1',
        OrOperationId.stateKey: OrOperationId.pending,
      },
    );
    final abandoned = OrOperationId.withState(first, OrOperationId.abandoned);
    final second = AIMessage(
      id: 'u2',
      role: AIMessageRole.user,
      content: 'same words',
      createdAt: DateTime(2026, 1, 2),
      metadata: {
        OrOperationId.metadataKey: 'or-chat-2',
        OrOperationId.stateKey: OrOperationId.pending,
      },
    );
    expect(OrOperationId.pendingId(abandoned), isNull);
    expect(OrOperationId.pendingId(second), 'or-chat-2');
    expect(second.metadata[OrOperationId.metadataKey], isNot(first.metadata[OrOperationId.metadataKey]));
  });
}
