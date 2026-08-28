/// Selects only response-relevant OR context — never dumps memory.
library;

import '../../ai/production/models/conversation_turn.dart';
import '../models/reflection_context.dart';
import 'or_context_selection_engine.dart';

/// Facade over [OrContextSelectionEngine] — keeps call sites stable.
abstract final class CompanionContextSelect {
  CompanionContextSelect._();

  /// Live styleHint: relevant layers only. No full profile or memory dump.
  static String assemble({
    required String userMessage,
    required List<ConversationTurn> turns,
    String? discoveryHint,
    String? proactiveAcknowledgment,
    ReflectionContext? reflection,
  }) {
    final ctx = reflection ??
        ReflectionContext(
          proactiveAcknowledgment: proactiveAcknowledgment,
        );
    return OrContextSelectionEngine.styleHint(
      currentMessage: userMessage,
      recentMessages: turns,
      fullHistory: turns,
      reflection: ctx,
      discoveryHint: discoveryHint,
      featureHandoff: proactiveAcknowledgment,
    );
  }
}
