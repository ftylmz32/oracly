/// Quiet listen control — real TTS, never a system ding.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/voice/oracly_voice_copy.dart';
import '../../../shared/widgets/oracly_pressable.dart';

class SettingsOrVoicePlay extends StatelessWidget {
  const SettingsOrVoicePlay({
    super.key,
    required this.languageCode,
    required this.label,
    required this.preparing,
    required this.onPreview,
  });

  final String languageCode;
  final String label;
  final bool preparing;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final action = OraclyVoiceCopy.preview(languageCode);
    return Semantics(
      button: true,
      label: '$action, $label',
      child: OraclyPressable(
        onTap: preparing ? null : onPreview,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Center(
            child: preparing
                ? Text(
                    OraclyVoiceCopy.preparing(languageCode),
                    style: AppTextStyles.caption.copyWith(
                      color: palette.gold.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Icon(
                    Icons.play_arrow_rounded,
                    color: palette.gold.withValues(alpha: 0.92),
                    size: 28,
                  ),
          ),
        ),
      ),
    );
  }
}
