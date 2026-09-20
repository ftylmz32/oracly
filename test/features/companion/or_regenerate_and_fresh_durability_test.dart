/// OR regenerate + New Chat durability regressions.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/domain/models/conversation_record.dart';
import 'package:oracly_new/core/domain/repositories/ai_conversation_repository.dart';
import 'package:oracly_new/core/intelligence/data/intelligence_index_store.dart';
import 'package:oracly_new/core/intelligence/data/local_intelligence_repository.dart';
import 'package:oracly_new/core/intelligence/data/ritual_history_reader.dart';
import 'package:oracly_new/core/intelligence/services/intelligence_layer_service.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/personality/or_response_depth.dart';
import 'package:oracly_new/features/ai/domain/models/ai_message.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/models/chat_ai_reply.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_service.dart';
import 'package:oracly_new/features/companion/controllers/companion_controller.dart';
import 'package:oracly_new/features/companion/controllers/companion_output_controller.dart';
import 'package:oracly_new/features/companion/data/companion_record_mapper.dart';
import 'package:oracly_new/features/companion/models/companion_state.dart';
import 'package:oracly_new/features/companion/models/conversation.dart';
import 'package:oracly_new/features/companion/models/or_chat_output_mode.dart';
import 'package:oracly_new/features/companion/services/companion_experience_service.dart';
import 'package:oracly_new/features/companion/services/companion_memory_service.dart';
import 'package:oracly_new/features/companion/services/companion_session_bootstrap.dart';
import 'package:oracly_new/features/companion/services/or_operation_id.dart';
import 'package:oracly_new/features/gems/services/paid_ai_operation_id.dart';
import 'package:oracly_new/services/memory_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('en'));

  group('regenerateLast', () {
    test('replaces answer without duplicating the user turn', () async {
      final ai = _CountingAi();
      final repo = _MemRepo();
      var seq = 0;
      final controller = _controller(
        ai: ai,
        repo: repo,
        operationIdFactory: (_) => 'op-${++seq}',
      );
      final now = DateTime.now();
      final seeded = Conversation(
        id: CompanionSessionBootstrap.sessionId,
        title: 'OR',
        topic: ConversationTopic.general,
        messages: [
          AIMessage(
            id: 'w',
            role: AIMessageRole.assistant,
            content: 'Welcome',
            createdAt: now,
          ),
          AIMessage(
            id: 'u1',
            role: AIMessageRole.user,
            content: 'same question',
            createdAt: now,
            metadata: {
              OrOperationId.metadataKey: 'op-A',
              OrOperationId.stateKey: OrOperationId.completed,
            },
          ),
          AIMessage(
            id: 'a1',
            role: AIMessageRole.assistant,
            content: 'old answer',
            createdAt: now,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );
      await repo.save(CompanionRecordMapper.toRecord(seeded));
      controller.seedSessionForTest(
        conversation: seeded,
        phase: CompanionPhase.conversing,
      );

      await controller.regenerateLast();

      expect(ai.chatCalls, 1);
      final users = controller.state.conversation!.messages
          .where((m) => m.isUser)
          .toList();
      expect(users, hasLength(1));
      expect(users.single.content, 'same question');
      expect(users.single.metadata[OrOperationId.metadataKey], 'op-1');
      expect(users.single.metadata[OrOperationId.metadataKey], isNot('op-A'));
      final assistants = controller.state.conversation!.messages
          .where((m) => !m.isUser && !m.id.startsWith('welcome') && m.id != 'w')
          .toList();
      expect(assistants, hasLength(1));
      expect(assistants.single.content, isNot('old answer'));

      final stored = await repo.getById(CompanionSessionBootstrap.sessionId);
      final mapped = CompanionRecordMapper.fromRecord(stored!);
      expect(mapped.messages.where((m) => m.isUser), hasLength(1));
      expect(
        mapped.messages.where((m) => m.isUser).single.metadata[OrOperationId
            .metadataKey],
        'op-1',
      );

      final reloaded = _controller(
        ai: ai,
        repo: repo,
        operationIdFactory: (_) => 'unused',
      );
      await reloaded.initialize();
      expect(
        reloaded.state.conversation!.messages.where((m) => m.isUser),
        hasLength(1),
      );
    });

    test('rapid double regenerate starts one provider generation', () async {
      final ai = _CountingAi(delay: const Duration(milliseconds: 80));
      final repo = _MemRepo();
      var seq = 0;
      final controller = _controller(
        ai: ai,
        repo: repo,
        operationIdFactory: (_) => 'op-${++seq}',
      );
      final now = DateTime.now();
      controller.seedSessionForTest(
        conversation: Conversation(
          id: CompanionSessionBootstrap.sessionId,
          title: 'OR',
          topic: ConversationTopic.general,
          messages: [
            AIMessage(
              id: 'w',
              role: AIMessageRole.assistant,
              content: 'Hi',
              createdAt: now,
            ),
            AIMessage(
              id: 'u',
              role: AIMessageRole.user,
              content: 'same question',
              createdAt: now,
              metadata: {
                OrOperationId.metadataKey: 'op-A',
                OrOperationId.stateKey: OrOperationId.completed,
              },
            ),
            AIMessage(
              id: 'a',
              role: AIMessageRole.assistant,
              content: 'old',
              createdAt: now,
            ),
          ],
          createdAt: now,
          updatedAt: now,
        ),
        phase: CompanionPhase.conversing,
      );

      await Future.wait([
        controller.regenerateLast(),
        controller.regenerateLast(),
      ]);

      expect(ai.chatCalls, 1);
      expect(
        controller.state.conversation!.messages.where((m) => m.isUser),
        hasLength(1),
      );
      expect(
        controller.state.conversation!.messages
            .where((m) => m.isUser == false && m.id != 'w')
            .length,
        1,
      );
    });

    test('provider failure keeps one user turn; retry reuses new pending id',
        () async {
      final ai = _CountingAi(failFirst: true);
      final repo = _MemRepo();
      var seq = 0;
      final controller = _controller(
        ai: ai,
        repo: repo,
        operationIdFactory: (_) => 'op-${++seq}',
      );
      final now = DateTime.now();
      controller.seedSessionForTest(
        conversation: Conversation(
          id: CompanionSessionBootstrap.sessionId,
          title: 'OR',
          topic: ConversationTopic.general,
          messages: [
            AIMessage(
              id: 'w',
              role: AIMessageRole.assistant,
              content: 'Hi',
              createdAt: now,
            ),
            AIMessage(
              id: 'u',
              role: AIMessageRole.user,
              content: 'same question',
              createdAt: now,
              metadata: {
                OrOperationId.metadataKey: 'op-A',
                OrOperationId.stateKey: OrOperationId.completed,
              },
            ),
            AIMessage(
              id: 'a',
              role: AIMessageRole.assistant,
              content: 'old',
              createdAt: now,
            ),
          ],
          createdAt: now,
          updatedAt: now,
        ),
        phase: CompanionPhase.conversing,
      );

      await controller.regenerateLast();
      expect(ai.chatCalls, 1);
      final users = controller.state.conversation!.messages
          .where((m) => m.isUser)
          .toList();
      expect(users, hasLength(1));
      expect(users.single.metadata[OrOperationId.metadataKey], 'op-1');
      expect(users.single.metadata[OrOperationId.stateKey], OrOperationId.pending);

      await controller.retryLast();
      expect(ai.operationIds, ['op-1', 'op-1']);
      expect(
        controller.state.conversation!.messages.where((m) => m.isUser),
        hasLength(1),
      );
    });
  });

  group('startFreshConversation durability', () {
    test('persistence failure keeps old thread and surfaces retry', () async {
      final repo = _MemRepo();
      final ai = _CountingAi();
      final controller = _controller(ai: ai, repo: repo);
      final now = DateTime.now();
      final prior = Conversation(
        id: CompanionSessionBootstrap.sessionId,
        title: 'OR',
        topic: ConversationTopic.general,
        messages: [
          AIMessage(
            id: 'u-old',
            role: AIMessageRole.user,
            content: 'Old thread stays forever?',
            createdAt: now,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );
      await repo.save(CompanionRecordMapper.toRecord(prior));
      repo.failNextSaves = 1;
      controller.seedSessionForTest(
        conversation: prior,
        phase: CompanionPhase.conversing,
      );

      await controller.startFreshConversation();

      expect(ai.chatCalls, 0);
      expect(controller.state.conversation?.messages.any((m) => m.isUser), isTrue);
      expect(
        controller.state.conversation!.messages.single.content,
        'Old thread stays forever?',
      );
      expect(
        controller.state.lastFailureKind,
        AiFailureKind.localPersistence,
      );
      expect(controller.state.errorMessage, isNotNull);

      final stored = await repo.getById(CompanionSessionBootstrap.sessionId);
      expect(
        CompanionRecordMapper.fromRecord(stored!).messages.single.content,
        'Old thread stays forever?',
      );

      await controller.retryLast();
      expect(controller.state.lastFailureKind, isNull);
      expect(controller.state.conversation?.messages.any((m) => m.isUser), isFalse);
      final freshStored = await repo.getById(
        CompanionSessionBootstrap.sessionId,
      );
      expect(
        CompanionRecordMapper.fromRecord(freshStored!).messages.any(
          (m) => m.isUser,
        ),
        isFalse,
      );
    });

    test('successful New Chat survives immediate reload without send', () async {
      final repo = _MemRepo();
      final controller = _controller(ai: _CountingAi(), repo: repo);
      final now = DateTime.now();
      final prior = Conversation(
        id: CompanionSessionBootstrap.sessionId,
        title: 'OR',
        topic: ConversationTopic.general,
        messages: [
          AIMessage(
            id: 'u-old',
            role: AIMessageRole.user,
            content: 'prior',
            createdAt: now,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );
      await repo.save(CompanionRecordMapper.toRecord(prior));
      controller.seedSessionForTest(
        conversation: prior,
        phase: CompanionPhase.conversing,
      );

      await controller.startFreshConversation();
      expect(controller.state.conversation?.messages.any((m) => m.isUser), isFalse);

      final reloaded = _controller(ai: _CountingAi(), repo: repo);
      await reloaded.initialize();
      expect(reloaded.state.conversation?.messages.any((m) => m.isUser), isFalse);
    });
  });
}

CompanionController _controller({
  required OraclyAiService ai,
  required AiConversationRepository repo,
  String Function(String feature)? operationIdFactory,
}) {
  final storage = LocalStorage.ephemeral();
  return CompanionController(
    CompanionExperienceService(
      conversationRepository: repo,
      intelligence: IntelligenceLayerService(
        LocalIntelligenceRepository(
          history: MockHistoryRepository(storage),
          conversations: repo,
          ritualHistory: RitualHistoryReader(storage),
          indexStore: IntelligenceIndexStore(storage),
        ),
      ),
      memoryService: CompanionMemoryService(MemoryService(storage)),
      ai: ai,
    ),
    CompanionOutputController(
      persistMode: (_) async {},
      readMode: () => OrChatOutputMode.text,
    ),
    operationIdFactory: operationIdFactory ?? PaidAiOperationId.create,
  );
}

class _MemRepo implements AiConversationRepository {
  final Map<String, ConversationRecord> _rows = {};
  int failNextSaves = 0;

  @override
  Future<void> save(ConversationRecord record) async {
    if (failNextSaves > 0) {
      failNextSaves--;
      throw StateError('simulated save failure');
    }
    _rows[record.id] = record;
  }

  @override
  Future<void> delete(String id) async => _rows.remove(id);

  @override
  Future<List<ConversationRecord>> getAll() async => _rows.values.toList();

  @override
  Future<ConversationRecord?> getById(String id) async => _rows[id];

  @override
  Future<void> sync() async {}
}

class _CountingAi implements OraclyAiService {
  _CountingAi({this.failFirst = false, this.delay});

  final bool failFirst;
  final Duration? delay;
  int chatCalls = 0;
  final List<String> operationIds = [];

  @override
  bool get isConfigured => true;
  @override
  bool get allowsLocalFallback => false;
  @override
  bool get visionAvailable => false;

  @override
  Future<AiOutcome<ChatAiReply>> chat({
    required String userMessage,
    List<String> priorUser = const [],
    String? styleHint,
    String? personality,
    List<ConversationTurn> turns = const [],
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
  }) async {
    chatCalls++;
    final op = OrOperationId.current;
    if (op != null) operationIds.add(op);
    if (delay != null) await Future<void>.delayed(delay!);
    if (failFirst && chatCalls == 1) {
      return AiOutcome.failure(AiFailure.network());
    }
    return AiOutcome.success(ChatAiReply(text: 'regen reply $chatCalls'));
  }

  @override
  Future<AiOutcome<ChatAiReply>> askOracle({
    required ReadingAiContext context,
    required String userMessage,
    List<String> priorUser = const [],
    List<String> observedThemes = const [],
    String? styleHint,
    String? personality,
    List<ConversationTurn> turns = const [],
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
  }) =>
      chat(userMessage: userMessage, turns: turns, depth: depth, spoken: spoken);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}
