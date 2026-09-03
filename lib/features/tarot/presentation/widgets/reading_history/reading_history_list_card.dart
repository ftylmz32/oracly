/// OR-1070 — Premium history journal list card.
library;

import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/oracly_brand_signature.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/reading_typography.dart';
import '../../../../../shared/widgets/oracly_pressable.dart';
import '../../../art/tarot_major_card_art.dart';
import 'reading_history_data.dart';
import 'reading_journal_keyword_chips.dart';

class ReadingHistoryListCard extends StatefulWidget {
  const ReadingHistoryListCard({
    super.key,
    required this.entry,
    required this.entrance,
    required this.onTap,
  });

  final ReadingHistoryEntry entry;
  final double entrance;
  final VoidCallback onTap;

  @override
  State<ReadingHistoryListCard> createState() => _ReadingHistoryListCardState();
}

class _ReadingHistoryListCardState extends State<ReadingHistoryListCard> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = _pressed || _hovered;
    final slide = (1 - widget.entrance) * 24;

    return Opacity(
      opacity: widget.entrance.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, slide),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: OraclyPressable(
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedOpacity(
              opacity: _hovered ? 0.98 : 1.0,
              duration: OraclySignatureMotion.pressRelease,
              curve: OraclySignatureMotion.releaseCurve,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.lg,
                  boxShadow: active
                      ? [
                          ...AppShadows.soft,
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.22),
                            blurRadius: 16,
                          ),
                        ]
                      : AppShadows.soft,
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.lg,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF120B1C).withValues(alpha: 0.96),
                          AppColors.surface.withValues(alpha: 0.82),
                          const Color(0xFF070510).withValues(alpha: 0.94),
                        ],
                      ),
                      borderRadius: AppRadius.lg,
                      border: Border.all(
                        color: AppColors.gold.withValues(
                          alpha: active ? 0.42 : 0.18,
                        ),
                        width: AppBorderWidth.hairline,
                      ),
                    ),
                    child: Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Hero(
                              tag: widget.entry.heroTag,
                              child: _Thumbnail(
                                imageAsset: widget.entry.cardImageAsset,
                                isReversed: widget.entry.isReversed,
                              ),
                            ),
                            SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        widget.entry.moodIcon,
                                        size: AppSpacing.md,
                                        color: AppColors.gold,
                                      ),
                                      SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          widget.entry.cardName,
                                          style: AppTextStyles.labelLarge.copyWith(
                                            color: AppColors.goldLight,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (widget.entry.isFavorite) ...[
                                        SizedBox(width: AppSpacing.xs),
                                        Icon(
                                          Icons.bookmark_rounded,
                                          size: 16,
                                          color: AppColors.goldLight.withValues(alpha: 0.82),
                                        ),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '${widget.entry.dateLabel} · ${widget.entry.timeLabel}',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                  SizedBox(height: AppSpacing.xs),
                                  Text(
                                    widget.entry.typeLabel,
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.purpleLight,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: AppSpacing.sm),
                                  ReadingJournalKeywordChips(
                                    keywords: widget.entry.emotionalKeywords,
                                    compact: true,
                                  ),
                                  if (widget.entry.hasPersonalNote) ...[
                                    SizedBox(height: AppSpacing.sm),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.edit_note_rounded,
                                          size: 16,
                                          color: AppColors.gold.withValues(alpha: 0.72),
                                        ),
                                        SizedBox(width: AppSpacing.xs),
                                        Expanded(
                                          child: Text(
                                            widget.entry.personalNote!.trim(),
                                            style: ReadingTypography.reflection(
                                              color: AppColors.goldLight,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  SizedBox(height: AppSpacing.sm),
                                  Text(
                                    widget.entry.timelineSummary,
                                    style: ReadingTypography.bodySmall(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.imageAsset,
    this.isReversed = false,
  });

  final String imageAsset;
  final bool isReversed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: AppRadius.sm,
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.42),
          width: AppBorderWidth.hairline,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldGlow.withValues(alpha: 0.22),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.sm,
        child: Transform.rotate(
          angle: isReversed ? pi : 0,
          child: TarotMajorCardArt(
            imageAsset: imageAsset,
            showChrome: false,
            fallback: ColoredBox(
              color: AppColors.purpleDark,
              child: Icon(
                Icons.style_rounded,
                color: AppColors.goldLight.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stagger entrance for list index.
double historyCardEntrance(int index, double master) {
  final start = index * 0.08;
  final end = start + 0.32;
  if (master <= start) return 0;
  if (master >= end) return 1;
  return Curves.easeOutCubic.transform(
    ((master - start) / (end - start)).clamp(0.0, 1.0),
  );
}
