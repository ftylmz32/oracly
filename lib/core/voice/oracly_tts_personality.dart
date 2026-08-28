/// Personality → device speech rate / pitch — calm and warm, never shouty.
library;

import '../../features/premium/models/personalization_models.dart';

abstract final class OraclyTtsPersonality {
  OraclyTtsPersonality._();

  static double rate(AiPersonality personality) => switch (personality) {
        AiPersonality.gentle => 0.48,
        AiPersonality.mystical => 0.50,
        AiPersonality.poetic => 0.51,
        AiPersonality.direct => 0.53,
      };

  static double pitch(AiPersonality personality) => switch (personality) {
        AiPersonality.gentle => 0.98,
        AiPersonality.mystical => 0.96,
        AiPersonality.poetic => 0.98,
        AiPersonality.direct => 0.99,
      };

  static double volume(AiPersonality personality) => switch (personality) {
        AiPersonality.gentle => 0.82,
        AiPersonality.mystical => 0.78,
        AiPersonality.poetic => 0.84,
        AiPersonality.direct => 0.86,
      };
}
