/// G1 — OR (Companion) controller over a scripted AI and in-memory thread.
library;

import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/domain/models/conversation_record.dart';
import 'package:oracly_new/core/domain/repositories/ai_conversation_repository.dart';
import 'package:oracly_new/core/intelligence/data/intelligence_index_store.dart';
import 'package:oracly_new/core/intelligence/data/local_intelligence_repository.dart';
import 'package:oracly_new/core/intelligence/data/ritual_history_reader.dart';
import 'package:oracly_new/core/intelligence/services/intelligence_layer_service.dart';
import 'package:oracly_new/core/personality/or_response_depth.dart';
import 'package:oracly_new/features/ai/domain/models/ai_message.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/models/chat_ai_reply.dart';
import 'package:oracly_new/features/ai/production/models/coffee_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/palm_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_service.dart';
import 'package:oracly_new/features/companion/controllers/companion_controller.dart';
import 'package:oracly_new/features/companion/controllers/companion_output_controller.dart';
import 'package:oracly_new/features/companion/models/conversation.dart';
import 'package:oracly_new/features/companion/models/or_chat_output_mode.dart';
import 'package:oracly_new/features/companion/services/companion_experience_service.dart';
import 'package:oracly_new/features/companion/services/companion_memory_service.dart';
import 'package:oracly_new/features/companion/services/or_operation_id.dart';
import 'package:oracly_new/services/memory_service.dart';

/// Replies in order (the last one repeats); '' fails the quality gate.
class G1ScriptedAi implements OraclyAiService {
  G1ScriptedAi({this.replies = const ['A calm, grounded reply.'], this.delay});

  final List<String> replies;
  final Duration? delay;
  final operationIds = <String?>[];

  int get calls => operationIds.length;

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
    operationIds.add(OrOperationId.current);
    final reply = replies[(calls - 1).clamp(0, replies.length - 1)];
    if (delay != null) await Future<void>.delayed(delay!);
    return AiOutcome.success(ChatAiReply(text: reply));
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
      chat(userMessage: userMessage);

  @override
  Future<AiOutcome<ChatAiReply>> generateTarotReading({
    required List<Map<String, dynamic>> cards,
    required String spreadLabel,
    String? userQuestion,
    String? readingTheme,
    Map<String, dynamic>? journeyHints,
  }) =>
      throw UnsupportedError('tarot');

  @override
  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(DreamAiContext context) =>
      throw UnsupportedError('dream');

  @override
  Future<AiOutcome<CoffeeAiAnalysis>> analyzeCoffee({
    required List<int> imageBytes,
    required String mimeType,
    Map<String, dynamic>? personalization,
  }) =>
      throw UnsupportedError('coffee');

  @override
  Future<AiOutcome<PalmAiAnalysis>> analyzePalm({
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
    Map<String, dynamic>? personalization,
  }) =>
      throw UnsupportedError('palm');
}

class G1ThreadRepo implements AiConversationRepository {
  bool failAssistant = false;
  final rows = <String, ConversationRecord>{};

  @override
  Future<void> save(ConversationRecord record) async {
    final hasReply = record.messagesJson
        .any((m) => m['role'] == 'assistant' && m['id'] != 'welcome');
    if (failAssistant && hasReply) throw StateError('assistant_persist_failed');
    rows[record.id] = record;
  }

  @override
  Future<void> delete(String id) async => rows.remove(id);
  @override
  Future<List<ConversationRecord>> getAll() async => rows.values.toList();
  @override
  Future<ConversationRecord?> getById(String id) async => rows[id];
  @override
  Future<void> sync() async {}
}

const g1FirstTarot = OracleReadingContext(
  sessionId: 'g1-first-session',
  spreadLabel: 'Tek Kart',
  deckId: 'classic',
  deckName: 'Classic',
  readingTitle: 'The Star',
  cardsSummary: 'The Star',
  interpretationSummary: 'Hope after a long night.',
  kind: OracleReadingKind.tarot,
  sourceLabel: 'Tarot',
);

CompanionController g1Companion({
  required G1ScriptedAi ai,
  required G1ThreadRepo repo,
  LocalStorage? storage,
}) {
  final intelligence = IntelligenceLayerService(
    LocalIntelligenceRepository(
      history: MockHistoryRepository(LocalStorage.ephemeral()),
      conversations: repo,
      ritualHistory: RitualHistoryReader(LocalStorage.ephemeral()),
      indexStore: IntelligenceIndexStore(LocalStorage.ephemeral()),
    ),
  );
  final controller = CompanionController(
    CompanionExperienceService(
      conversationRepository: repo,
      intelligence: intelligence,
      memoryService:
          CompanionMemoryService(MemoryService(LocalStorage.ephemeral())),
      ai: ai,
    ),
    CompanionOutputController(
      persistMode: (_) async {},
      readMode: () => OrChatOutputMode.text,
    ),
    storage: storage,
  );
  final now = DateTime.now();
  controller.seedSessionForTest(
    conversation: Conversation(
      id: 'companion_primary',
      title: 'OR',
      topic: ConversationTopic.general,
      messages: [
        AIMessage(
          id: 'welcome',
          role: AIMessageRole.assistant,
          content: 'Welcome.',
          createdAt: now,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    ),
  );
  return controller;
}
