/// SPRINT-003 — Companion journey orchestrator.
library;

import '../../../core/domain/repositories/ai_conversation_repository.dart';
import '../../../core/intelligence/services/intelligence_layer_service.dart';
import '../../../features/ai/domain/models/ai_message.dart';
import '../../../features/daily_ritual/services/daily_ritual_service.dart';
import '../models/memory.dart';
import '../models/memory_permission.dart';
import '../data/companion_record_mapper.dart';
import '../models/conversation.dart';
import '../models/insight_request.dart';
import '../models/reflection_context.dart';
import '../services/companion_context_builder.dart';
import '../services/companion_memory_service.dart';
import '../services/companion_responder.dart';
import '../../../../services/memory_service.dart';

class CompanionExperienceService {
  CompanionExperienceService({
    required AiConversationRepository conversationRepository,
    required IntelligenceLayerService intelligence,
    DailyRitualService? dailyRitual,
    CompanionContextBuilder? contextBuilder,
    CompanionResponder? responder,
    CompanionMemoryService? memoryService,
  })  : _conversations = conversationRepository,
        _contextBuilder = contextBuilder ??
            CompanionContextBuilder(
              intelligence: intelligence,
              dailyRitual: dailyRitual,
            ),
        _responder = responder ?? const CompanionResponder(),
        _memory = memoryService ??
            CompanionMemoryService(MemoryService());

  final AiConversationRepository _conversations;
  final CompanionContextBuilder _contextBuilder;
  final CompanionResponder _responder;
  final CompanionMemoryService _memory;

  static const _sessionId = 'companion_primary';

  Future<({Conversation conversation, ReflectionContext context})>
      loadOrCreateSession() async {
    final context = await _contextBuilder.build();
    final existing = await _conversations.getById(_sessionId);

    if (existing != null) {
      return (
        conversation: CompanionRecordMapper.fromRecord(existing),
        context: context,
      );
    }

    final welcome = _contextBuilder.welcomeMessage(context);
    final now = DateTime.now();
    final conversation = Conversation(
      id: _sessionId,
      title: 'OR Companion',
      topic: ConversationTopic.general,
      messages: [
        AIMessage(
          id: 'welcome_${now.millisecondsSinceEpoch}',
          role: AIMessageRole.assistant,
          content: welcome,
          createdAt: now,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );

    await _persist(conversation);
    return (conversation: conversation, context: context);
  }

  Future<({Conversation conversation, CompanionResponse response})> send({
    required Conversation conversation,
    required ReflectionContext context,
    required InsightRequest request,
  }) async {
    final now = DateTime.now();
    final userMsg = AIMessage(
      id: 'msg_u_${now.millisecondsSinceEpoch}',
      role: AIMessageRole.user,
      content: request.text.trim(),
      createdAt: now,
    );

    final response = _responder.respond(request: request, context: context);
    final assistantMsg = AIMessage(
      id: 'msg_a_${now.millisecondsSinceEpoch}',
      role: AIMessageRole.assistant,
      content: response.body,
      createdAt: now.add(const Duration(milliseconds: 1)),
      metadata: {
        if (response.suggestions.isNotEmpty)
          'suggestions': response.suggestions.join('|'),
      },
    );

    final updated = conversation.copyWith(
      messages: [...conversation.messages, userMsg, assistantMsg],
      updatedAt: DateTime.now(),
    );

    await _persist(updated);
    return (conversation: updated, response: response);
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
