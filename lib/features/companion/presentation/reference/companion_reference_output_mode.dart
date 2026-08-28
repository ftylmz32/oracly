/// Compact YAZILI / SESLİ / SOHBET — never a dashboard row.
library;

import 'package:flutter/material.dart';

import '../../copy/companion_copy.dart';
import '../../models/or_chat_output_mode.dart';
import '../../services/companion_voice_conversation_access.dart';
import '../../voice/or_voice_turn_phase.dart';
import 'companion_reference_output_chip.dart';
import 'companion_reference_output_playback.dart';
import 'companion_reference_voice_turn_status.dart';

class CompanionReferenceOutputMode extends StatelessWidget {
  const CompanionReferenceOutputMode({
    super.key,
    required this.mode,
    required this.onChanged,
    this.speaking = false,
    this.paused = false,
    this.canReplay = false,
    this.voiceAllowed = true,
    this.conversationAllowed = true,
    this.turnPhase,
    this.onStop,
    this.onPauseToggle,
    this.onReplay,
  });

  final OrChatOutputMode mode;
  final ValueChanged<OrChatOutputMode> onChanged;
  final bool speaking;
  final bool paused;
  final bool canReplay;
  final bool voiceAllowed;
  final bool conversationAllowed;
  final OrVoiceTurnPhase? turnPhase;
  final VoidCallback? onStop;
  final VoidCallback? onPauseToggle;
  final VoidCallback? onReplay;

  void _onConversation(BuildContext context) {
    if (conversationAllowed ||
        CompanionVoiceConversationAccess.ensure(context)) {
      onChanged(OrChatOutputMode.conversation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceOut = mode.isVoice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CompanionOutputChip(
              selected: mode == OrChatOutputMode.text,
              label: CompanionCopy.outputText,
              semantics: CompanionCopy.outputText,
              onTap: () => onChanged(OrChatOutputMode.text),
            ),
            CompanionOutputChip(
              selected: mode == OrChatOutputMode.voice,
              label: CompanionCopy.outputVoice,
              semantics: CompanionCopy.outputVoice,
              muted: !voiceAllowed,
              onTap: () => onChanged(OrChatOutputMode.voice),
            ),
            CompanionOutputChip(
              selected: mode == OrChatOutputMode.conversation &&
                  conversationAllowed,
              label: CompanionCopy.outputConversation,
              semantics: conversationAllowed
                  ? CompanionCopy.outputConversation
                  : CompanionCopy.voiceConversationLocked,
              muted: !voiceAllowed || !conversationAllowed,
              onTap: () => _onConversation(context),
            ),
            if (voiceOut && !mode.isConversation)
              CompanionReferenceOutputPlayback(
                speaking: speaking,
                paused: paused,
                canReplay: canReplay,
                onPauseToggle: onPauseToggle,
                onStop: onStop,
                onReplay: onReplay,
              ),
            if (mode.isConversation && conversationAllowed)
              CompanionReferenceOutputPlayback(
                speaking: speaking,
                paused: paused,
                canReplay: canReplay && turnPhase == OrVoiceTurnPhase.ready,
                onPauseToggle: onPauseToggle,
                onStop: onStop,
                onReplay: onReplay,
              ),
          ],
        ),
        if (mode.isConversation && conversationAllowed && turnPhase != null)
          CompanionReferenceVoiceTurnStatus(phase: turnPhase!),
      ],
    );
  }
}
