/// Composer dock — conversation controls only (no source/transport labels).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../providers/companion_providers.dart';
import '../../services/companion_voice_conversation_access.dart';
import '../../voice/companion_voice_phase.dart';
import '../../voice/or_voice_turn_phase.dart';
import 'companion_reference_actions.dart';
import 'companion_reference_input_bar.dart';
import 'companion_reference_live_transcript.dart';
import 'companion_reference_notice.dart';
import 'companion_reference_output_mode.dart';
import 'companion_reference_thinking.dart';
import 'companion_reference_tokens.dart';
import 'companion_reference_transcript_review.dart';
import 'companion_reference_voice_note.dart';

class CompanionReferenceComposerDock extends ConsumerWidget {
  const CompanionReferenceComposerDock({
    super.key,
    required this.inputController,
    required this.onSend,
    required this.enabled,
    this.busy = false,
    this.errorMessage,
    this.onRetry,
    this.onMicTap,
    this.onMicCancel,
    this.onPlusTap,
  });

  final TextEditingController inputController;
  final VoidCallback onSend;
  final bool enabled;
  final bool busy;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onMicTap;
  final VoidCallback? onMicCancel;
  final VoidCallback? onPlusTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final output = ref.watch(companionOutputControllerProvider);
    final turn = ref.watch(companionVoiceTurnControllerProvider);
    final voice = ref.watch(companionVoiceControllerProvider);
    final conversationAllowed =
        CompanionVoiceConversationAccess.isAllowed(context);
    final talk = output.isConversation && conversationAllowed;
    final voicePhase = talk && turn.phase == OrVoiceTurnPhase.listening
        ? CompanionVoicePhase.listening
        : voice.phase;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (errorMessage != null && onRetry != null)
          CompanionReferenceNotice(
            message: errorMessage!,
            onRetry: onRetry,
            compact: true,
          ),
        if (busy && !talk) const CompanionReferenceThinking(),
        Padding(
          padding: EdgeInsets.fromLTRB(
            CompanionReferenceTokens.screenHorizontal,
            0,
            CompanionReferenceTokens.screenHorizontal,
            AppSpacing.s8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompanionReferenceOutputMode(
                mode: output.mode,
                speaking: output.isVoice && output.isSpeaking,
                paused: output.isVoice && output.isPaused,
                canReplay: output.canReplay,
                voiceAllowed: !output.voiceUnavailable,
                conversationAllowed: conversationAllowed,
                turnPhase: talk ? turn.phase : null,
                onChanged: output.setMode,
                onStop: output.stop,
                onPauseToggle: output.togglePause,
                onReplay: output.replay,
              ),
              CompanionReferenceVoiceNote(
                visible: output.isVoice && output.voiceUnavailable,
              ),
              CompanionReferenceLiveTranscript(
                phase: voicePhase,
                text: voice.composerDraft,
              ),
              CompanionReferenceTranscriptReview(
                visible: voice.needsReview && !voice.isActive,
                onRetry: () => retryCompanionMic(
                  context: context,
                  ref: ref,
                  composer: inputController,
                ),
                onConfirm: onSend,
              ),
            ],
          ),
        ),
        CompanionReferenceInputBar(
          controller: inputController,
          onSend: onSend,
          enabled: enabled &&
              !(talk && turn.phase.blocksComposerSend),
          voicePhase: voicePhase,
          onMicTap: onMicTap,
          onMicCancel: onMicCancel,
          onPlusTap: onPlusTap,
        ),
      ],
    );
  }
}
