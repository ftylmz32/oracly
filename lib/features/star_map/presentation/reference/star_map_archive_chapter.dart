/// One archive chapter — brass rail, engraved title, readable story line.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_soft_reveal.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/reading_typography.dart';
import 'star_map_reference_tokens.dart';

class StarMapArchiveChapter extends StatelessWidget {
  const StarMapArchiveChapter({
    super.key,
    required this.title,
    required this.body,
    this.index = 0,
    this.emphasis = false,
  });

  final String title;
  final String body;
  final int index;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final line = body.trim();
    if (line.isEmpty) return const SizedBox.shrink();
    final brass = StarMapReferenceTokens.brassGlow;
    final railW = emphasis ? 2.0 : 1.15;
    return OraclySoftReveal(
      delay: Duration(milliseconds: 60 + index * 36),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: railW,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    brass.withValues(alpha: emphasis ? 0.92 : 0.78),
                    OraclyChrome.gold.withValues(alpha: 0.14),
                  ],
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ReadingTypography.sectionLabel(fontSize: 11).copyWith(
                      letterSpacing: 2.2,
                      color: brass.withValues(alpha: emphasis ? 0.94 : 0.86),
                    ),
                  ),
                  SizedBox(height: CraftsmanshipRhythm.afterTitle),
                  Text(
                    line,
                    style: ReadingTypography.body(
                      color: OraclyChrome.cream.withValues(
                        alpha: emphasis ? 0.92 : 0.86,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
