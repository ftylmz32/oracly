import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/personality/or_response_depth.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/oracle_conversation/services/oracle_ai_message_source.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/models/chat_ai_reply.dart';
import 'package:oracly_new/features/ai/production/models/coffee_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/palm_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_service.dart';

void main() {
  test('OR sends message-relevant continuity as tagged observation evidence', () async {
    final ai = _CaptureAi();
    final source = OracleAiMessageSource(
      ai: ai,
      contextHintFor: (message) async => message.contains('iş')
          ? 'Karar teması Tarot ve Kahve okumalarında tekrar etti.'
          : null,
    );

    final reply = await source.reply(
      context: _tarot(),
      userMessage: 'İşimle ilgili bu karar neden yine karşıma çıkıyor?',
    );

    expect(reply, isNotEmpty);
    expect(ai.lastStyleHint, startsWith('OBSERVATION:'));
    expect(ai.lastStyleHint, contains('Karar teması'));
    expect(ai.lastUserMessage, contains('İşimle'));
  });

  test('OR does not manufacture continuity when no relevant evidence exists', () async {
    final ai = _CaptureAi();
    final source = OracleAiMessageSource(
      ai: ai,
      contextHintFor: (_) async => null,
    );

    await source.reply(
      context: _tarot(),
      userMessage: 'Bu kartın ana mesajı ne?',
    );

    expect(ai.lastStyleHint, isNull);
  });
}

OracleReadingContext _tarot() {
  return const OracleReadingContext(
    sessionId: 'tarot_v2_1',
    kind: OracleReadingKind.tarot,
    sourceLabel: 'Tarot',
    spreadLabel: 'Üç Kart',
    deckId: 'rider-waite',
    deckName: 'Rider-Waite',
    readingTitle: 'Üç Kart Açılımı',
    cardsSummary: 'Two of Swords (Düz) · Eight of Wands (Düz)',
    interpretationSummary: 'Karar ve harekete geçiş arasında bir gerilim var.',
    cardNames: ['Two of Swords', 'Eight of Wands'],
  );
}

class _CaptureAi implements OraclyAiService {
  String? lastStyleHint;
  String? lastUserMessage;

  @override
  bool get isConfigured => true;

  @override
  bool get allowsLocalFallback => false;

  @override
  bool get visionAvailable => true;

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
    lastStyleHint = styleHint;
    lastUserMessage = userMessage;
    return AiOutcome.success(
      const ChatAiReply(
        text: 'Burada karar ile hız arasında aynı anda çalışan iki ayrı iz var; bunu tek bir kesin sonuca bağlamadan okumak daha doğru.',
      ),
    );
  }

  @override
  Future<AiOutcome<ChatAiReply>> chat({
    required String userMessage,
    List<String> priorUser = const [],
    String? styleHint,
    String? personality,
    List<ConversationTurn> turns = const [],
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
  }) {
    throw UnsupportedError('chat');
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
