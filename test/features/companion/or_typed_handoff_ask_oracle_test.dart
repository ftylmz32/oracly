/// Typed OracleReadingContext handoff + askOracle for live Companion OR.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_ai_conversation_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/intelligence/data/intelligence_index_store.dart';
import 'package:oracly_new/core/intelligence/data/local_intelligence_repository.dart';
import 'package:oracly_new/core/intelligence/data/ritual_history_reader.dart';
import 'package:oracly_new/core/intelligence/services/intelligence_layer_service.dart';
import 'package:oracly_new/core/personality/or_response_depth.dart';
import 'package:oracly_new/features/ai/domain/models/ai_message.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/contexts/oracle_context_mapper.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/models/chat_ai_reply.dart';
import 'package:oracly_new/features/ai/production/models/coffee_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/palm_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_service.dart';
import 'package:oracly_new/features/companion/controllers/companion_controller.dart';
import 'package:oracly_new/features/companion/controllers/companion_output_controller.dart';
import 'package:oracly_new/features/companion/models/companion_send_result.dart';
import 'package:oracly_new/features/companion/models/companion_state.dart';
import 'package:oracly_new/features/companion/models/conversation.dart';
import 'package:oracly_new/features/companion/models/insight_request.dart';
import 'package:oracly_new/features/companion/models/or_chat_output_mode.dart';
import 'package:oracly_new/features/companion/models/reflection_context.dart';
import 'package:oracly_new/features/companion/services/companion_ai_bridge.dart';
import 'package:oracly_new/features/companion/services/companion_experience_service.dart';
import 'package:oracly_new/features/companion/services/companion_responder.dart';
import 'package:oracly_new/features/companion/models/companion_response.dart';
import 'package:oracly_new/features/companion/services/or_chat_handoff.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';

