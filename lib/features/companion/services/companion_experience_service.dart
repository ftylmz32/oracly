/// Companion journey — live AI, fail-closed, never invented memory.
library;

import '../../../../services/memory_service.dart';
import '../../../core/copy/ai_source_copy.dart';
import '../../../core/domain/repositories/ai_conversation_repository.dart';
import '../../../core/domain/repositories/user_repository.dart';
import '../../../core/intelligence/services/intelligence_layer_service.dart';
import '../../../core/intelligence/services/personal_memory_service.dart';
import '../../../core/personality/or_response_depth.dart';
import '../../../features/ai/domain/models/ai_message.dart';
import '../../../features/ai/oracle_conversation/models/oracle_reading_context.dart';
import '../../../features/ai/production/oracly_ai_service.dart';
import '../../../features/daily_ritual/services/daily_ritual_service.dart';
import '../data/companion_record_mapper.dart';
import '../debug/or_runtime_log.dart';
import '../models/conversation.dart';
import '../models/insight_request.dart';
import '../models/memory.dart';
import '../models/memory_permission.dart';
import '../models/reflection_context.dart';
import 'companion_ai_bridge.dart';
import 'companion_context_builder.dart';
import 'companion_live_reply.dart';
import 'companion_memory_service.dart';
import 'companion_responder.dart';
import 'companion_session_bootstrap.dart';
import 'or_response_finalize.dart';

class CompanionExperienceService {
  CompanionExperienceService({
    required AiConversationRepository conversationRepository,
    required IntelligenceLayerService intelligence,
    DailyRitualService? dailyRitual,
    CompanionContextBuilder? contextBuilder,
    UserRepository? users,
    CompanionResponder? responder,
    CompanionMemoryService? memoryService,
    PersonalMemoryService? personalMemory,
    OraclyAiService? ai,
    Future<String?> Function(String userMessage)? styleHint,
    Future<String?> Function()? personality,
    Future<String?> Function()? observationLine,
    Future<({OrResponseDepth depth, bool spoken})> Function()? lengthPrefs,
  }) : _conversations = conversationRepository,
       _contextBuilder =
           contextBuilder ??
           CompanionContextBuilder(
             intelligence: intelligence,
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
       _memory = memoryService ?? CompanionMemoryService(MemoryService());

  final AiConversationRepository _conversations;
  final CompanionContextBuilder _contextBuilder;
  final CompanionLiveReply _live;
  final CompanionMemoryService _memory;

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

  Future<({Conversation conversation, CompanionResponse response, bool fromAi})>
  send({
    required Conversation conversation,
    required ReflectionContext context,
    required InsightRequest request,
    OracleReadingContext? readingContext,
  }) async {
    final result = await _live.complete(
      request: request,
      context: context,
      prior: conversation.messages,
      readingContext: readingContext,
    );
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
    final withReply = conversation.copyWith(
      messages: [...conversation.messages, assistant],
      updatedAt: now,
    );
    await _persist(withReply);
    return (
      conversation: withReply,
      response: CompanionResponse(
        body: body,
        suggestions: result.response.suggestions,
      ),
      fromAi: result.fromAi,
    );
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
  }

  Future<List<Memory>> savedMemories() => _memory.savedMemories();

  Future<void> _persist(Conversation conversation) async {
    await _conversations.save(CompanionRecordMapper.toRecord(conversation));
  }
}
