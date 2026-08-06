/// OR-301+ — Universal Frequency premium glass card.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'reading_premium_animations.dart';
import 'reading_premium_utils.dart';

class ReadingUniversalFrequencyCard extends StatefulWidget {
  const ReadingUniversalFrequencyCard({
    super.key,
    required this.data,
    required this.index,
    required this.master,
    this.exitProgress = 0,
  });

  final UniversalFrequencyData data;
  final int index;
  final double master;
  final double exitProgress;

  @override
  State<ReadingUniversalFrequencyCard> createState() =>
      _ReadingUniversalFrequencyCardState();
}

class _ReadingUniversalFrequencyCardState
    extends State<ReadingUniversalFrequencyCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
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
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final glow = 0.4 + sin(_pulse.value * pi * 2) * 0.2;
              return Container(
                padding: AppSpacing.card,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.lg,
                  color: AppColors.surface.withValues(alpha: 0.36),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.22 + glow * 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purpleGlow.withValues(alpha: 0.08),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Universal Frequency',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.goldLight,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    _Divider(glow: glow),
                    _Row(
                      icon: Icons.graphic_eq_rounded,
                      label: 'Frequency',
                      value: '${widget.data.frequencyHz} Hz',
                    ),
                    _Divider(glow: glow),
                    _Row(
                      icon: Icons.visibility_rounded,
                      label: 'Intuition',
                      value: '${widget.data.intuitionPercent}%',
                    ),
                    _Divider(glow: glow),
                    _Row(
                      icon: Icons.nightlight_round,
                      label: 'Moon Phase',
                      value: widget.data.moonPhase,
                    ),
                    _Divider(glow: glow),
                    _Row(
                      icon: Icons.schedule_rounded,
                      label: 'Lucky Hour',
                      value: widget.data.luckyHour,
                    ),
                    _Divider(glow: glow),
                    _Row(
                      icon: Icons.tag_rounded,
                      label: 'Lucky Number',
                      value: '${widget.data.luckyNumber}',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.glow});

  final double glow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.transparent,
              AppColors.gold.withValues(alpha: 0.15 + glow * 0.2),
              AppColors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.gold.withValues(alpha: 0.8)),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.goldLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
