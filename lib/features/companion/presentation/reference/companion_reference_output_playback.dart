/// SESLİ playback — clear state, pause / stop / replay. Never a media bar.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../copy/companion_copy.dart';
import 'companion_reference_output_chip.dart';
import 'companion_reference_output_stop.dart';

class CompanionReferenceOutputPlayback extends StatelessWidget {
  const CompanionReferenceOutputPlayback({
    super.key,
    required this.speaking,
    required this.paused,
    required this.canReplay,
    required this.onPauseToggle,
    required this.onStop,
    required this.onReplay,
  });

  final bool speaking;
  final bool paused;
  final bool canReplay;
  final VoidCallback? onPauseToggle;
  final VoidCallback? onStop;
  final VoidCallback? onReplay;

  @override
  Widget build(BuildContext context) {
    if (!speaking && !canReplay) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (speaking) ...[
          Text(
            paused ? CompanionCopy.paused : CompanionCopy.speaking,
            style: AppTextStyles.caption.copyWith(
              color: OraclyChrome.cream.withValues(alpha: 0.70),
              letterSpacing: 0.4,
            ),
          ),
          if (onPauseToggle != null)
            CompanionOutputChip(
              selected: false,
              label: paused
                  ? CompanionCopy.resumeSpeaking
                  : CompanionCopy.pauseSpeaking,
              semantics: paused
                  ? CompanionCopy.resumeSpeaking
                  : CompanionCopy.pauseSpeaking,
              onTap: onPauseToggle!,
            ),
          if (onStop != null) CompanionReferenceOutputStop(onTap: onStop),
        ] else if (canReplay && onReplay != null)
          CompanionOutputChip(
            selected: false,
            label: CompanionCopy.replaySpeaking,
            semantics: CompanionCopy.replaySpeaking,
            onTap: onReplay!,
          ),
      ],
    );
  }
}
