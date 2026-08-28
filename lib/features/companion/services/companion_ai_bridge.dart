/// AI Sohbet live path — configured AI only, never fake GPT copy.
library;

import '../../../core/honesty/or_response_grounding.dart';
import '../../../core/personality/or_response_depth.dart';
import '../../../core/reading/ai_output_quality_context.dart';
import '../../../core/reading/ai_output_quality_kind.dart';
import '../../../core/reading/ai_output_quality_runner.dart';
import '../../ai/oracle_conversation/models/oracle_reading_context.dart';
import '../../ai/production/ai_failure.dart';
import '../../ai/production/ai_request_exception.dart';
import '../../ai/production/contexts/oracle_context_mapper.dart';
import '../../ai/production/models/conversation_turn.dart';
import '../../ai/production/oracly_ai_service.dart';
import 'companion_thread_memory.dart';
import 'contextual_followup_policy.dart';
import 'or_response_finalize.dart';

class CompanionAiBridge {
  const CompanionAiBridge(this._ai);

  final OraclyAiService _ai;

  bool get isConfigured => _ai.isConfigured;

  bool get allowsLocalFallback => _ai.allowsLocalFallback;

  Future<String?> tryLive({
    required String userMessage,
    List<String> priorUser = const [],
    String? styleHint,
    String? personality,
    List<ConversationTurn> turns = const [],
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
    OracleReadingContext? readingContext,
  }) async {
    if (!_ai.isConfigured) return null;
    // Tagged FACT/OBSERVATION/INTERPRETATION only — never "any styleHint".
    final memoryEvidence =
        OrResponseGrounding.hasContextEvidence(styleHint) ||
            readingContext != null;
    final thread = CompanionThreadMemory.read(turns, userMessage);
    final followUp = ContextualFollowUpPolicy.evaluate(
      userMessage: userMessage,
      thread: thread,
    );
    try {
      final fallback = AiOutputQualityRunner.fallbackFor(
        AiOutputQualityKind.companion,
      );
      final text = await AiOutputQualityRunner.runText(
        operationId: readingContext == null
            ? 'companion.chat'
            : 'companion.askOracle',
        kind: AiOutputQualityKind.companion,
        context: AiOutputQualityContext(hasMemoryEvidence: memoryEvidence),
        fallback: fallback,
        transform: (raw) => OrResponseFinalize.apply(
          raw,
          userMessage: userMessage,
          hasMemoryEvidence: memoryEvidence,
          allowTrailingQuestion: followUp.allowTrailingQuestion,
          depth: depth,
          spoken: spoken,
          priorAssistant: thread.lastAssistant,
        ),
        generate: (attempt) async {
          final outcome = readingContext != null
              ? await _ai.askOracle(
                  context: OracleContextMapper.fromOracle(readingContext),
                  userMessage: userMessage,
                  priorUser: priorUser,
                  turns: turns,
                  styleHint: styleHint,
                  personality: personality,
                  depth: depth,
                  spoken: spoken,
                )
              : await _ai.chat(
                  userMessage: userMessage,
                  priorUser: priorUser,
                  styleHint: styleHint,
                  personality: personality,
                  turns: turns,
                  depth: depth,
                  spoken: spoken,
                );
          return outcome.when(
            success: (reply) => reply.text,
            error: (failure) => throw AiRequestException(failure),
          );
        },
      );
      final trimmed = text.trim();
      if (trimmed.isEmpty) {
        throw AiRequestException(AiFailure.invalidResponse());
      }
      // Quality exhausted → honest invalid response, never live-tagged fallback.
      if (trimmed == fallback.trim()) {
        throw AiRequestException(AiFailure.invalidResponse());
      }
      return text;
    } on AiRequestException {
      rethrow;
    }
  }

  /// Live text, or null when a development local responder may run.
  Future<String?> tryLiveOrFailClosed({
    required String userMessage,
    List<String> priorUser = const [],
    String? styleHint,
    String? personality,
    List<ConversationTurn> turns = const [],
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
    OracleReadingContext? readingContext,
  }) async {
    if (_ai.isConfigured) {
      return tryLive(
        userMessage: userMessage,
        priorUser: priorUser,
        styleHint: styleHint,
        personality: personality,
        turns: turns,
        depth: depth,
        spoken: spoken,
        readingContext: readingContext,
      );
    }
    if (_ai.allowsLocalFallback) return null;
    throw AiRequestException(AiFailure.noConfiguration());
  }
}
