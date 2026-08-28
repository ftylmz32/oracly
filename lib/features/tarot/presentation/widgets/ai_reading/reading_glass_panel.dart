/// OR-1060 — Premium glass reading panel with light sweep.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/oracly_quiet_motion.dart';
import 'ai_reading_content.dart';
import 'reading_glass_body.dart';

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
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _shimmer);
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = OraclyQuietMotion.still(context);
    final glass = ReadingGlassBody(
      content: widget.content,
      sectionMaster: widget.sectionMaster,
      useBackdrop: !OraclyQuietMotion.constrained(context),
    );
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
          child: still
              ? glass
              : AnimatedBuilder(
                  animation: _shimmer,
                  child: glass,
                  builder: (context, child) {
                    final sweep = sin(_shimmer.value * pi * 2) * 0.5 + 0.5;
                    return Stack(
                      children: [
                        child!,
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
                    );
                  },
                ),
        ),
      ),
    );
  }
}
