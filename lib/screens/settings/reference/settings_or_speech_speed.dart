/// OR speech tempo chips - slow / normal / fast. Default natural.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../core/voice/or_speech_speed.dart';
import '../../../core/voice/oracly_voice_copy.dart';
import '../../../features/companion/presentation/reference/companion_reference_output_chip.dart';
import '../../../features/premium/models/personalization_models.dart';
import 'settings_reference_tokens.dart';

class SettingsOrSpeechSpeed extends StatelessWidget {
  const SettingsOrSpeechSpeed({
    super.key,
    required this.settings,
    required this.onSave,
  });

  final PersonalizationSettings settings;
  final Future<void> Function(
    PersonalizationSettings Function(PersonalizationSettings),
  ) onSave;

  String get _lang => settings.language;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final selected = settings.orSpeechSpeed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          OraclyVoiceCopy.speedTitle(_lang),
          style: ReadingTypography.sectionLabel(fontSize: 11),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          OraclyVoiceCopy.speedHint(_lang),
          style: ReadingTypography.bodySmall(
            color: palette.textSecondary.withValues(alpha: 0.78),
          ),
        ),
        SizedBox(height: SettingsReferenceTokens.headerToProfile),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final speed in OrSpeechSpeed.values)
              CompanionOutputChip(
                key: ValueKey('or-speech-speed-${speed.wire}'),
                selected: selected == speed,
                label: OraclyVoiceCopy.speedLabel(speed, _lang),
                semantics: OraclyVoiceCopy.speedLabel(speed, _lang),
                onTap: () {
                  if (selected == speed) return;
                  onSave((s) => s.copyWith(orSpeechSpeed: speed));
                },
              ),
          ],
        ),
      ],
    );
  }
}

