/// P0-09 — local chat/OR replies cannot masquerade as unlabeled live AI.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/ai_source_copy.dart';
import 'package:oracly_new/core/copy/conversation_copy.dart';
import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/core/modules/oracly_feature_registry.dart';
import 'package:oracly_new/features/ai/domain/models/ai_message.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/oracle_conversation/repositories/oracle_conversation_repository.dart';
import 'package:oracly_new/features/ai/oracle_conversation/services/oracle_ai_message_source.dart';
import 'package:oracly_new/features/ai/oracle_conversation/widgets/or_ask_button.dart';
import 'package:oracly_new/features/ai/presentation/widgets/ai_source_footnote.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/models/chat_ai_reply.dart';
import 'package:oracly_new/features/ai/production/models/coffee_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/core/personality/or_response_depth.dart';
import 'package:oracly_new/features/ai/production/models/palm_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_service.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';
import 'package:oracly_new/features/companion/data/companion_record_mapper.dart';
import 'package:oracly_new/features/companion/models/conversation.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_message_bubble.dart';
import 'package:oracly_new/features/companion/services/companion_ai_bridge.dart';
import 'package:oracly_new/features/home/reference/home_reference_modules.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Home chat lives in registry, not the six-tile discovery grid', () {
    expect(
      HomeReferenceModules.list().map((m) => m.id),
      isNot(contains(OraclyFeatureId.aiChat)),
    );
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.aiChat)?.title,
      'OR',
    );
  });

  test('local oracle/chat cannot be labeled as live AI', () async {
    const ai = UnconfiguredOraclyAiService(allowsLocalFallback: true);
    final source = OracleAiMessageSource(ai: ai);
    expect(source.fromAi, isFalse);
    expect(
      await CompanionAiBridge(ai).tryLiveOrFailClosed(userMessage: 'Merhaba'),
      isNull,
    );
    final text = await source.reply(
      context: _tarot(),
      userMessage: 'Bu kart ne anlatıyor?',
    );
    expect(text.trim(), isNotEmpty);
    expect(AiSourceCopy.footnote(fromAi: source.fromAi), AiSourceCopy.sourceLocal);
    expect(AiSourceCopy.orAskFootnote(fromAi: false), AiSourceCopy.orAskLocal);
    expect(AiSourceCopy.sourceLocal.toLowerCase(), contains('yerel'));
    expect(AiSourceCopy.sourceLocal.toLowerCase(), contains('yapay zek'));
    expect(AiSourceCopy.sourceLocal.toLowerCase(), isNot(contains('or yanıtı')));
  });

  test('configured proxy/AI keeps the live OR label', () async {
    final ai = _LiveAi();
    final source = OracleAiMessageSource(ai: ai);
    expect(source.fromAi, isTrue);
    expect(
      await CompanionAiBridge(ai).tryLiveOrFailClosed(userMessage: 'Merhaba'),
      'Canlı sakin bir yanıt.',
    );
    final reply = await source.reply(
      context: _tarot(),
      userMessage: 'Bu kart ne anlatıyor?',
    );
    expect(reply, 'Canlı OR yanıt metni.');
    expect(AiSourceCopy.footnote(fromAi: true), AiSourceCopy.sourceLive);
    expect(AiSourceCopy.orAskFootnote(fromAi: true), AiSourceCopy.orAskLive);
    expect(AiSourceCopy.sourceLive, 'OR yanıtı.');
  });

  test('oracle repository stamps local vs live metadata', () async {
    final localRepo = MockOracleConversationRepository(
      source: OracleAiMessageSource(
        ai: const UnconfiguredOraclyAiService(allowsLocalFallback: true),
      ),
    );
    final ctx = _tarot();
    final localConv = await localRepo.startConversation(ctx);
    final local = await localRepo.sendMessage(
      conversationId: localConv.id,
      userMessage: 'Bu kart ne anlatıyor?',
      context: ctx,
    );
    expect(local.modelId, 'or-local');
    expect(AiSourceCopy.isLocal(local.message.metadata), isTrue);
    expect(AiSourceCopy.isLive(local.message.metadata), isFalse);

    final liveRepo = MockOracleConversationRepository(
      source: OracleAiMessageSource(ai: _LiveAi()),
    );
    final liveConv = await liveRepo.startConversation(ctx);
    final live = await liveRepo.sendMessage(
      conversationId: liveConv.id,
      userMessage: 'Bu kart ne anlatıyor?',
      context: ctx,
    );
    expect(live.modelId, 'or-live');
    expect(AiSourceCopy.isLive(live.message.metadata), isTrue);
  });

  test('companion mapper keeps source metadata', () {
    final now = DateTime(2026, 8, 10);
    final conversation = Conversation(
      id: 'c1',
      title: 'OR',
      topic: ConversationTopic.general,
      messages: [
        AIMessage(
          id: 'a1',
          role: AIMessageRole.assistant,
          content: 'Yerel yansıma metni.',
          createdAt: now,
          metadata: AiSourceCopy.tag(fromAi: false),
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );
    final roundTrip = CompanionRecordMapper.fromRecord(
      CompanionRecordMapper.toRecord(conversation),
    );
    expect(AiSourceCopy.isLocal(roundTrip.messages.single.metadata), isTrue);
  });

  testWidgets('OR bubbles never show source/transport labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              CompanionReferenceMessageBubble(
                live: true,
                message: AIMessage(
                  id: 'a1',
                  role: AIMessageRole.assistant,
                  content: 'Sakin bir yansıma.',
                  createdAt: DateTime(2026, 8, 10),
                  metadata: AiSourceCopy.tag(fromAi: false),
                ),
              ),
              CompanionReferenceMessageBubble(
                live: true,
                message: AIMessage(
                  id: 'a2',
                  role: AIMessageRole.assistant,
                  content: 'Canlı model yanıtı.',
                  createdAt: DateTime(2026, 8, 10),
                  metadata: AiSourceCopy.tag(fromAi: true),
                ),
              ),
              const AiSourceFootnote(fromAi: false, orAsk: true),
              const OrAskButton(
                readingContext: OracleReadingContext(
                  sessionId: 't1',
                  kind: OracleReadingKind.tarot,
                  sourceLabel: 'Tarot',
                  spreadLabel: 'Tek Kart',
                  deckId: 'classic',
                  deckName: 'Classic',
                  readingTitle: 'Tek Kart',
                  cardsSummary: 'Deli',
                  interpretationSummary: 'Başlangıç.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Sakin bir yansıma.'), findsOneWidget);
    expect(find.text('Canlı model yanıtı.'), findsOneWidget);
    expect(find.text(AiSourceCopy.sourceLocal), findsNothing);
    expect(find.text(AiSourceCopy.sourceLive), findsNothing);
    // OrAsk surface may still label honesty outside the OR thread.
    expect(find.text(AiSourceCopy.orAskLocal), findsOneWidget);
    expect(find.text(ConversationCopy.askOr), findsOneWidget);
    expect(find.text('AI Sohbet'), findsNothing);
  });

  testWidgets('live bubble keeps conversation body only', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CompanionReferenceMessageBubble(
          live: true,
          message: AIMessage(
            id: 'a2',
            role: AIMessageRole.assistant,
            content: 'Canlı model yanıtı.',
            createdAt: DateTime(2026, 8, 10),
            metadata: AiSourceCopy.tag(fromAi: true),
          ),
        ),
      ),
    );
    expect(find.text('Canlı model yanıtı.'), findsOneWidget);
    expect(find.text(AiSourceCopy.sourceLive), findsNothing);
    expect(find.text(AiSourceCopy.sourceLocal), findsNothing);
  });
}

OracleReadingContext _tarot() {
  return const OracleReadingContext(
    sessionId: 'tarot_1',
    kind: OracleReadingKind.tarot,
    sourceLabel: 'Tarot',
    spreadLabel: 'Tek Kart',
    deckId: 'rider-waite',
    deckName: 'Rider-Waite',
    readingTitle: 'Tek Kart',
    cardsSummary: 'The Star (Düz)',
    interpretationSummary: 'Umut ve sakin duruş.',
    cardNames: ['The Star'],
  );
}

class _LiveAi implements OraclyAiService {
  @override
  bool get isConfigured => true;

  @override
  bool get allowsLocalFallback => false;

  @override
  bool get visionAvailable => true;

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
      AiOutcome.success(const ChatAiReply(text: 'Canlı sakin bir yanıt.'));

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
      AiOutcome.success(const ChatAiReply(text: 'Canlı OR yanıt metni.'));

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
