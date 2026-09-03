/// Composer row — plus · pill field with mic · gold send.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/accessibility/oracly_a11y.dart';
import '../../../../core/copy/conversation_copy.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../copy/companion_copy.dart';
import '../../voice/companion_voice_phase.dart';
import 'companion_reference_plus_slot.dart';
import 'companion_reference_send_button.dart';
import 'companion_reference_tokens.dart';
import 'companion_reference_voice_slot.dart';

class CompanionReferenceComposerRow extends StatelessWidget {
  const CompanionReferenceComposerRow({
    super.key,
    required this.voicePhase,
    required this.enabled,
    required this.controller,
    required this.onSend,
    required this.onMicTap,
    required this.onPlusTap,
    this.onMicCancel,
  });

  final CompanionVoicePhase voicePhase;
  final bool enabled;
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onMicTap;
  final VoidCallback? onMicCancel;
  final VoidCallback? onPlusTap;

  void _submitIfReady() {
    if (!enabled || controller.text.trim().isEmpty) return;
    onSend();
  }

  @override
  Widget build(BuildContext context) {
    final listening = voicePhase == CompanionVoicePhase.listening ||
        voicePhase == CompanionVoicePhase.requesting;
    return OraclyA11y.chromeTextScale(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CompanionReferencePlusSlot(onTap: enabled ? onPlusTap : null),
          const SizedBox(width: 8),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: const Color(0xFF14101C).withValues(alpha: 0.92),
                border: Border.all(
                  color: OraclyChrome.violet.withValues(alpha: 0.42),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Shortcuts(
                      shortcuts: {
                        SingleActivator(LogicalKeyboardKey.enter, control: true):
                            const ActivateIntent(),
                        SingleActivator(LogicalKeyboardKey.enter, meta: true):
                            const ActivateIntent(),
                      },
                      child: Actions(
                        actions: {
                          ActivateIntent: CallbackAction<ActivateIntent>(
                            onInvoke: (_) {
                              _submitIfReady();
                              return null;
                            },
                          ),
                        },
                        child: Semantics(
                          textField: true,
                          label: CompanionCopy.messageYou,
                          child: TextField(
                            controller: controller,
                            enabled: enabled,
                            maxLines:
                                CompanionReferenceTokens.composerMaxLines,
                            minLines: 1,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.send,
                            textCapitalization: TextCapitalization.sentences,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: OraclyChrome.cream.withValues(alpha: 0.94),
                              fontSize: 15,
                              height: 1.35,
                            ),
                            cursorColor:
                                OraclyChrome.goldLight.withValues(alpha: 0.85),
                            onSubmitted: enabled
                                ? (_) => _submitIfReady()
                                : null,
                            decoration: InputDecoration(
                              hintText: ConversationCopy.inputHint,
                              hintStyle: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textMuted.withValues(
                                  alpha: OraclyA11y.hintCream,
                                ),
                                fontSize: 15,
                                height: 1.35,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                8,
                                12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  CompanionReferenceVoiceSlot(
                    phase: voicePhase,
                    onTap: enabled || listening ? onMicTap : null,
                    onCancel: onMicCancel,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final hasText = value.text.trim().isNotEmpty ||
                  !value.composing.isCollapsed;
              final canSend = hasText && enabled;
              return CompanionReferenceSendButton(
                onTap: canSend ? onSend : null,
                enabled: canSend,
              );
            },
          ),
        ],
      ),
    );
  }
}
