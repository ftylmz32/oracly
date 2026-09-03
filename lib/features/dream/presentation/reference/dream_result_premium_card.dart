/// Premium result section card for dream analysis.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';

class DreamResultPremiumCard extends StatelessWidget {
  const DreamResultPremiumCard({
    super.key,
    required this.title,
    required this.body,
    required this.icon,
    this.child,
  });

  final String title;
  final String body;
  final IconData icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: OraclyChrome.cardSurface.withValues(alpha: 0.12),
          border: Border.all(
            color: OraclyChrome.gold.withValues(alpha: 0.14),
            width: 0.6,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: OraclyChrome.goldLight.withValues(alpha: 0.78)),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: ReadingTypography.sectionLabel(
                      color: OraclyChrome.goldLight.withValues(alpha: 0.88),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              if (body.isNotEmpty)
                Text(
                  body,
                  style: ReadingTypography.body(
                    color: OraclyChrome.cream.withValues(alpha: 0.9),
                  ),
                ),
              if (child != null) child!,
            ],
          ),
        ),
      ),
    );
  }
}
