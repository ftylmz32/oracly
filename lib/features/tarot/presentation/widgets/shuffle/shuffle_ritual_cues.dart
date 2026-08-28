/// Shuffle ritual SFX + haptic — respects Settings via the feedback gate.
library;

import '../../../../../core/audio/oracly_feedback_gate.dart';
import '../../../../../core/audio/oracly_sound_hooks.dart';
import '../../../../../shared/widgets/oracly_pressable.dart';

abstract final class ShuffleRitualCues {
  ShuffleRitualCues._();

  static void begin() {
    OraclySoundHooks.play(OraclySoundHook.ambientTarot);
    OraclyFeedbackGate.cardMove();
    OraclyTouchFeedback.acknowledge();
  }

  static void midShuffle() {
    OraclyFeedbackGate.cardMove();
  }

  static void cut() {
    OraclyFeedbackGate.cardMove();
    OraclyTouchFeedback.selection();
  }
}
