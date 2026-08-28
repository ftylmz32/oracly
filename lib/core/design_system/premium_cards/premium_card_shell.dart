/// EPIC-023 — Layered premium card shell. All card variants compose this.
library;

import 'dart:math' show pi, sin;
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../widgets/oracly_signature_motifs.dart';
import '../cinematic_lighting/cinematic_lighting_painters.dart';
import '../micro_details/micro_detail_painters.dart';
import '../micro_details/micro_detail_tokens.dart';
import '../micro_details/micro_detail_widgets.dart';
import '../app_blur.dart';
import '../app_colors.dart';
import '../app_glows.dart';
import '../app_radius.dart';
import '../app_shadows.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import 'premium_card_effects.dart';
import 'premium_card_tokens.dart';

/// Cached decoration builder — avoids rebuilding shadow lists per frame.
abstract final class PremiumCardDecoration {
  PremiumCardDecoration._();

  static List<BoxShadow> shadowsFor(
    PremiumCardGlow glow, {
    double strength = 1.0,
    bool pressed = false,
  }) {
    final boost = pressed ? 1.18 : 1.0;
    return [
      ...AppShadows.luxury,
      ...switch (glow) {
        PremiumCardGlow.none => const <BoxShadow>[],
        PremiumCardGlow.small => AppGlows.small(strength: strength * boost),
        PremiumCardGlow.medium => AppGlows.medium(strength: strength * boost),
        PremiumCardGlow.large => AppGlows.large(strength: strength * boost),
        PremiumCardGlow.hero => AppGlows.hero(strength: strength * boost),
      },
    ];
  }
}

