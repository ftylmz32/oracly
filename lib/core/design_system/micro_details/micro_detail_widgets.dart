/// EPIC-027 — Reusable micro-detail widgets.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_typography.dart';
import '../cinematic_lighting/hero_light_spill.dart';
import '../../theme/oracly_quiet_motion.dart';
import '../../theme/oracly_reduced_motion.dart';
import 'micro_detail_painters.dart';
import 'micro_detail_tokens.dart';

/// Combined micro layer for every premium card.
class PremiumCardMicroLayer extends StatelessWidget {
  const PremiumCardMicroLayer({
    super.key,
    required this.ambientPhase,
    required this.sweepPhase,
    required this.borderRadius,
  });

  final double ambientPhase;
  final double sweepPhase;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: CardMovingHighlightPainter(phase: ambientPhase),
          ),
          CustomPaint(
            painter: CardMicroSweepPainter(sweepPhase: sweepPhase),
          ),
        ],
      ),
    );
  }
}

/// Fills large empty regions with barely visible life.
class MicroEmptyAmbience extends StatefulWidget {
  const MicroEmptyAmbience({
    super.key,
    required this.child,
    this.density = 18,
  });

  final Widget child;
  final int density;

  @override
  State<MicroEmptyAmbience> createState() => _MicroEmptyAmbienceState();
}

class _MicroEmptyAmbienceState extends State<MicroEmptyAmbience>
    with SingleTickerProviderStateMixin {
  late final AnimationController _phase;

  @override
  void initState() {
    super.initState();
    _phase = AnimationController(
      vsync: this,
      duration: MicroDetailTokens.breathCycle,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (OraclyReducedMotion.of(context)) {
      _phase.stop();
      _phase.value = 0.5;
    } else if (!_phase.isAnimating) {
      _phase.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.hasBoundedWidth && constraints.hasBoundedHeight;

        if (!bounded) {
          return widget.child;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
                    colors: [
                      AppColors.primaryPurple.withValues(alpha: 0.04),
                      AppColors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _phase,
                builder: (context, _) {
                  return CustomPaint(
                    painter: MicroEmptyParticlePainter(
                      phase: _phase.value,
                      density: widget.density,
                    ),
                  );
                },
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}

/// Large title with soft gradient and micro bloom — no harsh white.
class MicroLitTitle extends StatelessWidget {
  const MicroLitTitle({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.bloomStrength = 1.0,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final double bloomStrength;

  @override
  Widget build(BuildContext context) {
    final base = style ??
        AppTypography.headingM.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        );

    return LitTitle(
      bloomStrength: bloomStrength,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8EED0),
            Color(0xFFE8D4A0),
            Color(0xFFF4D58D),
          ],
          stops: [0.0, 0.5, 1.0],
        ).createShader(bounds),
        child: Text(
          text,
          style: base.copyWith(color: AppColors.textPrimary),
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: maxLines != null ? TextOverflow.ellipsis : null,
        ),
      ),
    );
  }
}

/// List item reveal — fade + slide with 15–25 ms desync stagger.
class MicroListReveal extends StatelessWidget {
  const MicroListReveal({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = Duration.zero,
  });

  final int index;
  final Widget child;
  final Duration baseDelay;

  @override
  Widget build(BuildContext context) {
    return _MicroListRevealItem(
      delay: baseDelay + MicroDetailTokens.listStaggerFor(index),
      child: child,
    );
  }
}

class _MicroListRevealItem extends StatefulWidget {
  const _MicroListRevealItem({
    required this.delay,
    required this.child,
  });

  final Duration delay;
  final Widget child;

  @override
  State<_MicroListRevealItem> createState() => _MicroListRevealItemState();
}

class _MicroListRevealItemState extends State<_MicroListRevealItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: MicroDetailCurve.breath,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(curved);

    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (OraclyReducedMotion.of(context)) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

/// Extremely slow parallax wrapper for background layers.
class MicroParallaxDrift extends StatefulWidget {
  const MicroParallaxDrift({
    super.key,
    required this.child,
    this.amplitude = MicroDetailTokens.parallaxAmplitude,
  });

  final Widget child;
  final double amplitude;

  @override
  State<MicroParallaxDrift> createState() => _MicroParallaxDriftState();
}

class _MicroParallaxDriftState extends State<MicroParallaxDrift>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: MicroDetailTokens.parallaxCycle,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _drift, reverse: true, rest: 0);
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (OraclyQuietMotion.still(context)) return widget.child;
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, child) {
        final t = _drift.value;
        final dx = math.sin(t * math.pi * 2) * widget.amplitude * 0.35;
        final dy = math.cos(t * math.pi * 2) * widget.amplitude * 0.25;
        return Transform.translate(
          offset: Offset(dx, dy),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
