/// Editorial opening of a reading — not a dashboard card.
library;

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/reading_typography.dart';
import 'oracly_chrome.dart';
import 'oracly_soft_reveal.dart';

class ChamberStoryPanel extends StatelessWidget {
  const ChamberStoryPanel({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
  });

  final String title;
  final String body;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    if (body.trim().isEmpty) return const SizedBox.shrink();
    return OraclySoftReveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: ReadingTypography.sectionLabel(
              color: OraclyChrome.goldPrimary.withValues(alpha: 0.96),
              fontSize: 13,
            ),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: ReadingTypography.opening(
                color: OraclyChrome.cream.withValues(alpha: 0.72),
              ).copyWith(fontSize: 13.5, height: 1.4),
            ),
          ],
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 42,
              height: 1,
              color: OraclyChrome.gold.withValues(alpha: 0.55),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            body,
            textAlign: TextAlign.center,
            style: ReadingTypography.reflection(
              color: OraclyChrome.cream.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}
