/// Microphone — quiet presence; brighter only while capturing.
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../copy/companion_copy.dart';
import '../../voice/companion_voice_phase.dart';
import 'companion_reference_tokens.dart';

class CompanionReferenceVoiceSlot extends StatelessWidget {
  const CompanionReferenceVoiceSlot({
    super.key,
    this.phase = CompanionVoicePhase.idle,
    this.onTap,
    this.onCancel,
  });

  final CompanionVoicePhase phase;
  final VoidCallback? onTap;

  /// Long-press while capturing — discard and release the mic.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final size = CompanionReferenceTokens.composerControl;
    final requesting = phase == CompanionVoicePhase.requesting;
    final listening = phase == CompanionVoicePhase.listening;
    final canTap = onTap != null && !requesting;
    final canCancel = listening && onCancel != null;
    final label = requesting
        ? CompanionCopy.voiceRequesting
        : listening
            ? CompanionCopy.voiceListening
            : CompanionCopy.voiceLabel;
    return Semantics(
      button: true,
      enabled: canTap || canCancel,
      label: label,
      hint: canCancel ? CompanionCopy.voiceCancelHint : null,
      customSemanticsActions: canCancel
          ? {
              CustomSemanticsAction(label: CompanionCopy.voiceCancel): onCancel!,
            }
          : null,
      child: GestureDetector(
        onLongPress: canCancel ? onCancel : null,
        child: OraclyPressable(
          onTap: canTap ? onTap : null,
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: OraclyChrome.cardSurface.withValues(
                  alpha: listening ? 0.42 : 0.26,
                ),
                border: Border.all(
                  color: OraclyChrome.gold.withValues(
                    alpha: listening || requesting ? 0.46 : 0.20,
                  ),
                  width: 0.65,
                ),
                boxShadow: listening
                    ? [
                        BoxShadow(
                          color: OraclyChrome.violet.withValues(alpha: 0.22),
                          blurRadius: 12,
                        ),
                        BoxShadow(
                          color: OraclyChrome.gold.withValues(alpha: 0.10),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                size: 20,
                color: OraclyChrome.goldLight.withValues(
                  alpha: listening
                      ? 0.96
                      : requesting
                          ? 0.68
                          : 0.80,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
