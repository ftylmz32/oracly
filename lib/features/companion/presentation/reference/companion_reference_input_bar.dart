/// Premium Luna composer well — separate controls, privacy whisper.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/companion_copy.dart';
import '../../voice/companion_voice_phase.dart';
import 'companion_feature_shortcuts.dart';
import 'companion_reference_composer_row.dart';
import 'companion_reference_prompts.dart';
import 'companion_reference_tokens.dart';

class CompanionReferenceInputBar extends StatelessWidget {
  const CompanionReferenceInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.enabled = true,
    this.voicePhase = CompanionVoicePhase.idle,
    this.onMicTap,
    this.onMicCancel,
    this.onPlusTap,
    this.showShortcuts = false,
    this.onPromptSelected,
    this.kindId,
    this.reserveShellNavigationClearance = true,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;
  final CompanionVoicePhase voicePhase;
  final VoidCallback? onMicTap;
  final VoidCallback? onMicCancel;
  final VoidCallback? onPlusTap;
  final bool showShortcuts;

  /// Sends the starter straight through the existing composer path.
  final ValueChanged<String>? onPromptSelected;
  final String? kindId;
  final bool reserveShellNavigationClearance;

  @override
  Widget build(BuildContext context) {
    final bottom = reserveShellNavigationClearance
        ? AppLayout.scrollBottomInset(context)
        : MediaQuery.paddingOf(context).bottom + 8;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        CompanionReferenceTokens.screenHorizontal,
        CompanionReferenceTokens.inputBarTopGap,
        CompanionReferenceTokens.screenHorizontal,
        bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showShortcuts) ...[
            if (onPromptSelected != null) ...[
              CompanionReferencePrompts(
                onSelected: onPromptSelected!,
                horizontal: true,
                limit: 3,
                kindId: kindId,
              ),
              const SizedBox(height: 10),
            ],
            const CompanionFeatureShortcuts(),
            const SizedBox(height: 8),
          ],
          CompanionReferenceComposerRow(
            voicePhase: voicePhase,
            enabled: enabled,
            controller: controller,
            onSend: onSend,
            onMicTap: onMicTap,
            onMicCancel: onMicCancel,
            onPlusTap: onPlusTap,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 11,
                color: OraclyChrome.goldLight.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  CompanionCopy.privacyNote,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: ReadingTypography.micro(
                    color: OraclyChrome.goldLight.withValues(alpha: 0.58),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
