/// OR-1050+ — 3D flip card with depth, bloom, and premium back.
library;

import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../theme/tarot_tokens.dart';
import 'card_reveal_spread.dart';
import 'reveal_border_energy.dart';
import 'reveal_card_back.dart';

class RevealFlipCard extends StatelessWidget {
  const RevealFlipCard({
    super.key,
    required this.data,
    required this.flipRotation,
    required this.tilt3D,
    required this.perspectiveTiltY,
    required this.borderEnergy,
    required this.landScale,
    required this.shadowDepth,
    required this.goldOpacity,
    required this.artOpacity,
    required this.particlePhase,
    this.width = 168,
    this.height = 268,
  });

  final RevealCardData data;
  final double flipRotation;
  final double tilt3D;
  final double perspectiveTiltY;
  final double borderEnergy;
  final double landScale;
  final double shadowDepth;
  final double goldOpacity;
  final double artOpacity;
  final double particlePhase;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final showingFront = flipRotation >= pi / 2;
    final shadowBlur = 8 + shadowDepth * 28;
    const particlePad = 80.0;
    final stackWidth = width + particlePad;
    final stackHeight = height + particlePad;

    return Transform.scale(
      scale: landScale,
      child: SizedBox(
        width: stackWidth,
        height: stackHeight,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
          Transform.translate(
            offset: Offset(tilt3D * 12, height * 0.52),
            child: Transform.scale(
              scaleX: 0.82 + shadowDepth * 0.12,
              child: Container(
                width: width * 0.75,
                height: 14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45 * shadowDepth),
                      blurRadius: shadowBlur,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0018)
              ..rotateX(tilt3D * 0.38)
              ..rotateZ(perspectiveTiltY * 0.5)
              ..rotateY(flipRotation),
            child: showingFront
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(pi),
                    child: _CardFront(
                      data: data,
                      width: width,
                      height: height,
                      goldOpacity: goldOpacity,
                      artOpacity: artOpacity,
                    ),
                  )
                : RevealPremiumCardBack(
                    width: width,
                    height: height,
                    elevation: 0.92,
                    particlePhase: particlePhase,
                  ),
          ),
          RevealBorderEnergy(
            progress: borderEnergy,
            width: width,
            height: height,
          ),
        ],
        ),
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({
    required this.data,
    required this.width,
    required this.height,
    required this.goldOpacity,
    required this.artOpacity,
  });

  final RevealCardData data;
  final double width;
  final double height;
  final double goldOpacity;
  final double artOpacity;

  @override
  Widget build(BuildContext context) {
    final radius = TarotTokens.cardCornerRadius;
    final innerRadius = radius - 1;
    final gold = goldOpacity.clamp(0.0, 1.0);
    final art = artOpacity.clamp(0.0, 1.0);

    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: AppColors.purpleDark.withValues(alpha: 0.92 * gold),
          boxShadow: [
            BoxShadow(
              color: AppColors.goldGlow.withValues(alpha: 0.14 * gold),
              blurRadius: 14,
              spreadRadius: 0,
            ),
            ...AppShadows.soft,
          ],
          border: Border.all(
            color: AppColors.gold.withValues(alpha: (0.55 + gold * 0.28).clamp(0.0, 1.0)),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(innerRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: art,
                child: SizedBox.expand(
                  child: Image.asset(
                    data.imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _ArtFallback(data: data),
                  ),
                ),
              ),
              if (gold > 0.02 && art < 0.85)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.12),
                        radius: 0.95,
                        colors: [
                          AppColors.goldLight.withValues(alpha: 0.10 * gold),
                          AppColors.gold.withValues(alpha: 0.06 * gold),
                          AppColors.purpleDark.withValues(alpha: 0.35 * gold),
                        ],
                        stops: const [0.0, 0.38, 1.0],
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Opacity(
                  opacity: art,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.white.withValues(alpha: 0.08),
                          AppColors.transparent,
                          Colors.black.withValues(alpha: 0.14),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: height * 0.22,
                child: Opacity(
                  opacity: art * 0.85,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.white.withValues(alpha: 0.10),
                          AppColors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtFallback extends StatelessWidget {
  const _ArtFallback({required this.data});

  final RevealCardData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              data.rarityColor.withValues(alpha: 0.45),
              AppColors.purpleDark,
              AppColors.primary,
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 48,
            color: AppColors.goldLight.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}
