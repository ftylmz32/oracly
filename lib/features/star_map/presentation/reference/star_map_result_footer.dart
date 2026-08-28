/// Quiet result epilogue - disclaimer, share, OR, continue, save.
library;

import 'package:flutter/material.dart';

import '../../../../core/continuation/models/session_continuation.dart';
import '../../../../core/continuation/widgets/session_continuation_link.dart';
import '../../../../core/copy/session_ending_copy.dart';
import '../../../../core/insight_copy/widgets/insight_copy_link.dart';
import '../../../../core/quality/quality_feature.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../features/ai/oracle_conversation/models/oracle_reading_context.dart';
import '../../../../features/ai/oracle_conversation/widgets/or_ask_button.dart';
import '../../../../features/discovery_share/services/discovery_share_builder.dart';
import '../../../../features/discovery_share/widgets/discovery_share_action.dart';
import '../../../favorite_moments/presentation/widgets/save_favorite_moment_link.dart';
import '../../../favorite_moments/services/favorite_moment_factory.dart';
import '../../../reading_feedback/presentation/widgets/reading_quality_actions.dart';
import '../../copy/star_map_polish_copy.dart';
import '../../models/star_map_reading.dart';
import 'star_map_insight_copy.dart';
import 'star_map_result_section.dart';

class StarMapResultFooter extends StatelessWidget {
  const StarMapResultFooter({
    super.key,
    required this.title,
    required this.sections,
    required this.planets,
    required this.insight,
    required this.refKey,
    this.readingContext,
  });

  final String title;
  final List<StarMapResultSection> sections;
  final List<StarMapPlanetInfluence> planets;
  final String insight;
  final String refKey;
  final OracleReadingContext? readingContext;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(top: AppSpacing.s8),
          child: Text(
            StarMapPolishCopy.symbolicDisclaimer,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: palette.textSecondary.withValues(alpha: 0.82),
              height: 1.4,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          SessionEndingCopy.footerWhisper,
          textAlign: TextAlign.center,
          style: ReadingTypography.micro(
            color: palette.textSecondary.withValues(alpha: 0.62),
          ),
        ),
        SizedBox(height: AppSpacing.md),
        InsightCopyLink(
          text: StarMapInsightCopy.fromResult(
            title: title,
            sections: sections,
            planets: planets,
          ),
        ),
        DiscoveryShareAction(
          discovery: DiscoveryShareBuilder.starMap(
            highlight: insight.trim().isNotEmpty
                ? insight
                : (sections.isEmpty ? title : sections.first.title),
          ),
        ),
        if (readingContext != null) ...[
          SizedBox(height: AppSpacing.md),
          OrAskButton(readingContext: readingContext!),
          SizedBox(height: AppSpacing.s8),
          Text(
            StarMapPolishCopy.orHint,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: palette.textSecondary.withValues(alpha: 0.80),
            ),
          ),
        ],
        SessionContinuationLink(
          source: SessionContinuationSource.starMap,
          sessionThemes: [
            for (final section in sections) section.title,
          ],
          orAlreadyOffered: readingContext != null,
        ),
        SaveFavoriteMomentLink(
          draft: FavoriteMomentFactory.starMap(
            ref: refKey,
            at: DateTime.now(),
            title: title,
            insight: insight,
          ),
        ),
        ReadingQualityActions(feature: QualityFeature.starMap),
      ],
    );
  }
}
