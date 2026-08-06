/// OR-301+ — Living tarot card: float, breath scale, soft glow pulse.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/oracly_brand_signature.dart';
import 'reading_element_theme.dart';
import 'reading_header_ambience.dart';

class ReadingBreathingCard extends StatefulWidget {
  const ReadingBreathingCard({
    super.key,
    required this.imageAsset,
    required this.elementTheme,
    this.rarityColor = AppColors.purple,
    this.width = 88,
    this.active = true,
  });

  final String imageAsset;
  final ReadingElementTheme elementTheme;
  final Color rarityColor;
  final double width;
  final bool active;

  @override
  State<ReadingBreathingCard> createState() => _ReadingBreathingCardState();
}

class _ReadingBreathingCardState extends State<ReadingBreathingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _life;

  @override
  void initState() {
    super.initState();
    _life = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );
    if (widget.active) _life.repeat();
  }

  @override
  void didUpdateWidget(covariant ReadingBreathingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_life.isAnimating) {
      _life.repeat();
    } else if (!widget.active && _life.isAnimating) {
      _life.stop();
    }
  }

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.width * 1.55;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = (widget.width * dpr).round();
    final cacheH = (height * dpr).round();

    return RepaintBoundary(
      child: SizedBox(
        width: widget.width,
        height: height,
        child: AnimatedBuilder(
          animation: _life,
          child: _CardArt(
            imageAsset: widget.imageAsset,
            elementTheme: widget.elementTheme,
            rarityColor: widget.rarityColor,
            width: widget.width,
            height: height,
            cacheWidth: cacheW,
            cacheHeight: cacheH,
          ),
          builder: (context, child) {
            final t = widget.active ? _life.value : 0.0;
            final floatY = widget.active ? sin(t * pi * 2) * 2.2 : 0.0;
            final scale =
                widget.active ? 0.994 + sin(t * pi * 2) * 0.006 : 1.0;
            final glow = widget.active
                ? 0.5 + sin(t * pi * 2 + 0.4) * 0.35
                : 0.5;

            return Transform.translate(
              offset: Offset(0, floatY),
              child: Transform.scale(
                scale: scale,
                child: Stack(
                  clipBehavior: Clip.none,
                  fit: StackFit.expand,
                  children: [
                    ReadingHeaderAmbience(
                      theme: widget.elementTheme,
                      phase: t,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.md,
                        border: Border.all(
                          color: OraclySignaturePalette.goldEngrave(0.72),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.elementTheme.glowColor
                                .withValues(alpha: 0.08 + glow * 0.10),
                            blurRadius: 18 + glow * 6,
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 16,
                            offset: Offset(
                              0,
                              widget.active ? 8 + sin(t * pi * 2) * 2 : 8,
                            ),
                          ),
                          ...AppShadows.soft,
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadius.md,
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CardArt extends StatelessWidget {
  const _CardArt({
    required this.imageAsset,
    required this.elementTheme,
    required this.rarityColor,
    required this.width,
    required this.height,
    required this.cacheWidth,
    required this.cacheHeight,
  });

  final String imageAsset;
  final ReadingElementTheme elementTheme;
  final Color rarityColor;
  final double width;
  final double height;
  final int cacheWidth;
  final int cacheHeight;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          imageAsset,
          fit: BoxFit.cover,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          errorBuilder: (context, error, stackTrace) =>
              _ArtFallback(color: rarityColor),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x1FFFFFFF),
                Colors.transparent,
                Color(0x2E000000),
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: FractionallySizedBox(
            heightFactor: 0.22,
            widthFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: OraclySignatureReflection.topSpecular(
                  intensity: 0.85,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArtFallback extends StatelessWidget {
  const _ArtFallback({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.45),
            AppColors.purpleDark,
            AppColors.primary,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          color: AppColors.goldLight,
          size: 36,
        ),
      ),
    );
  }
}
