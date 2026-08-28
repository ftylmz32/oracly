/// Engraved archive chapter label — timeline / fragments / discoveries.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';

class DiscoveryArchiveHeading extends StatelessWidget {
  const DiscoveryArchiveHeading({
    super.key,
    required this.label,
    this.top = AppSpacing.s16,
  });

  final String label;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: AppSpacing.s8),
      child: Row(
        children: [
          Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 5,
              height: 5,
              color: OraclyChrome.goldLight.withValues(alpha: 0.70),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label.trim().toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ReadingTypography.sectionLabel(fontSize: 11).copyWith(
                letterSpacing: 2.2,
                color: OraclyChrome.goldLight.withValues(alpha: 0.86),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 0.7,
              margin: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    OraclyChrome.gold.withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
