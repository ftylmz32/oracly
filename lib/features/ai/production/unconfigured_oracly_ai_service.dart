/// Honest unconfigured AI — typed errors, never fake copy.
library;

import '../../../core/personality/or_response_depth.dart';
import 'ai_failure.dart';
import 'ai_outcome.dart';
import 'contexts/reading_ai_context.dart';
import 'models/chat_ai_reply.dart';
import 'models/coffee_ai_analysis.dart';
import 'models/conversation_turn.dart';
import 'models/dream_ai_analysis.dart';
import 'models/palm_ai_analysis.dart';
import 'models/tarot_ai_analysis.dart';
import 'oracly_ai_service.dart';

class UnconfiguredOraclyAiService implements OraclyAiService {
  const UnconfiguredOraclyAiService({this.allowsLocalFallback = false});

  @override
  final bool allowsLocalFallback;

  @override
  bool get isConfigured => false;

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
      AiOutcome.failure(AiFailure.noConfiguration());

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
      AiOutcome.failure(AiFailure.noConfiguration());

  @override
  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(
    DreamAiContext context,
  ) async =>
      AiOutcome.failure(AiFailure.noConfiguration());

  @override
  Future<AiOutcome<TarotAiAnalysis>> analyzeTarot(
    TarotAiRequestContext context,
  ) async =>
      AiOutcome.failure(AiFailure.noConfiguration());

  @override
  Future<AiOutcome<CoffeeAiAnalysis>> analyzeCoffee({
    required List<int> imageBytes,
    required String mimeType,
  }) async =>
      AiOutcome.failure(
        AiFailure.imageAnalysisUnavailable(feature: AiAnalysisFeature.coffee),
      );

  @override
  Future<AiOutcome<PalmAiAnalysis>> analyzePalm({
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
  }) async =>
      AiOutcome.failure(
        AiFailure.imageAnalysisUnavailable(feature: AiAnalysisFeature.palm),
      );
}
