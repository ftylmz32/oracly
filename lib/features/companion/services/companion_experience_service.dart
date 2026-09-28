/// Companion journey — live AI, fail-closed, never invented memory.
library;

import '../../../core/copy/ai_source_copy.dart';
import '../../../core/data/repositories/local_ai_conversation_repository.dart';
import '../../../core/domain/repositories/ai_conversation_repository.dart';
import '../../../core/domain/repositories/user_repository.dart';
import '../../../core/intelligence/services/intelligence_layer_service.dart';
import '../../../core/intelligence/services/personal_memory_service.dart';
import '../../../core/memory/oracly_memory.dart' as connected;
import '../../../core/memory/oracly_memory_store.dart';
import '../../../core/personality/or_response_depth.dart';
import '../../../features/ai/domain/models/ai_message.dart';
import '../../../features/ai/oracle_conversation/models/oracle_reading_context.dart';
import '../../../features/ai/production/ai_failure.dart';
import '../../../features/ai/production/ai_request_exception.dart';
import '../../../features/ai/production/oracly_ai_service.dart';
import '../../../features/daily_ritual/services/daily_ritual_service.dart';
import '../data/companion_record_mapper.dart';
import '../debug/or_runtime_log.dart';
import '../models/companion_send_result.dart';
import '../models/conversation.dart';
import '../models/insight_request.dart';
import '../models/memory.dart';
import '../models/memory_permission.dart';
import '../models/reflection_context.dart';
import 'companion_ai_bridge.dart';
import 'companion_context_builder.dart';
import 'companion_live_reply.dart';
import 'companion_memory_service.dart';
import 'companion_owner_guard.dart';
import 'companion_responder.dart';
import 'companion_session_bootstrap.dart';
import 'or_response_finalize.dart';
import 'or_operation_id.dart';

class CompanionExperienceService {
  CompanionExperienceService({
    required AiConversationRepository conversationRepository,
    required IntelligenceLayerService intelligence,
    required CompanionMemoryService memoryService,
    DailyRitualService? dailyRitual,
    CompanionContextBuilder? contextBuilder,
    UserRepository? users,
    CompanionResponder? responder,
    PersonalMemoryService? personalMemory,
    OraclyMemoryStore? connectedMemory,
    OraclyAiService? ai,
    Future<String?> Function(String userMessage)? styleHint,
    Future<String?> Function()? personality,
    Future<String?> Function()? observationLine,
    Future<({OrResponseDepth depth, bool spoken})> Function()? lengthPrefs,
    CompanionOwnerGuard? ownerGuard,
  }) : _conversations = conversationRepository,
       _owner = ownerGuard,
       _contextBuilder =
           contextBuilder ??
           CompanionContextBuilder(
             intelligence: intelligence,
             memoryService: memoryService,
             dailyRitual: dailyRitual,
             users: users,
             personalMemory: personalMemory,
             observationLine: observationLine,
           ),
       _live = CompanionLiveReply(
         responder: responder ?? const CompanionResponder(),
         bridge: ai == null ? null : CompanionAiBridge(ai),
         styleHint: styleHint ?? ((_) async => null),
         personality: personality ?? (() async => null),
         lengthPrefs: lengthPrefs,
         memoryPromptHint: () => personalMemory?.promptHint(),
       ),
       _memory = memoryService,
       _connectedMemory = connectedMemory;

  final AiConversationRepository _conversations;

  /// Null only where no account owner exists (isolated tests).
  final CompanionOwnerGuard? _owner;
  final CompanionContextBuilder _contextBuilder;
  final CompanionLiveReply _live;
  final CompanionMemoryService _memory;
  final OraclyMemoryStore? _connectedMemory;

  Future<({Conversation conversation, ReflectionContext context})>
  loadOrCreateSession() async {
    try {
      final loaded = await CompanionSessionBootstrap.loadOrCreate(
        conversations: _conversations,
        contextBuilder: _contextBuilder,
      );
      logOrSession(completed: true, ready: true);
      return loaded;
    } catch (error) {
      logOrSession(
        completed: false,
        ready: false,
        errorType: error.runtimeType.toString(),
      );
      rethrow;
    }
  }

