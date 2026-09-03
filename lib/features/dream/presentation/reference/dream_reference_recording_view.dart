/// Sesli Anlat recording — Dinliyorum + Durdur, existing dream visual language.
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/chamber_waiting_orb.dart';
import '../../../../shared/widgets/oracly_button.dart';
import '../../copy/dream_copy.dart';
import '../../voice/dream_voice_phase.dart';

class DreamReferenceRecordingView extends StatelessWidget {
  const DreamReferenceRecordingView({
    super.key,
    required this.phase,
    required this.liveText,
    required this.onStop,
    required this.onCancel,
  });

  final DreamVoicePhase phase;
  final String liveText;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final stopping = phase == DreamVoicePhase.processing;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: AppSpacing.screenHorizontal,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ChamberWaitingOrb(),
              SizedBox(height: AppSpacing.lg),
              Text(
                DreamCopy.voiceListening,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (liveText.trim().isNotEmpty) ...[
                SizedBox(height: AppSpacing.md),
                Text(
                  liveText,
                  textAlign: TextAlign.center,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
              SizedBox(height: AppSpacing.xl),
              OraclyButton(
                text: DreamCopy.voiceStop,
                isExpanded: true,
                isLoading: stopping,
                onPressed: stopping ? null : onStop,
              ),
              SizedBox(height: AppSpacing.sm),
              OraclyButton(
                text: OraclyL10n.t(L10nKeys.back),
                type: OraclyButtonType.ghost,
                onPressed: stopping ? null : onCancel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
