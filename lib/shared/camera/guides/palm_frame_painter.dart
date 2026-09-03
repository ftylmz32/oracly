/// Palm framing geometry — soft stage + corner brackets. No hand art.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';

class PalmFramePainter extends CustomPainter {
  const PalmFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    final frameW = (shortest * 0.62).clamp(160.0, 280.0);
    final frameH = frameW * 1.28;
    final rect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.42),
      width: frameW,
      height: frameH,
    );
    const radius = Radius.circular(22);

    final vignette = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(rect.inflate(10), radius))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      vignette,
      Paint()..color = const Color(0xFF07040F).withValues(alpha: 0.38),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15
        ..color = OraclyChrome.gold.withValues(alpha: 0.48),
    );

    _brackets(canvas, rect);
  }

  void _brackets(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round
      ..color = OraclyChrome.goldLight.withValues(alpha: 0.62);
    const len = 16.0;
    final inset = 2.0;
    final corners = <(Offset, double, double)>[
      (Offset(rect.left + inset, rect.top + inset), 1, 1),
      (Offset(rect.right - inset, rect.top + inset), -1, 1),
      (Offset(rect.left + inset, rect.bottom - inset), 1, -1),
      (Offset(rect.right - inset, rect.bottom - inset), -1, -1),
    ];
    for (final (p, sx, sy) in corners) {
      canvas.drawLine(p, Offset(p.dx + sx * len, p.dy), paint);
      canvas.drawLine(p, Offset(p.dx, p.dy + sy * len), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