  /// Provider generation and local persistence are separate outcomes.
  Future<CompanionSendResult> send({
    required Conversation conversation,
    required ReflectionContext context,
    required InsightRequest request,
    OracleReadingContext? readingContext,
  }) async {
    final owner = _owner?.capture();
    _requireOwner(owner, stage: 'user');
    // Best-effort user-turn save before generation — never blocks the provider.
    try {
      await _save(conversation, owner);
      logOrPersist(stage: 'user', ok: true);
    } catch (error) {
      logOrPersist(
        stage: 'user',
        ok: false,
        errorType: error.runtimeType.toString(),
      );
      throw AiRequestException(AiFailure.localPersistence());
    }

    final operationId = OrOperationId.pendingId(conversation.lastMessage);
    final result = operationId == null
        ? await _live.complete(
            request: request,
            context: context,
            prior: conversation.messages,
            readingContext: readingContext,
          )
        : await OrOperationId.run(
            operationId,
            () => _live.complete(
              request: request,
              context: context,
              prior: conversation.messages,
              readingContext: readingContext,
            ),
          );
    logOrPersist(stage: 'generation', ok: true, fromAi: result.fromAi);

    final now = DateTime.now();
    final body = OrResponseFinalize.forMessage(result.response.body);
    final assistant = AIMessage(
      id: 'msg_a_${now.millisecondsSinceEpoch}',
      role: AIMessageRole.assistant,
      content: body,
      createdAt: now,
      metadata: {
        ...AiSourceCopy.tag(fromAi: result.fromAi),
        if (result.response.suggestions.isNotEmpty)
          'suggestions': result.response.suggestions.join('|'),
      },
    );
    final completedMessages = [...conversation.messages];
    if (completedMessages.isNotEmpty && operationId != null) {
      completedMessages[completedMessages.length - 1] = OrOperationId.withState(
        completedMessages.last,
        OrOperationId.completed,
      );
    }
    final withReply = conversation.copyWith(
      messages: [...completedMessages, assistant],
      updatedAt: now,
    );

    // The owner may have switched while the provider was answering; this
    // reply then belongs to nobody on this device and is dropped unseen.
    // _save re-checks the same snapshot a second time, immediately before
    // the physical write starts, in case the owner moves during the
    // repository's own read.
    _requireOwner(owner, stage: 'assistant');
    try {
      await _save(withReply, owner);
      logOrPersist(stage: 'assistant', ok: true);
      return CompanionSendResult(
        conversation: withReply,
        response: CompanionResponse(
          body: body,
          suggestions: result.response.suggestions,
        ),
        fromAi: result.fromAi,
        persisted: true,
      );
    } catch (error) {
      logOrPersist(
        stage: 'assistant',
        ok: false,
        errorType: error.runtimeType.toString(),
        priorUserSaved: true,
      );
      // Keep the exact reply in memory — never relabel as provider failure.
      return CompanionSendResult(
        conversation: withReply,
        response: CompanionResponse(
          body: body,
          suggestions: result.response.suggestions,
        ),
        fromAi: result.fromAi,
        persisted: false,
      );
    }
  }

  /// Idempotent upsert of an existing conversation (persistence retry).
  Future<void> persistConversation(Conversation conversation) async {
    final owner = _owner?.capture();
    _requireOwner(owner, stage: 'retry');
    await _save(conversation, owner);
  }

  /// The one durable conversation write boundary for OR. Against
  /// [LocalAiConversationRepository] this re-checks [owner] a second time,
  /// after the repository has loaded the current list and immediately
  /// before it calls the storage write — closing the gap [_requireOwner]
  /// cannot see from outside the repository. This is a guard, not a
  /// database transaction: the physical `SharedPreferences` write itself is
  /// never made atomic with auth state, only checked as late as possible
  /// before it starts.
  Future<void> _save(Conversation conversation, CompanionOwnerSnapshot? owner) {
    final record = CompanionRecordMapper.toRecord(conversation);
    final repo = _conversations;
    bool canWrite() => owner == null || _owner!.stillValid(owner);
    if (repo is LocalAiConversationRepository) {
      return repo.saveGuarded(record, canWrite: canWrite);
    }
    if (!canWrite()) {
      throw StateError(
        'Owner changed before the conversation write; not saved.',
      );
    }
    return repo.save(record);
  }

  /// Throws a retryable auth-pending failure when [owner] is no longer the
  /// settled owner. The controller drops it silently if its turn was reset.
  void _requireOwner(CompanionOwnerSnapshot? owner, {required String stage}) {
    if (owner == null || _owner!.stillValid(owner)) return;
    logOrPersist(stage: stage, ok: false, errorType: 'owner_changed');
    throw AiRequestException(AiFailure.authPending());
  }

  Future<void> saveUserMemory({
    required String content,
    String category = 'general',
  }) async {
    await _memory.save(
      Memory(
        id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
        content: content,
        category: category,
        permission: MemoryPermission.saved,
        createdAt: DateTime.now(),
        source: MemorySource.user,
      ),
    );
    final now = DateTime.now();
    final normalized = content.trim();
    if (normalized.isNotEmpty) {
      await _connectedMemory?.upsert(
        connected.OraclyMemory(
          id: 'fact:${normalized.toLowerCase()}',
          kind: connected.OraclyMemoryKind.stableFact,
          source: connected.OraclyMemorySource(
            id: 'user_saved_${now.millisecondsSinceEpoch}',
            type: connected.OraclyReadingType.orConversation,
            occurredAt: now,
          ),
          summary: normalized,
          confidence: 1,
        ),
      );
    }
  }

  Future<List<Memory>> savedMemories() => _memory.savedMemories();
}
