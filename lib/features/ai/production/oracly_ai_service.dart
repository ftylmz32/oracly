/// Single AI service for chat, OR'a Sor, dream, and reading analysis.
library;

import '../../../core/personality/or_response_depth.dart';
import 'ai_outcome.dart';
import 'contexts/reading_ai_context.dart';
import 'models/chat_ai_reply.dart';
import 'models/coffee_ai_analysis.dart';
import 'models/conversation_turn.dart';
import 'models/dream_ai_analysis.dart';
import 'models/palm_ai_analysis.dart';
import 'models/tarot_ai_analysis.dart';

abstract class OraclyAiService {
  bool get isConfigured;

  bool get visionAvailable;

  /// Dev/debug catalogue responders only. Always false in production.
  bool get allowsLocalFallback;

  Future<AiOutcome<ChatAiReply>> chat({
    required String userMessage,
    List<String> priorUser = const [],
    String? styleHint,
    String? personality,
    List<ConversationTurn> turns = const [],
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
  });

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
  });

  Future<AiOutcome<TarotAiAnalysis>> analyzeTarot(
    TarotAiAnalysisRequest request,
  );

  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(DreamAiContext context);

  Future<AiOutcome<CoffeeAiAnalysis>> analyzeCoffee({
    required List<int> imageBytes,
    required String mimeType,
  });

  Future<AiOutcome<PalmAiAnalysis>> analyzePalm({
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
  });
}
