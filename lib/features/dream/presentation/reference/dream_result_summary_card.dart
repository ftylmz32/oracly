/// Dream result summary — date, narrative, edit action.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_asset_image.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../copy/dream_copy.dart';
import '../../models/dream.dart';
import '../utils/dream_history_labels.dart';
import 'dream_reference_tokens.dart';

class DreamResultSummaryCard extends StatelessWidget {
  const DreamResultSummaryCard({
    super.key,
    required this.dream,
    this.onEdit,
  });

  final Dream dream;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final narrative = dream.narrative.trim();
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: OraclyChrome.cardSurface.withValues(alpha: 0.14),
        border: Border.all(
          color: OraclyChrome.gold.withValues(alpha: 0.16),
          width: 0.6,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: DreamReferenceTokens.recentThumbRadius,
                  child: OraclyAssetImage(
                    assetPath: AppAssets.homeDream,
                    width: DreamReferenceTokens.recentThumbSize,
                    height: DreamReferenceTokens.recentThumbSize,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DreamHistoryLabels.dateLabel(dream.recordedAt),
                        style: ReadingTypography.micro(
                          color: OraclyChrome.cream.withValues(alpha: 0.58),
                        ),
                      ),
                      SizedBox(height: AppSpacing.s4),
                      Text(
                        narrative,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: ReadingTypography.bodySmall(
                          color: OraclyChrome.cream.withValues(alpha: 0.86),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (onEdit != null) ...[
              SizedBox(height: AppSpacing.sm),
              OraclyPressable(
                onTap: onEdit,
                child: Text(
                  '🪄 ${DreamCopy.resultEdit} ✎',
                  style: ReadingTypography.footnote(
                    color: OraclyChrome.goldLight.withValues(alpha: 0.82),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