void main() {
  setUp(OrChatHandoffBuffer.clear);

  test('buffer stores typed context and derives compact', () {
    const ctx = OracleReadingContext(
      sessionId: 's1',
      spreadLabel: 'Tek Kart',
      deckId: 'classic',
      deckName: 'Classic',
      readingTitle: 'Kart',
      cardsSummary: 'Ay',
      interpretationSummary: 'Kisa ozet.',
      kind: OracleReadingKind.tarot,
      sourceLabel: 'Tarot',
    );
    OrChatHandoffBuffer.offer(ctx);
    final taken = OrChatHandoffBuffer.take();
    expect(taken, isNotNull);
    expect(taken!.kind, OracleReadingKind.tarot);
    expect(taken.sessionId, 's1');
    expect(OrChatHandoff.compact(taken), contains('Tarot'));
    expect(OrChatHandoffBuffer.take(), isNull);
  });

  test('palm mapper produces PalmAiContext not Coffee', () {
    final ctx = OracleReadingContextSources.palm(
      PalmReading(
        id: 'p1',
        createdAt: DateTime(2026, 8, 9),
        hand: PalmHand.right,
        overall: 'Avucta sakin bir hat.',
        heartLine: 'Yumusak bir egri.',
        headLine: 'Net bir cizgi.',
        lifeLine: 'Derin bir yay.',
        fateLine: 'Ince bir yon.',
        takeaway: 'Sakin kal.',
        symbols: const ['yildiz'],
        themes: const ['yakinlik', 'denge'],
      ),
    );
    final ai = OracleContextMapper.fromOracle(ctx);
    expect(ai, isA<PalmAiContext>());
    expect(ai.kindId, 'palm');
    final palm = ai as PalmAiContext;
    expect(palm.sessionId, 'p1');
    expect(palm.overall, contains('sakin'));
    expect(palm.handLabel, isNotEmpty);
    expect(palm.symbols, contains('yildiz'));
    expect(palm.themes, contains('yakinlik'));
    expect(palm.takeaway, contains('Sakin'));
    expect(palm.heartLine, contains('Yumusak'));
    expect(palm, isNot(isA<CoffeeAiContext>()));
  });

  test('typed context reaches askOracle on the live bridge', () async {
    final ai = _TrackingAi();
    final bridge = CompanionAiBridge(ai);
    const ctx = OracleReadingContext(
      sessionId: 'coffee-1',
      spreadLabel: '',
      deckId: '',
      deckName: '',
      readingTitle: 'Kahve',
      cardsSummary: '',
      interpretationSummary: 'Duruluk.',
      kind: OracleReadingKind.coffee,
      sourceLabel: 'Kahve',
    );
    final text = await bridge.tryLive(
      userMessage: 'Bu fal ne diyor?',
      readingContext: ctx,
    );
    expect(text, isNotNull);
    expect(ai.askOracleCalls, 1);
    expect(ai.chatCalls, 0);
    expect(ai.lastOracleKind, 'coffee');
  });

  test('no-context still uses chat', () async {
    final ai = _TrackingAi();
    final text = await CompanionAiBridge(ai).tryLive(userMessage: 'Merhaba');
    expect(text, isNotNull);
    expect(ai.chatCalls, 1);
    expect(ai.askOracleCalls, 0);
  });

  test('duplicate send blocked while busy; stale reply ignored', () async {
    final storage = LocalStorage.ephemeral();
    final conversations = LocalAiConversationRepository(storage);
    final intelligence = IntelligenceLayerService(
      LocalIntelligenceRepository(
        history: MockHistoryRepository(storage),
        conversations: conversations,
        ritualHistory: RitualHistoryReader(storage),
        indexStore: IntelligenceIndexStore(storage),
      ),
    );
    final deferred = _DeferredExperience(
      conversationRepository: conversations,
      intelligence: intelligence,
    );
    final output = CompanionOutputController(
      persistMode: (_) async {},
      readMode: () => OrChatOutputMode.text,
    );
    final controller = CompanionController(deferred, output);
    final now = DateTime.now();
    controller.seedSessionForTest(
      conversation: Conversation(
        id: 'c1',
        title: 'OR',
        topic: ConversationTopic.general,
        messages: [
          AIMessage(
            id: 'welcome_1',
            role: AIMessageRole.assistant,
            content: 'Hos geldin.',
            createdAt: now,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      ),
      readingContext: const OracleReadingContext(
        sessionId: 't1',
        spreadLabel: 'Tek',
        deckId: 'd',
        deckName: 'D',
        readingTitle: 'T',
        cardsSummary: 'C',
        interpretationSummary: 'Ozet',
        kind: OracleReadingKind.tarot,
        sourceLabel: 'Tarot',
      ),
    );

    final first = controller.send('Ilk soru');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(controller.state.phase, CompanionPhase.thinking);
    expect(deferred.calls, 1);
    expect(deferred.lastReading?.kind, OracleReadingKind.tarot);

    await controller.send('Ikinci soru');
    expect(deferred.calls, 1);

    controller.invalidateSendForTest();
    deferred.complete('Eski yanit — yok sayilmali.');
    await first;

    expect(controller.state.phase, CompanionPhase.thinking);
    expect(
      controller.state.conversation!.messages.any(
        (m) => m.content.contains('Eski yanit'),
      ),
      isFalse,
    );

    controller.dispose();
  });
}

class _TrackingAi implements OraclyAiService {
  int chatCalls = 0;
  int askOracleCalls = 0;
  String? lastOracleKind;

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
    return AiOutcome.success(const ChatAiReply(text: 'Sakin bir yanit.'));
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
  }) async {
    askOracleCalls++;
    lastOracleKind = context.kindId;
    return AiOutcome.success(const ChatAiReply(text: 'Okuma baglamli yanit.'));
  }

  @override
  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(DreamAiContext context) {
    throw UnsupportedError('dream');
  }

  @override
  Future<AiOutcome<CoffeeAiAnalysis>> analyzeCoffee({
    required List<int> imageBytes,
    required String mimeType,
  }) {
    throw UnsupportedError('coffee');
  }

  @override
  Future<AiOutcome<PalmAiAnalysis>> analyzePalm({
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
  }) {
    throw UnsupportedError('palm');
  }
}

class _DeferredExperience extends CompanionExperienceService {
  _DeferredExperience({
    required super.conversationRepository,
    required super.intelligence,
  });

  final Completer<String> _gate = Completer<String>();
  int calls = 0;
  OracleReadingContext? lastReading;

  void complete(String text) {
    if (!_gate.isCompleted) _gate.complete(text);
  }

  @override
  Future<CompanionSendResult> send({
    required Conversation conversation,
    required ReflectionContext context,
    required InsightRequest request,
    OracleReadingContext? readingContext,
  }) async {
    calls++;
    lastReading = readingContext;
    final body = await _gate.future;
    final now = DateTime.now();
    final assistant = AIMessage(
      id: 'msg_a_',
      role: AIMessageRole.assistant,
      content: body,
      createdAt: now,
    );
    return CompanionSendResult(
      conversation: conversation.copyWith(
        messages: [...conversation.messages, assistant],
        updatedAt: now,
      ),
      response: CompanionResponse(body: body),
      fromAi: true,
    );
  }
}
