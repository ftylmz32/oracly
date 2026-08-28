/// Shared OR phrases for conversations — realistic warmth, never clingy.
library;

import '../../features/premium/models/personalization_models.dart';
import 'or_conversation_opening.dart';
import 'or_living_voice.dart';
import 'or_personality.dart';

abstract final class OrConversationVoice {
  OrConversationVoice._();

  static String intro({
    required AiPersonality personality,
    required DateTime moment,
    String? name,
  }) {
    return OrConversationOpening.line(
      personality: personality.name,
      moment: moment,
      name: name,
    );
  }

  static String outro({required DateTime moment}) =>
      OrLivingVoice.closing(moment: moment);

  static String readingOpening({required DateTime moment}) =>
      OrLivingVoice.aside(moment: moment);

  static String readingClosing({required DateTime moment}) =>
      OrLivingVoice.closing(moment: moment);

  static String systemVoiceHint(AiPersonality personality) =>
      OrPersonality.voiceDescriptor(personality);
}
