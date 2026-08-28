/// Secondary text action — gallery / retake / history; never competes with gold CTA.
library;

import 'package:flutter/material.dart';

import '../../core/accessibility/oracly_a11y.dart';
import '../../core/design_system/oracly_chrome.dart';
import '../../core/theme/reading_typography.dart';
import 'oracly_pressable.dart';

class OraclyQuietLink extends StatelessWidget {
  const OraclyQuietLink({
    super.key,
    required this.label,
    required this.onTap,
    this.muted = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onTap,
      label: label,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: OraclyA11y.minTouchTarget,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ReadingTypography.sectionLabel(fontSize: 12).copyWith(
                letterSpacing: 1.6,
                color: OraclyChrome.goldLight.withValues(
                  alpha: muted
                      ? OraclyA11y.quietGoldMuted
                      : OraclyA11y.quietGold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
