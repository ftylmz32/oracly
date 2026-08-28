/// Shared Profile chamber chrome — engraved title, brass rail, quiet CTA.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/craftsmanship_rhythm.dart';
import '../../../core/theme/reading_typography.dart';

class ProfileChamberTitle extends StatelessWidget {
  const ProfileChamberTitle({
    super.key,
    required this.title,
    this.emphasis = false,
  });

  final String title;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.trim(),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: ReadingTypography.sectionLabel(
        fontSize: emphasis ? 12 : 11,
      ).copyWith(
        letterSpacing: 2.2,
        color: OraclyChrome.goldLight.withValues(
          alpha: emphasis ? 0.94 : 0.86,
        ),
      ),
    );
  }
}

class ProfileChamberCta extends StatelessWidget {
  const ProfileChamberCta({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.trim(),
      style: ReadingTypography.footnote(
        color: OraclyChrome.goldLight.withValues(alpha: 0.82),
      ).copyWith(letterSpacing: 1.4),
    );
  }
}

class ProfileChamberRail extends StatelessWidget {
  const ProfileChamberRail({
    super.key,
    required this.child,
    this.emphasis = false,
  });

  final Widget child;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: emphasis ? 2.0 : 1.15,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  OraclyChrome.goldLight.withValues(
                    alpha: emphasis ? 0.90 : 0.72,
                  ),
                  OraclyChrome.gold.withValues(alpha: 0.14),
                ],
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm + 2),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class ProfileChamberGap {
  ProfileChamberGap._();

  static double get afterTitle => CraftsmanshipRhythm.afterTitle;
  static double get beforeCta => CraftsmanshipRhythm.paragraphGap;
}
