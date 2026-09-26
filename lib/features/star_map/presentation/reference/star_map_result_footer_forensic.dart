/// Pre-7E footer action order — frozen 7A–7C golden chrome only.
library;

import 'package:flutter/material.dart';

import '../../../../core/continuation/models/session_continuation.dart';
import '../../../../core/continuation/widgets/session_continuation_link.dart';
import '../../../../core/insight_copy/widgets/insight_copy_link.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/ai/oracle_conversation/widgets/or_ask_button.dart';
import '../../../../features/discovery_share/widgets/discovery_share_action.dart';
import '../../../favorite_moments/copy/favorite_moments_copy.dart';
import '../../../favorite_moments/presentation/widgets/save_favorite_moment_link.dart';
import '../../copy/star_map_polish_copy.dart';
import '../../result/yildizname_result_actions.dart';

abstract final class StarMapResultFooterForensic {
  StarMapResultFooterForensic._();

  static List<Widget> actionCluster({
    required YildiznameResultActions actions,
    required AppColorPalette palette,
    required Widget feedback,
  }) {
    return [
      InsightCopyLink(text: actions.copyText),
      DiscoveryShareAction(discovery: actions.share),
      if (actions.hasOr) ...[
        SizedBox(height: AppSpacing.md),
        OrAskButton(readingContext: actions.orContext!),
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
        sessionThemes: actions.continuationThemes,
        orAlreadyOffered: actions.hasOr,
      ),
      if (actions.hasFavorite)
        SaveFavoriteMomentLink(draft: actions.favorite!.toMoment())
      else
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            FavoriteMomentsCopy.sourceUnavailable,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: palette.textSecondary.withValues(alpha: 0.72),
            ),
          ),
        ),
      feedback,
    ];
  }
}
