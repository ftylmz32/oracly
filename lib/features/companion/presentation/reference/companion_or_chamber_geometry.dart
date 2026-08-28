/// Faint celestial geometry for the OR chamber — quiet, never noisy.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';

class CompanionOrChamberGeometry extends StatelessWidget {
  const CompanionOrChamberGeometry({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _CompanionOrChamberGeometryPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _CompanionOrChamberGeometryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.28);
    final r = size.shortestSide * 0.42;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.35
      ..color = OraclyChrome.violet.withValues(alpha: 0.045);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 - math.pi / 2;
      canvas.drawLine(
        c,
        Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r),
        line,
      );
    }
    canvas.drawCircle(c, r * 0.62, line..color = OraclyChrome.gold.withValues(alpha: 0.035));
    canvas.drawCircle(c, r * 0.28, line..color = OraclyChrome.violet.withValues(alpha: 0.03));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
