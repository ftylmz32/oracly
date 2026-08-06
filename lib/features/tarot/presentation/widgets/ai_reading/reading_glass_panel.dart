/// OR-1060 — Premium glass reading panel with light sweep.
library;

import 'dart:math' show pi, sin;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/copy/transparency_copy.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/reading_typography.dart';
import '../../../../../core/theme/oracly_brand_signature.dart';
import '../../../../../core/widgets/transparency_footnote.dart';
import 'ai_reading_content.dart';
import 'reading_or_orb.dart';
import 'reading_section_tile.dart';

class ReadingGlassPanel extends StatefulWidget {
  const ReadingGlassPanel({
    super.key,
    required this.content,
    required this.sectionMaster,
    required this.panelOpacity,
  });

  final AiReadingContent content;
  final double sectionMaster;
  final double panelOpacity;

  @override
  State<ReadingGlassPanel> createState() => _ReadingGlassPanelState();
}

class _ReadingGlassPanelState extends State<ReadingGlassPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        final sweep = sin(_shimmer.value * pi * 2) * 0.5 + 0.5;
        return Opacity(
          opacity: widget.panelOpacity,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: AppRadius.lg,
              boxShadow: AppShadows.card,
            ),
            child: ClipRRect(
              borderRadius: AppRadius.lg,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: OraclySignatureMaterials.blurChamber,
                  sigmaY: OraclySignatureMaterials.blurChamber,
                ),
                child: Stack(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.surfaceElevated.withValues(alpha: 0.94),
                            AppColors.surface.withValues(alpha: 0.88),
                          ],
                        ),
                        borderRadius: AppRadius.lg,
                        border: Border.all(
                          color: AppColors.gold.withValues(
                            alpha: OraclySignatureMaterials.goldBorder,
                          ),
                          width: AppBorderWidth.hairline,
                        ),
                      ),
                      child: Padding(
                        padding: AppSpacing.card,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const ReadingOrOrb(size: 32),
                                SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'OR Yorumu',
                                        style: AppTextStyles.titleSmall.copyWith(
                                          color: AppColors.goldLight,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: AppSpacing.xs),
                                      Text(
                                        TransparencyCopy.interpretationBrief,
                                        style: ReadingTypography.footnote(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: AppSpacing.lg),
                            ReadingSectionTile(
                              title: widget.content.cardName,
                              body: widget.content.tagline,
                              progress: readingSectionProgress(0, widget.sectionMaster),
                              icon: Icons.style_rounded,
                            ),
                            ReadingSectionTile(
                              title: 'Genel Anlam',
                              body: widget.content.generalMeaning,
                              progress: readingSectionProgress(1, widget.sectionMaster),
                              icon: Icons.auto_awesome_rounded,
                            ),
                            ReadingSectionTile(
                              title: 'Aşk',
                              body: widget.content.love,
                              progress: readingSectionProgress(2, widget.sectionMaster),
                              icon: Icons.favorite_rounded,
                            ),
                            ReadingSectionTile(
                              title: 'Kariyer',
                              body: widget.content.career,
                              progress: readingSectionProgress(3, widget.sectionMaster),
                              icon: Icons.work_outline_rounded,
                            ),
                            ReadingSectionTile(
                              title: 'Para',
                              body: widget.content.money,
                              progress: readingSectionProgress(4, widget.sectionMaster),
                              icon: Icons.payments_outlined,
                            ),
                            ReadingSectionTile(
                              title: 'Ruhsal Rehberlik',
                              body: widget.content.spiritualGuidance,
                              progress: readingSectionProgress(5, widget.sectionMaster),
                              icon: Icons.self_improvement_rounded,
                            ),
                            ReadingSectionTile(
                              title: 'Şanslı Enerji',
                              body: widget.content.luckyEnergy,
                              progress: readingSectionProgress(6, widget.sectionMaster),
                              icon: Icons.bolt_rounded,
                            ),
                            ReadingSectionTile(
                              title: 'Günlük Tavsiye',
                              body: widget.content.dailyAdvice,
                              progress: readingSectionProgress(7, widget.sectionMaster),
                              icon: Icons.wb_twilight_rounded,
                            ),
                            const TransparencyFootnote(
                              padding: EdgeInsets.only(top: AppSpacing.md),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(-1 + sweep * 2, -0.8),
                              end: Alignment(-0.4 + sweep * 2, 0.6),
                              colors: [
                                AppColors.transparent,
                                AppColors.white.withValues(alpha: 0.04),
                                AppColors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
