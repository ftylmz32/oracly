/// Organic palm contour + subtle line filaments — capture guidance only.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import 'palm_tokens.dart';

class PalmCapturePalmGuidePainter extends CustomPainter {
  const PalmCapturePalmGuidePainter({
    required this.pulse,
    required this.mirror,
  });

  final double pulse;
  final bool mirror;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.1, -0.15),
          radius: 1.15,
          colors: [
            OraclyChrome.violet.withValues(alpha: 0.24),
            const Color(0xFF0A0614),
            const Color(0xFF050308),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.save();
    if (mirror) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    final palm = _palmPath(size);
    final c = Offset(size.width * 0.5, size.height * 0.54);
    canvas.drawOval(
      Rect.fromCenter(
        center: c,
        width: size.width * 0.62,
        height: size.height * 0.58,
      ),
    Paint()
      ..color = PalmTokens.amberGlow.withValues(alpha: 0.05 + pulse * 0.02)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32),
  );
    canvas.drawPath(
      palm,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1E1220).withValues(alpha: 0.92),
            PalmTokens.veilInk,
            OraclyChrome.violet.withValues(alpha: 0.35),
          ],
        ).createShader(palm.getBounds()),
    );
    _lines(canvas, size);
    canvas.drawPath(
      palm,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.65
        ..color = OraclyChrome.goldLight.withValues(alpha: 0.62 + pulse * 0.1),
    );
    canvas.restore();
    _motes(canvas, size, pulse);
  }

  Path _palmPath(Size size) {
    final cx = size.width * 0.50;
    final cy = size.height * 0.56;
    final w = size.width * 0.19;
    return Path()
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
  }

  void _lines(Canvas canvas, Size size) {
    final cx = size.width * 0.50;
    final cy = size.height * 0.56;
    final w = size.width * 0.19;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85
      ..strokeCap = StrokeCap.round
      ..color = OraclyChrome.goldLight.withValues(alpha: 0.16);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy + w * 0.05), width: w * 1.5, height: w * 0.9),
      2.9,
      1.1,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - w * 0.08, cy + w * 0.22), width: w * 1.1, height: w * 1.35),
      1.35,
      1.25,
      false,
      paint..color = OraclyChrome.violet.withValues(alpha: 0.22),
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - w * 0.22, cy + w * 0.18), width: w * 0.75, height: w * 1.05),
      1.55,
      1.05,
      false,
      paint..color = OraclyChrome.gold.withValues(alpha: 0.14),
    );
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
      old.pulse != pulse || old.mirror != mirror;
}