/// The physical card frame — gradient, glass, glow, border, depth, interaction.
class PremiumCardShell extends StatefulWidget {
  const PremiumCardShell({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
    this.glow = PremiumCardGlow.medium,
    this.tier = PremiumCardTier.standard,
    this.useGlassBlur = true,
    this.showCorners = true,
    this.showShimmer = false,
    this.showParticles = false,
    this.gradient,
    this.width,
    this.height,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final PremiumCardGlow glow;
  final PremiumCardTier tier;
  final bool useGlassBlur;
  final bool showCorners;
  final bool showShimmer;
  final bool showParticles;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final Clip clipBehavior;

  @override
  State<PremiumCardShell> createState() => _PremiumCardShellState();
}

class _PremiumCardShellState extends State<PremiumCardShell>
    with TickerProviderStateMixin {
  late final AnimationController _ambient;
  late final AnimationController _sweep;
  late final int _sweepSeed;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _sweepSeed = Object.hash(widget.tier, widget.glow, widget.key);
    _ambient = AnimationController(
      vsync: this,
      duration: MicroDetailTokens.breathCycle,
    )..repeat(reverse: true);
    _sweep = AnimationController(
      vsync: this,
      duration: MicroDetailTokens.sweepDurationFor(_sweepSeed),
    )..repeat();
  }

  @override
  void dispose() {
    _ambient.dispose();
    _sweep.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    OraclyTouchFeedback.selection();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final radius =
        widget.borderRadius ?? PremiumCardTokens.radiusForTier(widget.tier);
    final glow = widget.glow == PremiumCardGlow.medium
        ? PremiumCardTokens.glowForTier(widget.tier)
        : widget.glow;
    final borderAlpha = _pressed ? 0.38 : 0.26;
    final scale = _pressed ? PremiumCardTokens.pressScale : 1.0;

    return AnimatedBuilder(
      animation: Listenable.merge([_ambient, _sweep]),
      builder: (context, _) {
        final phase = Curves.easeInOut.transform(_ambient.value);
        final sweepPhase = _sweep.value;
        final depthBreath =
            1.0 + math.sin(phase * math.pi * 2) * MicroDetailTokens.cardDepthBreath;

        return Transform.scale(
          scale: scale * depthBreath,
          child: _buildCard(radius, glow, borderAlpha, phase, sweepPhase),
        );
      },
    );
  }

  Widget _buildCard(
    BorderRadius radius,
    PremiumCardGlow glow,
    double borderAlpha,
    double phase,
    double sweepPhase,
  ) {
    final content = Padding(
      padding: widget.padding ?? PremiumCardTokens.paddingStandard,
      child: widget.child,
    );

    Widget layered = ClipRRect(
      borderRadius: radius,
      clipBehavior: widget.clipBehavior,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // Background animated gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: _animatedGradient(phase, widget.gradient),
              ),
            ),
          ),
          // Glass blur
          if (widget.useGlassBlur)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: AppBlur.glass,
                  sigmaY: AppBlur.glass,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.6 + sin(phase * pi * 2) * 0.08, -1),
                  end: Alignment(0.5, 1.1),
                  colors: [
                    AppColors.surfaceElevated.withValues(alpha: 0.92),
                    AppColors.surface.withValues(alpha: 0.88),
                    AppColors.background.withValues(alpha: 0.94),
                  ],
                  stops: const [0, 0.55, 1],
                ),
              ),
            ),
          ),
          // Inner glow
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.35 + sin(phase * pi * 2) * 0.05),
                    radius: 1.05,
                    colors: [
                      AppColors.glowGold.withValues(
                        alpha: (_pressed ? 0.14 : 0.10),
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // EPIC-026 — surface lighting: highlight, inner light, reflection, depth
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: CardSurfaceLightingPainter(
                  phase: phase,
                  pressed: _pressed,
                ),
              ),
            ),
          ),
          // EPIC-027 — micro sweep + moving highlight (always on)
          Positioned.fill(
            child: IgnorePointer(
              child: PremiumCardMicroLayer(
                ambientPhase: phase,
                sweepPhase: sweepPhase,
                borderRadius: radius,
              ),
            ),
          ),
          if (widget.showParticles)
            Positioned.fill(
              child: IgnorePointer(
                child: PremiumCardParticles(phase: phase),
              ),
            ),
          if (widget.showShimmer)
            Positioned.fill(
              child: IgnorePointer(
                child: PremiumCardShimmer(
                  phase: phase,
                  borderRadius: radius,
                  intensity: _pressed ? 0.16 : 0.10,
                ),
              ),
            ),
          if (widget.showCorners)
            Positioned.fill(
              child: OraclySignatureCornerOrnaments(
                inset: widget.tier == PremiumCardTier.hero ? 14 : 8,
                size: widget.tier == PremiumCardTier.hero ? 12 : 9,
                asPositionedFill: false,
              ),
            ),
          // Content
          content,
          // Press gold highlight
          if (_pressed)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.goldLight.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    final card = Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: AppColors.gold.withValues(alpha: borderAlpha + 0.06),
          width: AppBorderWidth.hairline,
        ),
        boxShadow: breathingCardShadows(
          base: [
            ...PremiumCardDecoration.shadowsFor(
              glow,
              pressed: _pressed,
            ),
            BoxShadow(
              color: AppColors.goldGlow.withValues(alpha: _pressed ? 0.12 : 0.08),
              blurRadius: 8,
              spreadRadius: -1,
              offset: const Offset(0, -1),
            ),
          ],
          breathPhase: phase,
          pressed: _pressed,
        ),
      ),
      child: layered,
    );

    if (widget.onTap == null) return card;

    return OraclyPressable(
      onTap: _handleTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      scale: false,
      depth: false,
      opacity: false,
      borderRadius: radius,
      child: card,
    );
  }

  Gradient _animatedGradient(double phase, Gradient? override) {
    if (override != null) return override;
    final shift = sin(phase * pi * 2) * 0.04;
    return LinearGradient(
      begin: Alignment(-0.5 + shift, -0.9),
      end: Alignment(0.6 - shift, 1),
      colors: [
        AppColors.surfaceElevated,
        AppColors.surface,
        AppColors.backgroundSecondary,
      ],
      stops: const [0, 0.52, 1],
    );
  }
}
