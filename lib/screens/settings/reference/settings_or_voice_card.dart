/// One OR voice expression — not a separate character, not an audio slider.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../core/voice/oracly_voice_copy.dart';
import '../../../core/voice/oracly_voice_id.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import 'settings_or_voice_play.dart';
import 'settings_reference_card_shell.dart';
import 'settings_reference_tokens.dart';

class SettingsOrVoiceCard extends StatelessWidget {
  const SettingsOrVoiceCard({
    super.key,
    required this.id,
    required this.languageCode,
    required this.selected,
    required this.preparing,
    required this.onSelect,
    required this.onPreview,
  });

  final OraclyVoiceId id;
  final String languageCode;
  final bool selected;
  final bool preparing;
  final VoidCallback onSelect;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final label = OraclyVoiceCopy.title(id, languageCode);
    return SettingsReferenceCardShell(
      selected: selected,
      borderRadius: SettingsReferenceTokens.groupRadius,
      child: Padding(
        padding: SettingsReferenceTokens.rowPadding,
        child: Row(
          children: [
            Expanded(
              child: OraclyPressable(
                onTap: onSelect,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: ReadingTypography.sectionLabel(
                          color: selected
                              ? palette.goldLight
                              : palette.textPrimary.withValues(alpha: 0.92),
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        OraclyVoiceCopy.subtitle(id, languageCode),
                        style: ReadingTypography.bodySmall(
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SettingsOrVoicePlay(
              key: ValueKey('or-voice-preview-${id.wire}'),
              languageCode: languageCode,
              label: label,
              preparing: preparing,
              onPreview: onPreview,
            ),
          ],
        ),
      ),
    );
  }
}
