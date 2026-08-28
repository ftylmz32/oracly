/// Compact Yıldızname overview — general vs personalized, honestly labeled.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/star_map_polish_copy.dart';
import '../../models/star_map_reading.dart';
import 'star_map_reference_card_shell.dart';
import 'star_map_reference_tokens.dart';

class StarMapReferenceIntro extends StatelessWidget {
  const StarMapReferenceIntro({
    super.key,
    required this.overview,
    this.isPersonalized = false,
  });

  final StarMapOverview overview;
  final bool isPersonalized;

  @override
  Widget build(BuildContext context) {
    return StarMapReferenceCardShell(
      height: StarMapReferenceTokens.introCardHeight,
      borderRadius: StarMapReferenceTokens.introCardRadius,
      padding: StarMapReferenceTokens.introCardPadding,
      premium: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isPersonalized
                ? StarMapPolishCopy.personalizedDailyLabel
                : StarMapPolishCopy.generalDailyLabel,
            style: ReadingTypography.sectionLabel(fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text(
            StarMapPolishCopy.todayCardTitle,
            style: AppTextStyles.caption.copyWith(
              color: OraclyChrome.cream.withValues(alpha: 0.88),
              fontWeight: FontWeight.w600,
              fontSize: 12,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            overview.mainMessage,
            style: OraclyChrome.bodySecondary(size: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
