/// G1 Audit.1 — an OR reply still in flight when the account switches is
/// never written back after the wipe, not even while auth has already moved
/// to the next owner and the local owner is still the previous one.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_ai_conversation_repository.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/domain/models/ai_message.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/companion/data/companion_record_mapper.dart';
import 'package:oracly_new/features/companion/models/conversation.dart';
import 'package:oracly_new/features/companion/services/companion_owner_guard.dart';
import 'package:oracly_new/features/companion/services/companion_session_bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'g1_or_support.dart';

const _aMessage = 'A PRIVATE MESSAGE FROM OWNER A';
const _aReply = 'A PRIVATE REPLY FOR OWNER A';

class _Device {
  _Device(this.storage);

  final LocalStorage storage;
  String? auth = 'owner-a';

  static Future<_Device> open() async {
    SharedPreferences.setMockInitialValues(
      {UserLocalDataIsolation.ownerKey: 'owner-a'},
    );
    return _Device(await LocalStorage.open());
  }

  late final guard = CompanionOwnerGuard.fromStorage(
    storage,
    liveOwnerId: () => auth,
  );
  late final repo = LocalAiConversationRepository(storage);

  String get raw =>
      (storage.getStringList('ai_conversations') ?? const []).join('\n');

  /// The wipe has reached `ai_conversations`; the local owner is unchanged.
  Future<void> wipeConversations() =>
      storage.setStringList('ai_conversations', const []);

  Future<void> commitOwner(String uid) async {
    await storage.setString(UserLocalDataIsolation.ownerKey, uid);
    UserLocalDataIsolation.accountSwitchEpoch.value++;
  }

  Future<void> seedThread(String text) {
    final now = DateTime.now();
    return repo.save(CompanionRecordMapper.toRecord(Conversation(
      id: CompanionSessionBootstrap.sessionId,
      title: 'OR',
      topic: ConversationTopic.general,
      messages: [
        AIMessage(
          id: 'msg_u_seed',
          role: AIMessageRole.user,
          content: text,
          createdAt: now,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    )));
  }
}

Future<void> _untilInFlight(G1ScriptedAi ai) async {
  for (var i = 0; i < 200 && ai.calls == 0; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(ai.calls, 1, reason: 'the provider call must be in flight');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('en'));

  test('only a settled, unchanged owner may write', () {
    String? auth = 'owner-a';
    String? local = 'owner-a';
    final guard = CompanionOwnerGuard(
      liveOwnerId: () => auth,
      localOwnerId: () => local,
    );
    final a = guard.capture();
    expect(guard.stillValid(a), isTrue, reason: 'stable A');

    auth = 'owner-b';
    expect(guard.stillValid(a), isFalse, reason: 'wipe window: old A');
    expect(guard.capture().isSettled, isFalse, reason: 'nobody writes mid-wipe');

    local = 'owner-b';
    UserLocalDataIsolation.accountSwitchEpoch.value++;
    expect(guard.stillValid(a), isFalse, reason: 'switch done: old A');
    expect(guard.stillValid(guard.capture()), isTrue, reason: 'new B');

    auth = null;
    local = null;
    final none = guard.capture();
    expect(guard.stillValid(none), isTrue, reason: 'no owner: device-local');
    auth = 'owner-c';
    expect(guard.stillValid(none), isFalse, reason: 'first owner arrives');

    final broken = CompanionOwnerGuard(
      liveOwnerId: () => throw StateError('auth unavailable'),
      localOwnerId: () => 'owner-a',
    );
    expect(broken.stillValid(broken.capture()), isFalse);
  });

  test('wipe window: auth is B, local owner still A — the old reply is '
      'dropped', () async {
    final device = await _Device.open();
    final ai = G1ScriptedAi(replies: const [_aReply], hold: Completer());
    final controller = g1Companion(
      ai: ai,
      repo: device.repo,
      storage: device.storage,
      ownerGuard: device.guard,
    );

    final pending = controller.send(_aMessage);
    await _untilInFlight(ai);
    expect(device.raw, contains(_aMessage), reason: 'A turn saved for A');

    device.auth = 'owner-b';
    await device.wipeConversations();
    ai.hold!.complete();
    await pending;

    expect(device.raw, isNot(contains(_aMessage)));
    expect(device.raw, isNot(contains(_aReply)));
    final shown = controller.state.conversation!.messages.map((m) => m.content);
    expect(shown, isNot(contains(_aReply)));
    expect(controller.state.lastFailureKind, AiFailureKind.authPending);
  });

  test('switch completes before the reply: nothing of A returns and B\'s '
      'thread is kept', () async {
    final device = await _Device.open();
    final ai = G1ScriptedAi(replies: const [_aReply], hold: Completer());
    final controller = g1Companion(
      ai: ai,
      repo: device.repo,
      storage: device.storage,
      ownerGuard: device.guard,
    );

    final pending = controller.send(_aMessage);
    await _untilInFlight(ai);
    device.auth = 'owner-b';
    await device.wipeConversations();
    await device.seedThread('B OWN THREAD');
    await device.commitOwner('owner-b');
    await controller.resetForAccountSwitch();

    ai.hold!.complete();
    await pending;

    expect(device.raw, isNot(contains(_aMessage)));
    expect(device.raw, isNot(contains(_aReply)));
    expect(device.raw, contains('B OWN THREAD'));
    final shown = controller.state.conversation!.messages.map((m) => m.content);
    expect(shown, isNot(contains(_aReply)));
    expect(shown, isNot(contains(_aMessage)));
    expect(shown, contains('B OWN THREAD'));
  });

  test('after a legitimate switch B talks to OR and it is saved', () async {
    final device = await _Device.open();
    final ai = G1ScriptedAi(replies: const ['A saved reply.', 'B REPLY']);
    final controller = g1Companion(
      ai: ai,
      repo: device.repo,
      storage: device.storage,
      ownerGuard: device.guard,
    );
    await controller.send('A saved message.');
    expect(device.raw, contains('A saved reply.'));

    device.auth = 'owner-b';
    await device.wipeConversations();
    await device.commitOwner('owner-b');
    await controller.resetForAccountSwitch();
    await controller.send('B MESSAGE');

    expect(device.raw, contains('B MESSAGE'));
    expect(device.raw, contains('B REPLY'));
    expect(device.raw, isNot(contains('A saved')));
    expect(controller.state.errorMessage, isNull);
    expect(controller.state.conversation!.messages.last.content, 'B REPLY');
  });
}
