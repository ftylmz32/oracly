/// OR-401 / OR-407 / OR-418 / OR-419 — Sacred ritual spread selection card.
library;

import 'dart:math' show cos, sin;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import 'oracly_sacred_identity.dart';
import 'spread_card_living.dart';
import 'spread_sacred_identity.dart';
import 'spread_visual_style.dart';
import 'tarot_atmosphere.dart';
import 'tarot_home_data.dart';
import 'tarot_home_progressive_discovery.dart';

/// Crystal altar tile — each spread carries its own ritual identity.
class TarotSpreadCard extends StatefulWidget {
  const TarotSpreadCard({
    super.key,
    required this.option,
    this.selected = false,
    this.onTap,
    this.gridIndex = 0,
  });

  final TarotSpreadOption option;
  final bool selected;
  final VoidCallback? onTap;
  /// Grid position 0–3 for crystal-light proximity from Hero.
  final int gridIndex;

  static Duration get pressDuration => OraclyMotion.press;

  @override
  State<TarotSpreadCard> createState() => _TarotSpreadCardState();
}

class _TarotSpreadCardState extends State<TarotSpreadCard>
    with TickerProviderStateMixin {
  late final AnimationController _breath;
  late final AnimationController _press;
  late final Animation<double> _pressT;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: OraclyMotion.breath,
    );
    _press = AnimationController(
      vsync: this,
      duration: OraclyMotion.press,
    );
    _pressT = CurvedAnimation(parent: _press, curve: OraclyMotion.curve);
    _breath.value = (widget.gridIndex * 0.17) % 1.0;
    if (widget.selected) _breath.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant TarotSpreadCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !_breath.isAnimating) {
      _breath.repeat(reverse: true);
    } else if (!widget.selected && _breath.isAnimating) {
      _breath.stop();
      _breath.value = 0;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _press.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    HapticFeedback.lightImpact();
    _press.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _press.reverse();
  }

  void _onTapCancel() {
    _press.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.selected;
    final style = widget.option.visualStyle;
    final living = SpreadCardLiving.profile(style);
    final identity = TarotAtmosphere.identity(style);
    final sacred = SpreadSacredIdentity.profile(style);
    final presence = TarotAtmosphere.spreadGridPresence(
      widget.gridIndex,
      selected: active,
    );
    final ambientPhase =
        TarotHomeScrollScope.maybeOf(context)?.ambientPhase ?? 0;

    return AnimatedBuilder(
      animation: Listenable.merge([_breath, _pressT]),
      builder: (context, _) {
        final breathT = widget.selected ? _breath.value : 0.0;
        final pressT = _pressT.value;
        final pressed = pressT > 0.01;
        final planeScale = presence.scale *
            (1.0 - (1.0 - SpreadCardLiving.pressScale) * pressT);

        final borderAlpha = widget.selected
            ? 0.26 + breathT * 0.05 + pressT * 0.04
            : living.goldEngrave + pressT * 0.05;

        return GestureDetector(
          onTap: widget.onTap,
          onTapDown: widget.onTap != null ? _onTapDown : null,
          onTapUp: widget.onTap != null ? _onTapUp : null,
          onTapCancel: widget.onTap != null ? _onTapCancel : null,
          child: Transform.translate(
            offset: Offset(0, presence.liftY + pressT * 1.0),
            child: AnimatedScale(
              scale: planeScale,
              duration: OraclyMotion.press,
              curve: OraclyMotion.curve,
              child: AnimatedContainer(
                duration: OraclyMotion.press,
                curve: OraclyMotion.curve,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.lg,
                  boxShadow: SpreadCardLiving.altarShadows(
                    style: style,
                    pressed: pressed,
                    selected: widget.selected,
                    breathPhase: breathT,
                    depthMult: presence.shadowDepth,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.lg,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: OraclyCrystalBodyLayers(
                          lightTier: widget.selected
                              ? OraclyLightTier.upperChamber
                              : OraclyLightTier.midChamber,
                          borderRadius: AppRadius.lg,
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: AppRadius.lg,
                              gradient: TarotAtmosphere.spreadProximityLight(
                                widget.gridIndex,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: AppRadius.lg,
                              gradient: SpreadSacredIdentity.ambientTint(style),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: SpreadCardAtmospherePainter(
                              style: style,
                              phase: ambientPhase,
                              pressed: pressed,
                              pressT: pressT,
                            ),
                          ),
                        ),
                      ),
                      BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: SpreadCardLiving.glassBlur,
                          sigmaY: SpreadCardLiving.glassBlur,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.lg,
                            border: Border.all(
                              color: OraclySacredPalette.goldEngrave(borderAlpha),
                              width: widget.selected
                                  ? AppBorderWidth.thin + 0.15
                                  : AppBorderWidth.hairline + 0.45,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              OraclyRhythm.spreadCardInsetH,
                              OraclyRhythm.spreadCardInsetTop - 2,
                              OraclyRhythm.spreadCardInsetH,
                              OraclyRhythm.spreadCardInsetBottom - 4,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SpreadLayoutPreview(
                                  style: style,
                                  active: active,
                                  breathPhase: breathT,
                                  ambientPhase: ambientPhase,
                                ),
                                SizedBox(
                                  height: OraclyRhythm.sectionContentGap + 4,
                                ),
                                Text(
                                  widget.option.title,
                                  textAlign: TextAlign.center,
                                  style: SpreadSacredIdentity.titleStyle(
                                    style,
                                    selected: active,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: AppSpacing.sm),
                                Text(
                                  widget.option.description,
                                  textAlign: TextAlign.center,
                                  style: SpreadSacredIdentity.captionStyle(
                                    style,
                                    selected: active,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: SpreadCardGlassPainter(
                              style: style,
                              phase: ambientPhase,
                              pressed: pressed,
                              pressT: pressT,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: SpreadCardEngravedBorderPainter(
                              style: style,
                              phase: ambientPhase,
                              pressed: pressed,
                              pressT: pressT,
                              selected: active,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: SpreadSacredOrnamentPainter(
                              style: style,
                              phase: ambientPhase,
                              selected: active,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: SpreadCardAltarStarsPainter(
                              style: style,
                              phase: ambientPhase,
                            ),
                          ),
                        ),
                      ),
                      OraclyChampagneSpecular(
                        intensity: (active
                                ? 0.52
                                : 0.36 +
                                    identity.lightBias * 0.03 +
                                    presence.warmthBoost) +
                            pressT * 0.08,
                        horizontalInset: AppSpacing.lg - pressT * 2,
                        topOffset: pressT * 1.5,
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: SpreadCardLivingReflectionPainter(
                              phase: ambientPhase,
                              pressed: pressed,
                              pressT: pressT,
                            ),
                          ),
                        ),
                      ),
                      if (widget.selected)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _SelectedParticlesPainter(
                                phase: breathT,
                                density: sacred.particleDensity,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SelectedParticlesPainter extends CustomPainter {
  const _SelectedParticlesPainter({
    required this.phase,
    this.density = 1.0,
  });

  final double phase;
  final double density;

  static const _seeds = <(double a, double r, double s)>[
    (0.3, 0.42, 0.6),
    (2.9, 0.38, 0.5),
    (5.5, 0.44, 0.55),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.38;

    for (var i = 0; i < _seeds.length; i++) {
      final (a, r, dot) = _seeds[i];
      final drift = phase * 6.28 + a;
      final px = cx + cos(drift) * size.width * r * 0.35;
      final py = cy + sin(drift * 0.9) * size.height * r * 0.22;

      canvas.drawCircle(
        Offset(px, py),
        dot,
        Paint()
          ..color = OraclySacredPalette.champagne
              .withValues(alpha: (0.05 + phase * 0.03) * density),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SelectedParticlesPainter old) =>
      old.phase != phase || old.density != density;
}
