/// Centered palm silhouette — outline only, never fake reading lines.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';

class PalmSilhouetteArt extends StatelessWidget {
  const PalmSilhouetteArt({super.key, this.size = 160});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: const _PalmPainter(),
    );
  }
}

class _PalmPainter extends CustomPainter {
  const _PalmPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.50;
    final cy = size.height * 0.58;
    final w = size.width * 0.22;

    final glow = Paint()
      ..color = OraclyChrome.gold.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: w * 2.8, height: w * 3.4),
      glow,
    );

    final violet = Paint()
      ..color = OraclyChrome.violet.withValues(alpha: 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(Offset(cx, cy), w * 1.6, violet);

    final palm = Path()
      ..moveTo(cx - w * 0.72, cy + w * 1.05)
      ..quadraticBezierTo(cx, cy + w * 1.22, cx + w * 0.72, cy + w * 1.05)
      ..lineTo(cx + w * 0.70, cy + w * 0.12)
      ..quadraticBezierTo(cx + w * 1.18, cy - w * 0.08, cx + w * 1.10, cy - w * 0.55)
      ..quadraticBezierTo(cx + w * 0.92, cy - w * 0.18, cx + w * 0.52, cy - w * 0.10)
      ..quadraticBezierTo(cx + w * 0.58, cy - w * 1.38, cx + w * 0.28, cy - w * 1.42)
      ..quadraticBezierTo(cx + w * 0.18, cy - w * 0.22, cx + w * 0.12, cy - w * 0.12)
      ..quadraticBezierTo(cx + w * 0.08, cy - w * 1.58, cx - w * 0.12, cy - w * 1.52)
      ..quadraticBezierTo(cx - w * 0.06, cy - w * 0.22, cx - w * 0.16, cy - w * 0.10)
      ..quadraticBezierTo(cx - w * 0.22, cy - w * 1.38, cx - w * 0.48, cy - w * 1.28)
      ..quadraticBezierTo(cx - w * 0.38, cy - w * 0.18, cx - w * 0.48, cy - w * 0.06)
      ..quadraticBezierTo(cx - w * 0.92, cy - w * 0.02, cx - w * 0.88, cy - w * 0.48)
      ..quadraticBezierTo(cx - w * 1.05, cy + w * 0.06, cx - w * 0.70, cy + w * 0.16)
      ..close();

    canvas.drawPath(
      palm,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF241428),
            const Color(0xFF120810),
            OraclyChrome.violet.withValues(alpha: 0.45),
          ],
        ).createShader(palm.getBounds()),
    );
    canvas.drawPath(
      palm,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..color = OraclyChrome.goldLight.withValues(alpha: 0.88),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
