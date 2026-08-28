/// Low-mood openings — a precise question, never a therapist script.
library;

import '../../../core/l10n/l10n.dart';
import '../../../core/personality/or_emotional_intelligence.dart';
import 'companion_conversation_copy.dart';
import 'companion_intent.dart';

abstract final class CompanionMoodCopy {
  CompanionMoodCopy._();

  static bool looksLow(String text) {
    if (CompanionIntent.isLow(text)) return true;
    return OrEmotionalIntelligence.sense(text)
        .signals
        .contains(OrEmotionalSignal.sadness);
  }

  static String openUp(String? personality) {
    final name = CompanionConversationCopy.style(personality).name;
    return OraclyL10n.t('or.mood.$name');
  }
}
