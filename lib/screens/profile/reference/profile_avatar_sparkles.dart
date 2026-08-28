/// Tiny star particles — placed from seed, never reshuffled on launch.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import 'profile_avatar_seed.dart';

class ProfileAvatarSparkleLayer extends StatelessWidget {
  const ProfileAvatarSparkleLayer({super.key, required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: ProfileAvatarSparklePainter(seed),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class ProfileAvatarSparklePainter extends CustomPainter {
  const ProfileAvatarSparklePainter(this.seed);

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(size.width, size.height) / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 5; i++) {
      final angle = ProfileAvatarSeed.unit(seed, i) * math.pi * 2;
      final dist = (0.42 + 0.28 * ProfileAvatarSeed.unit(seed, i + 7)) * r;
      final mag = 0.8 + 0.7 * ProfileAvatarSeed.unit(seed, i + 11);
      paint.color = OraclyChrome.goldLight.withValues(
        alpha: 0.22 + 0.16 * ProfileAvatarSeed.unit(seed, i + 17),
      );
      _star(
        canvas,
        Offset(cx + math.cos(angle) * dist, cy + math.sin(angle) * dist),
        mag,
        paint,
      );
    }
  }

  void _star(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size * 0.22, center.dy - size * 0.22)
      ..lineTo(center.dx + size, center.dy)
      ..lineTo(center.dx + size * 0.22, center.dy + size * 0.22)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size * 0.22, center.dy + size * 0.22)
      ..lineTo(center.dx - size, center.dy)
      ..lineTo(center.dx - size * 0.22, center.dy - size * 0.22)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ProfileAvatarSparklePainter old) =>
      old.seed != seed;
}
