/// Listen → answer in proportion. Conversational, never a FAQ dump.
library;

import '../../../core/l10n/l10n.dart';
import '../../../core/personality/or_response_depth.dart';
import '../../../features/ai/services/followup_question_resolve.dart';
import '../../ai/production/models/conversation_turn.dart';
import '../models/companion_response.dart';
import '../models/insight_request.dart';
import '../models/reflection_context.dart';
import 'companion_thread_memory.dart';
import 'companion_turn_router.dart';
import 'contextual_followup_policy.dart';
import 'or_context_bucket_helpers.dart';
import 'or_response_finalize.dart';

export '../models/companion_response.dart';

class CompanionResponder {
  const CompanionResponder();

  CompanionResponse respond({
    required InsightRequest request,
    required ReflectionContext context,
    List<String> priorUser = const [],
    List<ConversationTurn> turns = const [],
    String? personality,
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
  }) {
    final thread = CompanionThreadMemory.read(turns, request.text);
    final text = FollowupQuestionResolve.expand(
      current: request.text,
      priorUser: priorUser,
      sameThread: thread.continuing || thread.answeringPrompt,
      switched: thread.switched,
    );
    final followUp = ContextualFollowUpPolicy.evaluate(
      userMessage: request.text,
      thread: thread,
    );
    final raw = CompanionTurnRouter.answer(
      lower: text.toLowerCase(),
      request: request,
      context: context,
      thread: thread,
      personality: personality,
      hasHistory: turns.isNotEmpty,
      depth: depth,
    );
    final recall = text.toLowerCase().contains('hatırl') ||
        text.toLowerCase().contains('hatirl') ||
        text.toLowerCase().contains('remember') ||
        text.toLowerCase().contains('daha önce') ||
        text.toLowerCase().contains('daha once');
    final saved = OrContextBucketHelpers.relevantSaved(
      context.savedMemories,
      request.text,
    );
    final body = OrResponseFinalize.apply(
      _unrepeat(raw, thread.lastAssistant),
      userMessage: request.text,
      hasMemoryEvidence: recall && saved != null,
      allowTrailingQuestion: followUp.allowTrailingQuestion,
      depth: depth,
      spoken: spoken,
      priorAssistant: thread.lastAssistant,
    );
    return CompanionResponse(body: body);
  }

  static String _unrepeat(String body, String? last) {
    if (last == null || last.trim().isEmpty) return body;
    final a = body.trim().toLowerCase();
    final b = last.trim().toLowerCase();
    if (a == b) return OraclyL10n.t('or.repeat');
    if (a.length >= 18 && b.startsWith(a.substring(0, 18))) {
      return OraclyL10n.t('or.angle');
    }
    return body;
  }
}
