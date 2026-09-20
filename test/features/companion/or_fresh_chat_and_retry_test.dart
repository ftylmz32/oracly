/// Residual OR defects: fresh chat overwrites primary; offline Retry clears.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/domain/models/conversation_record.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
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
import 'package:oracly_new/features/companion/models/reflection_context.dart';
import 'package:oracly_new/features/companion/services/companion_experience_service.dart';
import 'package:oracly_new/features/companion/services/companion_memory_service.dart';
import 'package:oracly_new/features/companion/services/companion_session_bootstrap.dart';
import 'package:oracly_new/services/memory_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('en'));

  test('startFreshConversation overwrites companion_primary', () async {
    final repo = _MemRepo();
    final controller = _controller(repo);
    final now = DateTime.now();
    final prior = Conversation(
      id: CompanionSessionBootstrap.sessionId,
      title: 'OR Companion',
      topic: ConversationTopic.general,
      messages: [
        AIMessage(
          id: 'u1',
          role: AIMessageRole.user,
          content: 'Old thread stays forever?',
          createdAt: now,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );
    await repo.save(CompanionRecordMapper.toRecord(prior));
    controller.seedSessionForTest(
      conversation: prior,
      context: const ReflectionContext(),
      phase: CompanionPhase.conversing,
    );

    await controller.startFreshConversation();

    expect(
      controller.state.conversation?.id,
      CompanionSessionBootstrap.sessionId,
    );
    expect(
      controller.state.conversation?.messages.any((m) => m.isUser),
      isFalse,
    );
    final stored = await repo.getById(CompanionSessionBootstrap.sessionId);
    expect(stored, isNotNull);
    final mapped = CompanionRecordMapper.fromRecord(stored!);
    expect(mapped.messages.any((m) => m.isUser), isFalse);
  });

  test('retryLast without failed text clears offline for a new send', () async {
    final controller = _controller(_MemRepo());
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
        ],
        createdAt: now,
        updatedAt: now,
      ),
      phase: CompanionPhase.conversing,
    );
    controller.markOfflineForTest();
    expect(controller.state.linkStatus, CompanionLinkStatus.offline);

    await controller.retryLast();

    expect(controller.state.linkStatus, CompanionLinkStatus.online);
    expect(controller.state.lastFailureKind, isNull);
  });

  test('memory default category/importance keys resolve', () {
    expect(OraclyL10n.t('memory.cat.general'), 'General');
    expect(OraclyL10n.t('memory.imp.normal'), 'Normal');
  });
}

CompanionController _controller(AiConversationRepository repo) {
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
      ai: _IdleAi(),
    ),
    CompanionOutputController(
      persistMode: (_) async {},
      readMode: () => OrChatOutputMode.text,
    ),
  );
}

class _MemRepo implements AiConversationRepository {
  final Map<String, ConversationRecord> _rows = {};

  @override
  Future<void> save(ConversationRecord record) async =>
      _rows[record.id] = record;

  @override
  Future<void> delete(String id) async => _rows.remove(id);

  @override
  Future<List<ConversationRecord>> getAll() async => _rows.values.toList();

  @override
  Future<ConversationRecord?> getById(String id) async => _rows[id];

  @override
  Future<void> sync() async {}
}

class _IdleAi implements OraclyAiService {
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
  }) async =>
      AiOutcome.failure(AiFailure.network());

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
  }) async =>
      AiOutcome.failure(AiFailure.network());

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}
