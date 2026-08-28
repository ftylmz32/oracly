/// OR-1060 — Staggered reading section with fade + slide.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/reading_typography.dart';

class ReadingSectionTile extends StatelessWidget {
  const ReadingSectionTile({
    super.key,
    required this.title,
    required this.body,
    required this.progress,
    this.icon,
  });

  final String title;
  final String body;
  final double progress;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final slide = (1 - progress) * 18;
    return Opacity(
      opacity: progress.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, slide),
        child: Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md + AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: AppSpacing.md, color: AppColors.gold),
                    SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: ReadingTypography.sectionLabel(fontSize: 13),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              Text(
                body,
                style: ReadingTypography.bodySmall(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section reveal stagger — index 0..7, master 0..1 after intro.
double readingSectionProgress(int index, double master) {
  const span = 0.09;
  final start = index * span + (index % 3) * 0.017;
  final end = start + 0.28;
  if (master <= start) return 0;
  if (master >= end) return 1;
  return Curves.easeOutCubic.transform(
    ((master - start) / (end - start)).clamp(0.0, 1.0),
  );
}
