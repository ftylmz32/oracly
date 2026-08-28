/// Premium OR composer well — cosmic glass, ceremonial gold, quiet.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../voice/companion_voice_phase.dart';
import 'companion_reference_composer_row.dart';
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
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;
  final CompanionVoicePhase voicePhase;
  final VoidCallback? onMicTap;
  final VoidCallback? onMicCancel;
  final VoidCallback? onPlusTap;

  @override
  Widget build(BuildContext context) {
    final bottom = AppLayout.scrollBottomInset(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        CompanionReferenceTokens.screenHorizontal,
        CompanionReferenceTokens.inputBarTopGap,
        CompanionReferenceTokens.screenHorizontal,
        bottom,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: CompanionReferenceTokens.inputRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.48),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: OraclyChrome.violet.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: CompanionReferenceTokens.inputRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: CompanionReferenceTokens.inputRadius,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF221C2C).withValues(alpha: 0.55),
                    const Color(0xFF121018).withValues(alpha: 0.96),
                  ],
                  stops: const [0.0, 0.22],
                ),
                border: Border.all(
                  color: OraclyChrome.gold.withValues(alpha: 0.20),
                  width: AppBorderWidth.hairline,
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: CompanionReferenceTokens.composerMinHeight,
                ),
                child: Padding(
                  padding: CompanionReferenceTokens.inputPadding,
                  child: CompanionReferenceComposerRow(
                    voicePhase: voicePhase,
                    enabled: enabled,
                    controller: controller,
                    onSend: onSend,
                    onMicTap: onMicTap,
                    onMicCancel: onMicCancel,
                    onPlusTap: onPlusTap,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
