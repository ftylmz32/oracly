/// Quiet cue when a new OR turn arrives while the reader scrolled up.
library;

import 'package:flutter/material.dart';

import '../../../../core/accessibility/oracly_a11y.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../copy/companion_copy.dart';

class CompanionNewReplyChip extends StatelessWidget {
  const CompanionNewReplyChip({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      liveRegion: true,
      label: CompanionCopy.newReply,
      child: OraclyPressable(
        onTap: onTap,
        borderRadius: AppRadius.s20,
        child: OraclyA11y.ensureMinTouch(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.s20,
              color: OraclyChrome.midnight.withValues(alpha: 0.88),
              border: Border.all(
                color: OraclyChrome.gold.withValues(alpha: 0.32),
              ),
              boxShadow: [
                BoxShadow(
                  color: OraclyChrome.violet.withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(
                CompanionCopy.newReply,
                style: AppTextStyles.caption.copyWith(
                  color: OraclyA11y.goldReadable(OraclyChrome.goldLight),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
