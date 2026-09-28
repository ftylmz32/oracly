/// G1 Audit.2 — the final OR conversation write is guarded a second time,
/// after `LocalAiConversationRepository` has loaded the current list and
/// immediately before it calls `setStringList`, not just at the top of
/// `CompanionExperienceService.send()`. Also: a `setStringList` that
/// resolves `false` (no exception) must fail the write, never look like a
/// silent success.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_ai_conversation_repository.dart';
import 'package:oracly_new/core/domain/models/conversation_record.dart';
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

/// A `LocalStorage` whose `setStringList` always resolves `false`, without
/// throwing — the exact shape a real `SharedPreferences` write failure
/// takes. Reads still work, so a repository can load an existing list
/// before its write is refused.
class _FalseWriteStorage extends LocalStorage {
  _FalseWriteStorage() : super.ephemeral();

  @override
  Future<bool> setStringList(String key, List<String> values) async => false;
}

/// Like [_FalseWriteStorage], but only the SECOND write resolves `false` —
/// the first (the user-turn save) durably lands, so `send()` reaches the
/// provider and only the assistant-reply write fails.
class _SecondWriteFailsStorage extends LocalStorage {
  _SecondWriteFailsStorage() : super.ephemeral();

  int _calls = 0;

  @override
  Future<bool> setStringList(String key, List<String> values) async {
    _calls++;
    if (_calls == 1) return super.setStringList(key, values);
    return false;
  }
}

class _Device {
  _Device(this.storage);

  final LocalStorage storage;
  String? auth = 'owner-a';

