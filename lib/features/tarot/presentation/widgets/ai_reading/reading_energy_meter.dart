/// OR-301+ — Premium energy bars with shimmer and inner glow.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/reading_typography.dart';
import 'reading_premium_animations.dart';
import 'reading_sacred_rhythm.dart';

class ReadingEnergyMeter extends StatefulWidget {
  const ReadingEnergyMeter({
    super.key,
    required this.love,
    required this.career,
    required this.spiritual,
    required this.index,
    required this.master,
    this.exitProgress = 0,
  });

  final double love;
  final double career;
  final double spiritual;
  final int index;
  final double master;
  final double exitProgress;

  @override
  State<ReadingEnergyMeter> createState() => _ReadingEnergyMeterState();
}

class _ReadingEnergyMeterState extends State<ReadingEnergyMeter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = readingPremiumSectionProgress(widget.index, widget.master);
    final slide = (1 - progress) * 24;

    return Opacity(
      opacity: (progress * (1 - widget.exitProgress)).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, slide + widget.exitProgress * 18),
        child: Padding(
          padding: EdgeInsets.only(bottom: ReadingSacredRhythm.sectionBottom),
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _shimmer,
              builder: (context, _) {
                return Container(
                  padding: AppSpacing.card,
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.lg,
                    color: AppColors.surface.withValues(alpha: 0.42),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enerji Akışı',
                        style: ReadingTypography.sectionLabel(
                          color: AppColors.goldLight.withValues(alpha: 0.86),
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      _PremiumEnergyBar(
                        label: 'Aşk Enerjisi',
                        value: widget.love * progress,
                        color: const Color(0xFFE879A8),
                        shimmer: _shimmer.value,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      _PremiumEnergyBar(
                        label: 'Kariyer Enerjisi',
                        value: widget.career * progress,
                        color: AppColors.gold,
                        shimmer: _shimmer.value + 0.33,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      _PremiumEnergyBar(
                        label: 'Ruhsal Enerji',
                        value: widget.spiritual * progress,
                        color: AppColors.purpleLight,
                        shimmer: _shimmer.value + 0.66,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumEnergyBar extends StatelessWidget {
  const _PremiumEnergyBar({
    required this.label,
    required this.value,
    required this.color,
    required this.shimmer,
  });

  final String label;
  final double value;
  final Color color;
  final double shimmer;

  @override
  Widget build(BuildContext context) {
    final factor = value.clamp(0.0, 1.0);
    final lightPos = shimmer % 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: ReadingTypography.sectionLabel(
                fontSize: 11,
                color: AppColors.textMuted.withValues(alpha: 0.88),
              ),
            ),
            Text(
              '${(factor * 100).round()}%',
              style: ReadingTypography.sectionLabel(
                fontSize: 11,
                color: AppColors.goldLight.withValues(alpha: 0.86),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: AppRadius.round,
          child: SizedBox(
            height: 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.65),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: factor,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.55),
                          color,
                          color.withValues(alpha: 0.85),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FractionallySizedBox(
                          alignment: Alignment(-1 + lightPos * 2.5, 0),
                          widthFactor: 0.35,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: 0.35),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
