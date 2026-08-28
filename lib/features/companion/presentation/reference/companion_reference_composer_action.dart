/// Trailing composer — mic stays secondary; Send is always visible.
library;

import 'package:flutter/material.dart';

import '../../voice/companion_voice_phase.dart';
import 'companion_reference_send_button.dart';
import 'companion_reference_voice_slot.dart';

class CompanionReferenceComposerAction extends StatelessWidget {
  const CompanionReferenceComposerAction({
    super.key,
    required this.controller,
    required this.voicePhase,
    required this.enabled,
    required this.onSend,
    required this.onMicTap,
    this.onMicCancel,
  });

  final TextEditingController controller;
  final CompanionVoicePhase voicePhase;
  final bool enabled;
  final VoidCallback onSend;
  final VoidCallback? onMicTap;
  final VoidCallback? onMicCancel;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.trim().isNotEmpty ||
            !value.composing.isCollapsed;
        final listening = voicePhase == CompanionVoicePhase.listening ||
            voicePhase == CompanionVoicePhase.requesting;
        final canSend = hasText && enabled;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CompanionReferenceVoiceSlot(
              phase: voicePhase,
              onTap: enabled || listening ? onMicTap : null,
              onCancel: onMicCancel,
            ),
            const SizedBox(width: 6),
            CompanionReferenceSendButton(
              onTap: canSend ? onSend : null,
              enabled: canSend,
            ),
          ],
        );
      },
    );
  }
}
