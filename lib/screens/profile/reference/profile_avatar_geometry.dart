/// Quiet celestial geometry unique to the identity seed.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import 'profile_avatar_seed.dart';

class ProfileAvatarGeometry extends StatelessWidget {
  const ProfileAvatarGeometry({super.key, required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: ProfileAvatarGeometryPainter(seed),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class ProfileAvatarGeometryPainter extends CustomPainter {
  const ProfileAvatarGeometryPainter(this.seed);

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;
    final spin = ProfileAvatarSeed.unit(seed, 2) * math.pi;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(spin);

    final ring = Paint()
      ..color = OraclyChrome.goldMuted.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    canvas.drawCircle(Offset.zero, r * 0.72, ring);

    final ticks = 4 + (seed % 3);
    final tick = Paint()
      ..color = OraclyChrome.goldLight.withValues(alpha: 0.28)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < ticks; i++) {
      final a = (math.pi * 2) * (i / ticks);
      final inner = Offset(math.cos(a) * r * 0.58, math.sin(a) * r * 0.58);
      final outer = Offset(math.cos(a) * r * 0.70, math.sin(a) * r * 0.70);
      canvas.drawLine(inner, outer, tick);
    }

    final diamond = Path()
      ..moveTo(0, -r * 0.42)
      ..lineTo(r * 0.18, 0)
      ..lineTo(0, r * 0.42)
      ..lineTo(-r * 0.18, 0)
      ..close();
    canvas.drawPath(
      diamond,
      Paint()
        ..color = OraclyChrome.gold.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ProfileAvatarGeometryPainter old) =>
      old.seed != seed;
}
