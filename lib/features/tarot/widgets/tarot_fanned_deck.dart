/// OR-1021 — Cinematic layered tarot deck centerpiece.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import 'tarot_card_back_painter.dart';

class TarotFannedDeck extends StatefulWidget {
  const TarotFannedDeck({
    super.key,
    this.cardCount = 7,
    this.cardWidth = 76,
    this.cardHeight = 124,
    this.opacity = 1,
  });

  final int cardCount;
  final double cardWidth;
  final double cardHeight;
  final double opacity;

  @override
  State<TarotFannedDeck> createState() => _TarotFannedDeckState();
}

class _TarotFannedDeckState extends State<TarotFannedDeck>
    with TickerProviderStateMixin {
  late final AnimationController _float;
  late final AnimationController _breath;

  static const _stackDepth = 13;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7200),
    )..repeat(reverse: true);
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_float, _breath]),
      builder: (context, _) {
        final lift = (_float.value - 0.5) * 4;
        final breathScale = 1 + (_breath.value - 0.5) * 0.022;
        final glow = 0.5 + sin(_breath.value * pi * 2) * 0.22;
        final sway = sin(_float.value * pi * 2) * 0.011;

        return Opacity(
          opacity: widget.opacity,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(-0.06)
              ..rotateZ(sway),
            child: Transform.translate(
              offset: Offset(0, lift),
              child: Transform.scale(
                scale: breathScale,
                child: RepaintBoundary(
                  child: SizedBox(
                    width: 280,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          bottom: 12,
                          child: _DeckGlow(intensity: glow),
                        ),
                        Positioned(
                          bottom: 8,
                          child: _LayeredStack(
                            cardWidth: widget.cardWidth - 6,
                            cardHeight: widget.cardHeight - 10,
                            depth: _stackDepth,
                          ),
                        ),
                        for (var i = 0; i < widget.cardCount; i++) _fanCard(i),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _fanCard(int i) {
    final mid = (widget.cardCount - 1) / 2;
    final t = mid == 0 ? 0.0 : (i - mid) / mid;
    final angle = t * 0.34;
    final dx = t * 34;
    final lift = i * 2.2;
    final perspectiveSkew = t * 0.018;

    return Positioned(
      bottom: 16 + lift,
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()
          ..translateByDouble(dx, -lift * 0.32, 0, 1)
          ..rotateZ(angle + perspectiveSkew),
        child: _TarotCardFace(
          width: widget.cardWidth,
          height: widget.cardHeight,
          elevation: 0.74 + (i / widget.cardCount) * 0.26,
        ),
      ),
    );
  }
}

class _DeckGlow extends StatelessWidget {
  const _DeckGlow({required this.intensity});

  final double intensity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 228,
        height: 96,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.purpleGlow.withValues(alpha: 0.22 * intensity),
              blurRadius: 64,
              spreadRadius: 10,
            ),
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.16 * intensity),
              blurRadius: 44,
              spreadRadius: 6,
            ),
            BoxShadow(
              color: AppColors.goldGlow.withValues(alpha: 0.28 * intensity),
              blurRadius: 24,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _LayeredStack extends StatelessWidget {
  const _LayeredStack({
    required this.cardWidth,
    required this.cardHeight,
    required this.depth,
  });

  final double cardWidth;
  final double cardHeight;
  final int depth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cardWidth + 16,
      height: cardHeight * 0.52 + depth * 1.55,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < depth; i++)
            Positioned(
              bottom: i * 1.55,
              left: (depth - i) * 0.32,
              right: (depth - i) * 0.32,
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..rotateZ((i - depth / 2) * 0.002),
                child: _TarotCardFace(
                  width: cardWidth - i * 0.12,
                  height: cardHeight - i * 0.38,
                  elevation: i / depth,
                  compact: true,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TarotCardFace extends StatelessWidget {
  const _TarotCardFace({
    required this.width,
    required this.height,
    required this.elevation,
    this.compact = false,
  });

  final double width;
  final double height;
  final double elevation;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final edge = 1.2 + elevation * 1.6;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5 + elevation * 0.18),
            blurRadius: 10 + elevation * 12,
            offset: Offset(0, 4 + elevation * 5),
          ),
          if (!compact)
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.14 + elevation * 0.14),
              blurRadius: 14,
              spreadRadius: 0.5,
            ),
          ...AppShadows.soft,
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gold.withValues(alpha: 0.22 + elevation * 0.12),
            AppColors.gold.withValues(alpha: 0.38 + elevation * 0.1),
            const Color(0xFF8B6914).withValues(alpha: 0.62),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(0.85),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF162440), Color(0xFF0A1228), Color(0xFF050A14)],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.5),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: TarotCardBackPainter()),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: edge,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          AppColors.goldLight.withValues(alpha: 0.32),
                          AppColors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: edge * 0.75,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          Colors.black.withValues(alpha: 0.42),
                          AppColors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: const Alignment(-0.8, -1),
                        end: const Alignment(0.6, 0.4),
                        colors: [
                          AppColors.white.withValues(alpha: 0.09),
                          AppColors.transparent,
                          AppColors.transparent,
                        ],
                        stops: const [0.0, 0.35, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: height * 0.2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.white.withValues(alpha: 0.08),
                          AppColors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: height * 0.12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.28),
                          AppColors.transparent,
                        ],
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
  }
}
