/// History detail top chrome — back, title, favorite, hero thumb.
library;

import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_icons.dart';
import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/oracly_header_action.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../art/tarot_major_card_art.dart';
import '../widgets/reading_history/reading_history_data.dart';

class ReadingHistoryDetailHeader extends StatelessWidget {
  const ReadingHistoryDetailHeader({
    super.key,
    required this.entry,
    required this.isFavorite,
    required this.onBack,
    required this.onFavorite,
  });

  final ReadingHistoryEntry entry;
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.screenHorizontal,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          OraclyHeaderAction(
            icon: AppIcons.back,
            label: OraclyL10n.t(L10nKeys.back),
            onTap: onBack,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayTitle,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.goldLight,
                  ),
                ),
                Text(
                  '${entry.dateLabel} · ${entry.typeLabel}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          OraclyHeaderAction(
            icon: isFavorite
                ? Icons.bookmark_rounded
                : Icons.bookmark_outline_rounded,
            label: isFavorite
                ? OraclyL10n.t('tarot.memory.remove')
                : OraclyL10n.t('tarot.memory.add'),
            onTap: onFavorite,
          ),
          Hero(
            tag: entry.heroTag,
            child: ClipRRect(
              borderRadius: AppRadius.xs,
              child: SizedBox(
                width: 44,
                height: 64,
                child: Transform.rotate(
                  angle: entry.isReversed ? pi : 0,
                  child: TarotMajorCardArt(
                    imageAsset: entry.cardImageAsset,
                    showChrome: false,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
