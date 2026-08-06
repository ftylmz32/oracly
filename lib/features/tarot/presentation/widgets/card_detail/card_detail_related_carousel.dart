/// OR-1080 — Related cards horizontal carousel.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/oracly_pressable.dart';
import 'card_detail_catalogue.dart';
import 'card_detail_models.dart';

class CardDetailRelatedCarousel extends StatelessWidget {
  const CardDetailRelatedCarousel({
    super.key,
    required this.relatedIds,
    required this.entrance,
    required this.onCardTap,
  });

  final List<int> relatedIds;
  final double entrance;
  final ValueChanged<CardDetailContent> onCardTap;

  @override
  Widget build(BuildContext context) {
    final slide = (1 - entrance) * 18;
    final cards = relatedIds.map(CardDetailCatalogue.forId).toList();

    return Opacity(
      opacity: entrance.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, slide),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'İlgili Kartlar',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                clipBehavior: Clip.none,
                itemCount: cards.length,
                separatorBuilder: (_, _) => SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  return _RelatedCard(
                    content: cards[index],
                    onTap: () => onCardTap(cards[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RelatedCard extends StatelessWidget {
  const _RelatedCard({
    required this.content,
    required this.onTap,
  });

  final CardDetailContent content;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
          width: 120,
          child: ClipRRect(
            borderRadius: AppRadius.lg,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.surfaceElevated.withValues(alpha: 0.92),
                      AppColors.surface.withValues(alpha: 0.84),
                    ],
                  ),
                  borderRadius: AppRadius.lg,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.28),
                    width: AppBorderWidth.hairline,
                  ),
                  boxShadow: AppShadows.soft,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Hero(
                        tag: content.heroTag,
                        child: Image.asset(
                          content.imageAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => ColoredBox(
                            color: AppColors.purpleDark,
                            child: Icon(
                              Icons.style_rounded,
                              color: content.accentColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: Text(
                        content.displayNameTr,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.goldLight,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }
}
