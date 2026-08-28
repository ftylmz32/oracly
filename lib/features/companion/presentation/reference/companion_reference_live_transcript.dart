/// Live STT caption while listening - sole transcript surface until settle.
library;

import 'package:flutter/material.dart';

import '../../../../core/accessibility/oracly_a11y.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/companion_copy.dart';
import '../../voice/companion_voice_phase.dart';

class CompanionReferenceLiveTranscript extends StatelessWidget {
  const CompanionReferenceLiveTranscript({
    super.key,
    required this.phase,
    required this.text,
  });

  final CompanionVoicePhase phase;
  final String text;

  @override
  Widget build(BuildContext context) {
    final listening = phase == CompanionVoicePhase.listening ||
        phase == CompanionVoicePhase.requesting;
    if (!listening) return const SizedBox.shrink();
    final palette = AppColors.of(context);
    final body = text.trim();
    final caption = body.isEmpty ? '…' : body;
    return Semantics(
      liveRegion: true,
      label: '${CompanionCopy.voiceListening}. $caption',
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              CompanionCopy.voiceListening,
              style: ReadingTypography.sectionLabel(
                fontSize: 10,
                color: OraclyA11y.goldReadable(palette.goldLight),
              ),
            ),
            SizedBox(height: AppSpacing.s4),
            Text(
              caption,
              style: ReadingTypography.body(
                color: palette.textPrimary.withValues(
                  alpha: body.isEmpty ? OraclyA11y.hintCream : 0.94,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
