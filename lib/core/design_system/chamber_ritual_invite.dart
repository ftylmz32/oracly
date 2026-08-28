/// One ritual invitation — purpose, then the primary actions live below.
library;

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/reading_typography.dart';
import 'oracly_chrome.dart';

class ChamberRitualInvite extends StatelessWidget {
  const ChamberRitualInvite({
    super.key,
    required this.title,
    required this.body,
    this.lead,
  });

  final String title;
  final String body;
  final String? lead;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: OraclyChrome.cardRadius,
        border: Border.all(
          color: OraclyChrome.gold.withValues(alpha: 0.38),
          width: 0.9,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OraclyChrome.gold.withValues(alpha: 0.10),
            OraclyChrome.violet.withValues(alpha: 0.16),
            OraclyChrome.midnight.withValues(alpha: 0.55),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          children: [
            if (lead != null && lead!.trim().isNotEmpty) ...[
              Text(
                lead!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ReadingTypography.opening(
                  color: OraclyChrome.cream.withValues(alpha: 0.78),
                ).copyWith(fontSize: 13.5, height: 1.35),
              ),
              SizedBox(height: AppSpacing.s8),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: ReadingTypography.sectionLabel(
                color: OraclyChrome.goldPrimary.withValues(alpha: 0.94),
              ),
            ),
            SizedBox(height: AppSpacing.s8),
            Text(
              body,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: ReadingTypography.body(
                color: OraclyChrome.cream.withValues(alpha: 0.84),
              ).copyWith(height: 1.42, fontSize: 13.5),
            ),
          ],
        ),
      ),
    );
  }
}
