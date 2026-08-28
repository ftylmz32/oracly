/// Opening of today's archive chapters.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/star_map_polish_copy.dart';

class StarMapReferenceStory extends StatelessWidget {
  const StarMapReferenceStory({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          StarMapPolishCopy.storyTitle,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ReadingTypography.sectionLabel(
            color: OraclyChrome.goldPrimary.withValues(alpha: 0.96),
            fontSize: 13,
          ),
        ),
        SizedBox(height: AppSpacing.s8),
        Center(
          child: Container(
            width: 42,
            height: 1,
            color: OraclyChrome.gold.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}
