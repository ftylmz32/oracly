/// Single AI service for chat, OR'a Sor, dream, and coffee vision.
library;

import '../../../core/personality/or_response_depth.dart';
import 'ai_outcome.dart';
import 'contexts/reading_ai_context.dart';
import 'models/chat_ai_reply.dart';
import 'models/coffee_ai_analysis.dart';
import 'models/conversation_turn.dart';
import 'models/dream_ai_analysis.dart';
import 'models/palm_ai_analysis.dart';

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

  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(DreamAiContext context);

  /// Real grounded tarot reading — [cards] carry name/position/reversed
  /// evidence only; never invented server- or client-side.
  Future<AiOutcome<ChatAiReply>> generateTarotReading({
    required List<Map<String, dynamic>> cards,
    required String spreadLabel,
    String? userQuestion,
    String? readingTheme,
    Map<String, dynamic>? journeyHints,
  });

  Future<AiOutcome<CoffeeAiAnalysis>> analyzeCoffee({
    required List<int> imageBytes,
    required String mimeType,
    Map<String, dynamic>? personalization,
  });

  Future<AiOutcome<PalmAiAnalysis>> analyzePalm({
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
    Map<String, dynamic>? personalization,
  });
}

/// Optional capability: Coffee/Palm analysis using ONLY the server-staged
/// image (no local bytes) — for resuming a reading operation after the
/// client's local image state was lost (app restart, controller
/// disposal). Implemented by the real production service only; callers
/// check `is OraclyStagedImageAiService` before use.
abstract class OraclyStagedImageAiService {
  Future<AiOutcome<CoffeeAiAnalysis>> analyzeCoffeeStaged({
    required String operationId,
    required String mimeType,
    Map<String, dynamic>? personalization,
  });

  Future<AiOutcome<PalmAiAnalysis>> analyzePalmStaged({
    required String operationId,
    required String mimeType,
    required String hand,
    Map<String, dynamic>? personalization,
  });
}

/// Optional production capability that pauses Coffee/Palm after verified
/// visual observation, retrieves only matching local memory, then resumes the
/// writer. Implementations must continue with no memory if retrieval fails.
abstract class OraclyEvidenceMemoryAiService {
  Future<AiOutcome<CoffeeAiAnalysis>> analyzeCoffeeWithEvidenceMemory({
    required List<int> imageBytes,
    required String mimeType,
    required Map<String, dynamic>? basePersonalization,
    required String? Function(List<String> themes) memorySummary,
  });

  Future<AiOutcome<PalmAiAnalysis>> analyzePalmWithEvidenceMemory({
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
    required Map<String, dynamic>? basePersonalization,
    required String? Function(List<String> themes) memorySummary,
  });

  Future<AiOutcome<CoffeeAiAnalysis>> analyzeCoffeeStagedWithEvidenceMemory({
    required String operationId,
    required String mimeType,
    required Map<String, dynamic>? basePersonalization,
    required String? Function(List<String> themes) memorySummary,
  });

  Future<AiOutcome<PalmAiAnalysis>> analyzePalmStagedWithEvidenceMemory({
    required String operationId,
    required String mimeType,
    required String hand,
    required Map<String, dynamic>? basePersonalization,
    required String? Function(List<String> themes) memorySummary,
  });
}
