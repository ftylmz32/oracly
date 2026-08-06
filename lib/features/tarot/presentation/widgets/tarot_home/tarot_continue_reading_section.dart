/// OR-402 — Continue Reading section with crystal premium language.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers/app_providers.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../components/tarot_loading.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../utils/reading_history_mapper.dart';
import 'tarot_home_ornaments.dart';
import 'oracly_sacred_identity.dart';
import 'tarot_home_section_primitives.dart';

/// Recent readings — horizontal crystal ritual tiles.
class TarotContinueReadingSection extends ConsumerWidget {
  const TarotContinueReadingSection({
    super.key,
    this.onViewAll,
  });

  static const String _title = 'Okumaya Devam Et';

  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(readingHistoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TarotHomeSectionHeading(
          title: _title,
          trailing: onViewAll != null
              ? TarotHomeGhostButton(label: 'Tümü', onPressed: onViewAll)
              : null,
        ),
        SizedBox(height: OraclyRhythm.sectionContentGap),
        historyAsync.when(
          loading: () => TarotHomeSectionShell(
            lightTier: OraclyLightTier.midChamber,
            child: SizedBox(
              height: 120,
              child: TarotLoading(message: 'Son açılımlar dinleniyor...'),
            ),
          ),
          error: (_, _) => TarotHomeSectionShell(
            lightTier: OraclyLightTier.midChamber,
            child: SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'Son açılımlar şu an yüklenemedi.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
          data: (readings) {
            if (readings.isEmpty) return const SizedBox.shrink();
            final recent =
                readings.take(3).map(ReadingHistoryMapper.fromModel).toList();
            return SizedBox(
              height: 152,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.none,
                itemCount: recent.length,
                separatorBuilder: (_, _) =>
                    SizedBox(width: OraclyRhythm.carouselGap),
                itemBuilder: (context, index) {
                  final entry = recent[index];
                  return _RecentReadingCard(
                    title: entry.spreadType,
                    cardName: entry.cardName,
                    timeAgo: entry.dateLabel,
                    icon: entry.moodIcon,
                    onTap: onViewAll,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RecentReadingCard extends StatelessWidget {
  const _RecentReadingCard({
    required this.title,
    required this.cardName,
    required this.timeAgo,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String cardName;
  final String timeAgo;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TarotHomeCrystalTile(
      width: 204,
      height: 148,
      lightTier: OraclyLightTier.midChamber,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TarotHomeMysticIcon(
                icon: icon,
                size: 36,
                iconSize: 18,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: OraclyTypography.tileTitle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            cardName,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1.35,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            timeAgo,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.75),
              fontSize: 11,
              height: 1.5,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
