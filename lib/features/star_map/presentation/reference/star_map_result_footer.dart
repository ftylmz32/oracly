/// Quiet result epilogue — typed actions only; never rebuilds payloads.
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
import '../../../../features/ai/oracle_conversation/widgets/or_ask_button.dart';
import '../../../../features/discovery_share/widgets/discovery_share_action.dart';
import '../../../favorite_moments/presentation/widgets/save_favorite_moment_link.dart';
import '../../../reading_feedback/presentation/widgets/reading_quality_actions.dart';
import '../../copy/star_map_polish_copy.dart';
import '../../result/yildizname_result_actions.dart';
import 'star_map_result_footer_forensic.dart';

class StarMapResultFooter extends StatelessWidget {
  const StarMapResultFooter({
    super.key,
    required this.actions,
    this.forensicLegacyActionOrder = false,
  });

  final YildiznameResultActions actions;
  final bool forensicLegacyActionOrder;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final feedback = ReadingQualityActions(feature: QualityFeature.starMap);
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
        if (forensicLegacyActionOrder)
          ...StarMapResultFooterForensic.actionCluster(
            actions: actions,
            palette: palette,
            feedback: feedback,
          )
        else
          ..._productionCluster(palette, feedback),
      ],
    );
  }

  List<Widget> _productionCluster(
    AppColorPalette palette,
    Widget feedback,
  ) {
    return [
      if (actions.hasOr) ...[
        OrAskButton(readingContext: actions.orContext!),
        SizedBox(height: AppSpacing.s8),
        Text(
          StarMapPolishCopy.orHint,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            color: palette.textSecondary.withValues(alpha: 0.80),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
      ],
      DiscoveryShareAction(discovery: actions.share),
      if (actions.hasFavorite)
        SaveFavoriteMomentLink(draft: actions.favorite!.toMoment()),
      InsightCopyLink(text: actions.copyText),
      SessionContinuationLink(
        source: SessionContinuationSource.starMap,
        sessionThemes: actions.continuationThemes,
        orAlreadyOffered: actions.hasOr,
        oracleContext: actions.orContext,
      ),
      feedback,
    ];
  }
}