  static Future<_Device> open() async {
    SharedPreferences.setMockInitialValues({
      UserLocalDataIsolation.ownerKey: 'owner-a',
    });
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
    return repo.save(
      CompanionRecordMapper.toRecord(
        Conversation(
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
        ),
      ),
    );
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

  group('final write-point owner guard (repository-level race)', () {
    test(
      'owner switches + wipes DURING the repository read: the paused old-A '
      'write is refused and the post-wipe empty storage stays empty',
      () async {
        final device = await _Device.open();
        // Pause only the SECOND saveGuarded call (the assistant reply): the
        // first is the user-turn save, which must go through untouched.
        var reads = 0;
        final gate = Completer<void>();
        device.repo.debugPauseAfterRead = () async {
          reads++;
          if (reads == 2) await gate.future;
        };
        final ai = G1ScriptedAi(replies: const [_aReply]);
        final controller = g1Companion(
          ai: ai,
          repo: device.repo,
          storage: device.storage,
          ownerGuard: device.guard,
        );

        final pending = controller.send(_aMessage);
        await _untilInFlight(ai);
        // Give saveGuarded's first (user-turn) pass, the provider call, and
        // the second saveGuarded call time to reach the read-then-pause
        // point before the switch happens.
        for (var i = 0; i < 200 && reads < 2; i++) {
          await Future<void>.delayed(Duration.zero);
        }
        expect(reads, 2, reason: 'the assistant write must be mid-read');
        expect(
          device.raw,
          contains(_aMessage),
          reason: 'the user turn was already saved for A before the switch',
        );

        // The account switch + wipe happens entirely inside the pause.
        device.auth = 'owner-b';
        await device.wipeConversations();
        await device.commitOwner('owner-b');
        gate.complete();
        await pending;

        expect(
          device.raw,
          isNot(contains(_aMessage)),
          reason: 'the wipe must not be undone by the paused A write',
        );
        expect(device.raw, isNot(contains(_aReply)));
        expect(device.raw, isEmpty);
        expect(controller.state.lastFailureKind, isNotNull);
      },
    );

    test('wipe window mid-read: auth already B, local owner still A, epoch not '
        'yet bumped — the resumed write is blocked', () async {
      final device = await _Device.open();
      var reads = 0;
      final gate = Completer<void>();
      device.repo.debugPauseAfterRead = () async {
        reads++;
        if (reads == 2) await gate.future;
      };
      final ai = G1ScriptedAi(replies: const [_aReply]);
      final controller = g1Companion(
        ai: ai,
        repo: device.repo,
        storage: device.storage,
        ownerGuard: device.guard,
      );

      final pending = controller.send(_aMessage);
      await _untilInFlight(ai);
      for (var i = 0; i < 200 && reads < 2; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(reads, 2);

      // Mid-wipe ordering: auth has already moved, the local owner and the
      // epoch have not — this window must never be writable either.
      device.auth = 'owner-b';
      await device.wipeConversations();
      gate.complete();
      await pending;

      expect(device.raw, isNot(contains(_aMessage)));
      expect(device.raw, isNot(contains(_aReply)));
      expect(device.raw, isEmpty);
    });

    test("B's own row, written during the pause, survives the refused old-A "
        'write that resumes after it', () async {
      final device = await _Device.open();
      var reads = 0;
      final gate = Completer<void>();
      device.repo.debugPauseAfterRead = () async {
        reads++;
        if (reads == 2) await gate.future;
      };
      final ai = G1ScriptedAi(replies: const [_aReply]);
      final controller = g1Companion(
        ai: ai,
        repo: device.repo,
        storage: device.storage,
        ownerGuard: device.guard,
      );

      final pending = controller.send(_aMessage);
      await _untilInFlight(ai);
      for (var i = 0; i < 200 && reads < 2; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(reads, 2);

      device.auth = 'owner-b';
      await device.wipeConversations();
      await device.seedThread('B OWN THREAD');
      await device.commitOwner('owner-b');
      gate.complete();
      await pending;

      expect(
        device.raw,
        contains('B OWN THREAD'),
        reason: "B's row must survive the refused, stale A write",
      );
      expect(device.raw, isNot(contains(_aMessage)));
      expect(device.raw, isNot(contains(_aReply)));
    });

    test(
      'an unchanged, settled owner writes normally through saveGuarded',
      () async {
        final device = await _Device.open();
        final ai = G1ScriptedAi(replies: const ['A calm reply.']);
        final controller = g1Companion(
          ai: ai,
          repo: device.repo,
          storage: device.storage,
          ownerGuard: device.guard,
        );
        await controller.send('hello from A');
        expect(device.raw, contains('hello from A'));
        expect(device.raw, contains('A calm reply.'));
        expect(controller.state.lastFailureKind, isNull);
      },
    );
  });

  group(
    'setStringList == false is a write failure, never a silent success',
    () {
      test(
        'LocalAiConversationRepository.save throws on a false write',
        () async {
          final repo = LocalAiConversationRepository(_FalseWriteStorage());
          final now = DateTime.now();
          final record = ConversationRecord(
            id: 'c1',
            title: 'OR',
            kind: 'general',
            messagesJson: const [],
            createdAt: now,
            updatedAt: now,
          );
          await expectLater(repo.save(record), throwsA(isA<StateError>()));
        },
      );

      test(
        'LocalAiConversationRepository.saveGuarded throws on a false write',
        () async {
          final repo = LocalAiConversationRepository(_FalseWriteStorage());
          final now = DateTime.now();
          final record = ConversationRecord(
            id: 'c1',
            title: 'OR',
            kind: 'general',
            messagesJson: const [],
            createdAt: now,
            updatedAt: now,
          );
          await expectLater(
            repo.saveGuarded(record, canWrite: () => true),
            throwsA(isA<StateError>()),
          );
        },
      );

      test(
        'LocalAiConversationRepository.delete throws on a false write',
        () async {
          final repo = LocalAiConversationRepository(_FalseWriteStorage());
          await expectLater(repo.delete('c1'), throwsA(isA<StateError>()));
        },
      );

      test(
        'a false conversation write never reports persisted: true from send()',
        () async {
          final storage = _SecondWriteFailsStorage();
          final repo = LocalAiConversationRepository(storage);
          final guard = CompanionOwnerGuard(
            liveOwnerId: () => 'owner-a',
            localOwnerId: () => 'owner-a',
          );
          final ai = G1ScriptedAi(replies: const ['A reply that cannot land.']);
          final controller = g1Companion(
            ai: ai,
            repo: repo,
            storage: storage,
            ownerGuard: guard,
          );
          await controller.send('hello');
          expect(ai.calls, 1, reason: 'the provider still ran');
          expect(
            controller.state.lastFailureKind,
            AiFailureKind.localPersistence,
          );
          // The reply still shows — persistence failure is honest, not a
          // silent drop of a reply the user is owed.
          expect(
            controller.state.conversation!.messages.last.content,
            'A reply that cannot land.',
          );
        },
      );
    },
  );
}
