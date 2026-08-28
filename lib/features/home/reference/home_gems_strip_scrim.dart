/// Left-readable scrim + copy for the home gems strip.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/craftsmanship_rhythm.dart';
import '../../../core/theme/reading_typography.dart';

class HomeGemsStripScrim extends StatelessWidget {
  const HomeGemsStripScrim({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.nearBlack.withValues(alpha: 0.86),
            AppColors.surfaceElevated.withValues(alpha: 0.70),
            AppColors.surface.withValues(alpha: 0.32),
            AppColors.glowPurple.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          stops: const [0.0, 0.28, 0.52, 0.72, 0.92],
        ),
      ),
    );
  }
}

class HomeGemsStripCopy extends StatelessWidget {
  const HomeGemsStripCopy({
    super.key,
    required this.title,
    required this.balance,
    required this.balanceLabel,
    required this.padding,
  });

  final String title;
  final String balance;
  final String balanceLabel;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 210),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: ReadingTypography.eyebrow(
                  color: AppColors.goldLight.withValues(alpha: 0.92),
                  fontSize: 10.5,
                ).copyWith(
                  letterSpacing: CraftsmanshipRhythm.sectionLabelTracking + 0.25,
                  height: 1.05,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                balance,
                style: ReadingTypography.pageTitle(
                  color: AppColors.goldLight.withValues(alpha: 0.98),
                ).copyWith(
                  fontSize: 22,
                  height: 1.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                balanceLabel,
                style: ReadingTypography.metadata().copyWith(
                  color: AppColors.ivory.withValues(alpha: 0.74),
                  height: 1.15,
                  fontSize: 10.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
