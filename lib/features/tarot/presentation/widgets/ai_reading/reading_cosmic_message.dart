/// OR-301 — Mystical cosmic message with animated border.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../../../../core/copy/reading_section_copy.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/reading_typography.dart';
import 'reading_flow_text.dart';
import 'reading_premium_animations.dart';

class ReadingCosmicMessage extends StatefulWidget {
  const ReadingCosmicMessage({
    super.key,
    required this.message,
    required this.index,
    required this.master,
    this.exitProgress = 0,
  });

  final String message;
  final int index;
  final double master;
  final double exitProgress;

  @override
  State<ReadingCosmicMessage> createState() => _ReadingCosmicMessageState();
}

class _ReadingCosmicMessageState extends State<ReadingCosmicMessage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        readingPremiumReflectionProgress(widget.index, widget.master);
    final slide = (1 - progress) * 14;

    return Opacity(
      opacity: (progress * (1 - widget.exitProgress)).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, slide + widget.exitProgress * 14),
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final glow = 0.28 + sin(_pulse.value * pi * 2) * 0.12;
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg + 4,
                  vertical: AppSpacing.lg + 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.lg,
                  color: AppColors.surface.withValues(alpha: 0.32),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.18 + glow * 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purpleGlow.withValues(alpha: glow * 0.14),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final twinkle =
                            0.35 + sin(_pulse.value * pi * 2 + i * 1.4) * 0.25;
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          child: Icon(
                            Icons.star_rounded,
                            size: 8,
                            color: AppColors.goldLight
                                .withValues(alpha: 0.22 + twinkle * 0.28),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      ReadingSectionCopy.closing,
                      style: ReadingTypography.sectionLabel(
                        color: AppColors.goldLight.withValues(alpha: 0.82),
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg - AppSpacing.xs),
                    ReadingFlowText(
                      text: readingCompleteSentence(widget.message),
                      textAlign: TextAlign.center,
                      style: ReadingTypography.closing(
                        color: AppColors.textSecondary.withValues(alpha: 0.90),
                      ),
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
