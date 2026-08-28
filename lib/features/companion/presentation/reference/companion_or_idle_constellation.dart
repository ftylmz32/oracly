/// Subtle constellation — one opacity drift, no particle storm.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/oracly_quiet_motion.dart';
import 'companion_or_living_tokens.dart';

class CompanionOrIdleConstellation extends StatelessWidget {
  const CompanionOrIdleConstellation({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    if (OraclyQuietMotion.still(context)) {
      return IgnorePointer(
        child: CustomPaint(
          size: Size.square(size),
          painter: _ConstellationPainter(
            gold: OraclyChrome.gold.withValues(alpha: 0.20),
            cream: OraclyChrome.cream.withValues(alpha: 0.12),
            drift: 0.5,
          ),
        ),
      );
    }
    return _DriftingConstellation(size: size);
  }
}

class _DriftingConstellation extends StatefulWidget {
  const _DriftingConstellation({required this.size});

  final double size;

  @override
  State<_DriftingConstellation> createState() => _DriftingConstellationState();
}

class _DriftingConstellationState extends State<_DriftingConstellation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: CompanionOrLivingTokens.atmosphereDrift,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _drift,
        builder: (context, _) {
          final t = _drift.value;
          return CustomPaint(
            size: Size.square(widget.size),
            painter: _ConstellationPainter(
              gold: OraclyChrome.gold.withValues(alpha: 0.16 + t * 0.08),
              cream: OraclyChrome.cream.withValues(alpha: 0.10 + t * 0.06),
              drift: t,
            ),
          );
        },
      ),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  _ConstellationPainter({
    required this.gold,
    required this.cream,
    required this.drift,
  });

  final Color gold;
  final Color cream;
  final double drift;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * (0.41 + drift * 0.015);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = gold;
    canvas.drawCircle(c, r, ring);
    canvas.drawCircle(c, r * 0.62, ring..color = cream);

    final node = Paint()..color = gold;
    const angles = [0.2, 1.1, 2.0, 3.4, 4.6, 5.5];
    final points = <Offset>[];
    for (final a in angles) {
      final p = Offset(
        c.dx + math.cos(a) * r * 0.88,
        c.dy + math.sin(a) * r * 0.88,
      );
      points.add(p);
      canvas.drawCircle(p, 1.35, node);
    }
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.55
      ..color = cream;
    for (var i = 0; i < points.length - 1; i += 2) {
      canvas.drawLine(points[i], points[i + 1], line);
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter old) =>
      old.gold != gold || old.cream != cream || old.drift != drift;
}
