/// Compact output chip — engraved ceremonial toggle, never a neon mode button.
library;

import 'package:flutter/material.dart';

import '../../../../core/accessibility/oracly_a11y.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/oracly_reduced_motion.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import 'companion_reference_output_stop.dart';

class CompanionOutputChip extends StatelessWidget {
  const CompanionOutputChip({
    super.key,
    required this.selected,
    required this.label,
    required this.semantics,
    required this.onTap,
    this.muted = false,
  });

  final bool selected;
  final String label;
  final String semantics;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final cream = OraclyChrome.cream.withValues(
      alpha: muted && !selected
          ? OraclyA11y.hintCream
          : (selected ? OraclyA11y.goldOnDark : OraclyA11y.secondaryCream),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: semantics,
      child: OraclyPressable(
        onTap: onTap,
        borderRadius: CompanionOutputModeTokens.radius,
        child: OraclyA11y.ensureMinTouch(
          child: AnimatedContainer(
            duration: OraclyReducedMotion.duration(
              context,
              const Duration(milliseconds: 180),
            ),
            height: CompanionOutputModeTokens.height,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              borderRadius: CompanionOutputModeTokens.radius,
              color: selected
                  ? OraclyChrome.violet.withValues(alpha: 0.18)
                  : OraclyChrome.midnight.withValues(alpha: 0.28),
              border: Border.all(
                color: OraclyChrome.gold.withValues(
                  alpha: selected ? 0.42 : 0.16,
                ),
                width: AppBorderWidth.hairline,
              ),
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                style: AppTextStyles.bodySmall.copyWith(
                  color: cream,
                  letterSpacing: 1.6,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 10.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
