/// Quiet turn status — conversation rhythm, never a walkie-talkie meter.
library;

import 'package:flutter/material.dart';

import '../../../../core/accessibility/oracly_a11y.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/companion_copy.dart';
import '../../voice/or_voice_turn_phase.dart';

class CompanionReferenceVoiceTurnStatus extends StatelessWidget {
  const CompanionReferenceVoiceTurnStatus({
    super.key,
    required this.phase,
  });

  final OrVoiceTurnPhase phase;

  @override
  Widget build(BuildContext context) {
    final line = switch (phase) {
      OrVoiceTurnPhase.ready => CompanionCopy.voiceTurnReady,
      OrVoiceTurnPhase.listening => CompanionCopy.voiceTurnListening,
      OrVoiceTurnPhase.settling => CompanionCopy.voiceTurnSettling,
      OrVoiceTurnPhase.thinking => CompanionCopy.voiceTurnThinking,
      OrVoiceTurnPhase.speaking => CompanionCopy.voiceTurnSpeaking,
    };
    return Semantics(
      liveRegion: true,
      label: line,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.s8),
        child: Text(
          line,
          style: ReadingTypography.micro(
            color: OraclyChrome.cream.withValues(
              alpha: OraclyA11y.secondaryCream,
            ),
          ),
        ),
      ),
    );
  }
}
