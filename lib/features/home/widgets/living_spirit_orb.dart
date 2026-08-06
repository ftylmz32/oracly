import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'orb_models.dart';
import 'spirit_orb_painter.dart';

/// Living Spirit Orb — ORACLY identity widget.
///
/// Drives [SpiritOrbPainter] with eight visual layers:
/// 1 outer atmospheric glow · 2 purple aura · 3 soft fog · 4 main sphere
/// 5 inner energy · 6 glass reflection · 7 floating particles · 8 celestial ring
class LivingSpiritOrb extends StatefulWidget {
  const LivingSpiritOrb({super.key, this.size = 220, this.onBreath});

  final double size;
  final ValueChanged<double>? onBreath;

  @override
  State<LivingSpiritOrb> createState() => _LivingSpiritOrbState();
}

class _LivingSpiritOrbState extends State<LivingSpiritOrb>
    with TickerProviderStateMixin {
  static const _canvasPad = 120.0;

  late final AnimationController _breath;
  late final AnimationController _ring;
  late final AnimationController _float;
  late final AnimationController _drift;
  late final Animation<double> _scale;
  late final Animation<double> _core;
  late final Animation<double> _haze;
  late final Animation<double> _lift;
  late final List<OrbWisp> _wisps;
  late final List<OrbParticle> _particles;

  double get _canvasExtent => widget.size + _canvasPad;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    )..repeat(reverse: true);
    _breath.addListener(_emitBreath);

    final breathCurve = CurvedAnimation(parent: _breath, curve: Curves.easeInOutCubic);
    _scale = Tween<double>(begin: 0.985, end: 1.025).animate(breathCurve);
    _core = Tween<double>(begin: 0.72, end: 0.94).animate(breathCurve);
    _haze = Tween<double>(begin: 0.12, end: 0.20).animate(breathCurve);

    _ring = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 48),
    )..repeat();

    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);
    _lift = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _float, curve: Curves.easeInOutCubic),
    );

    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 90),
    )..repeat();

    _wisps = _buildWisps();
    _particles = _buildParticles();
  }

  List<OrbWisp> _buildWisps() {
    final r = math.Random(31);
    return List.generate(12, (i) {
      return OrbWisp(
        i * 0.52 + r.nextDouble() * 0.08,
        0.10 + r.nextDouble() * 0.38,
        0.42 + r.nextDouble() * 0.28,
        r.nextDouble() * math.pi * 2,
        0.06 + r.nextDouble() * 0.10,
      );
    });
  }

  List<OrbParticle> _buildParticles() {
    final r = math.Random(47);
    final out = <OrbParticle>[];

    for (var i = 0; i < 40; i++) {
      final a = r.nextDouble() * math.pi * 2;
      final rad = 0.04 + r.nextDouble() * 0.30;
      out.add(_particle(r, math.cos(a) * rad, math.sin(a) * rad, inner: true));
    }
    for (var i = 0; i < 16; i++) {
      final a = r.nextDouble() * math.pi * 2;
      final rad = 0.32 + r.nextDouble() * 0.26;
      out.add(_particle(r, math.cos(a) * rad, math.sin(a) * rad, inner: true));
    }
    for (var i = 0; i < 8; i++) {
      out.add(_particle(
        r,
        0,
        0.68 + r.nextDouble() * 0.28,
        inner: false,
        orbit: true,
      ));
    }
    return out;
  }

  OrbParticle _particle(
    math.Random r,
    double dx,
    double dy, {
    required bool inner,
    bool orbit = false,
  }) {
    return OrbParticle(
      dx,
      dy,
      r.nextDouble() * math.pi * 2,
      0.03 + r.nextDouble() * 0.07,
      inner ? 0.35 + r.nextDouble() * 0.55 : 0.65 + r.nextDouble() * 0.75,
      r.nextDouble() < 0.15,
      orbit: orbit,
    );
  }

  void _emitBreath() {
    widget.onBreath?.call(_breath.value);
  }

  @override
  void dispose() {
    _breath.removeListener(_emitBreath);
    _breath.dispose();
    _ring.dispose();
    _float.dispose();
    _drift.dispose();
    super.dispose();
  }

  double get _combinedDrift =>
      _breath.value * math.pi * 2 + _drift.value * math.pi * 0.35;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: _canvasExtent,
        height: _canvasExtent,
        child: AnimatedBuilder(
          animation: Listenable.merge([_breath, _ring, _float, _drift]),
          builder: (context, _) {
            return Transform.translate(
              offset: Offset(0, _lift.value),
              child: Transform.scale(
                scale: _scale.value,
                child: CustomPaint(
                  size: Size.square(_canvasExtent),
                  painter: SpiritOrbPainter(
                    sphereRadius: widget.size / 2,
                    coreGlow: _core.value,
                    hazeOpacity: _haze.value,
                    ringAngle: _ring.value * math.pi * 2,
                    drift: _combinedDrift,
                    wisps: _wisps,
                    particles: _particles,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
