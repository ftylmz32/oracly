/// Organic palm contour + subtle line filaments — capture guidance only.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import 'palm_tokens.dart';

class PalmCapturePalmGuidePainter extends CustomPainter {
  const PalmCapturePalmGuidePainter({required this.pulse});

  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.transparent,
            PalmTokens.veilInk.withValues(alpha: 0.28),
          ],
          stops: const [0, 0.68, 1],
        ).createShader(bounds),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds.deflate(1), const Radius.circular(23)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = OraclyChrome.goldLight.withValues(alpha: 0.52 + pulse * 0.12),
    );
    _motes(canvas, size, pulse);
  }

  void _motes(Canvas canvas, Size size, double pulse) {
    final paint = Paint()
      ..color = OraclyChrome.goldLight.withValues(alpha: 0.18 + pulse * 0.1);
    for (final o in [
      Offset(size.width * 0.18, size.height * 0.22),
      Offset(size.width * 0.82, size.height * 0.34),
      Offset(size.width * 0.74, size.height * 0.78),
    ]) {
      canvas.drawCircle(o, 1.1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PalmCapturePalmGuidePainter old) =>
      old.pulse != pulse;
}
