/// One draw-mode choice — ritual draw or quiet manual pick.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/reading_typography.dart';
import '../../../../../shared/widgets/oracly_pressable.dart';

class DrawModeOption extends StatelessWidget {
  const DrawModeOption({
    super.key,
    required this.title,
    required this.blurb,
    required this.onTap,
    this.emphasized = false,
  });

  final String title;
  final String blurb;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final gold = AppColors.goldLight;
    final edge = emphasized ? 0.42 : 0.22;
    final fill = emphasized ? 0.07 : 0.04;
    return Semantics(
      button: true,
      label: '$title. $blurb',
      child: OraclyPressable(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: gold.withValues(alpha: edge)),
              color: Colors.white.withValues(alpha: fill),
              boxShadow: emphasized
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ReadingTypography.sectionLabel(
                      color: gold.withValues(alpha: emphasized ? 0.96 : 0.88),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    blurb,
                    style: ReadingTypography.bodySmall(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
