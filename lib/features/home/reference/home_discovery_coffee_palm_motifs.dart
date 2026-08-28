/// Coffee + Palm discovery motifs — warm chamber / gold line-art.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/oracly_brand_signature.dart';

void paintCoffeeMotif(Canvas canvas, Size size) {
  final gold = OraclySignaturePalette.goldEngrave(0.82);
  final cx = size.width * 0.52;
  final cy = size.height * 0.52;
  final cupR = size.width * 0.22;
  canvas.drawOval(
    Rect.fromCenter(center: Offset(cx, cy + cupR * 0.95), width: cupR * 1.7, height: 7),
    Paint()..color = const Color(0xFF3A1C0C).withValues(alpha: 0.75),
  );
  final cup = Path()
    ..moveTo(cx - cupR, cy - cupR * 0.15)
    ..lineTo(cx - cupR * 0.82, cy + cupR * 0.85)
    ..quadraticBezierTo(cx, cy + cupR * 1.05, cx + cupR * 0.82, cy + cupR * 0.85)
    ..lineTo(cx + cupR, cy - cupR * 0.15)
    ..close();
  canvas.drawPath(cup, Paint()..color = const Color(0xFF5A3018));
  canvas.drawPath(
    cup,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = gold,
  );
  canvas.drawOval(
    Rect.fromCenter(center: Offset(cx, cy - cupR * 0.12), width: cupR * 1.72, height: 9),
    Paint()..color = const Color(0xFF2A1408),
  );
  canvas.drawArc(
    Rect.fromCenter(
      center: Offset(cx + cupR * 1.05, cy + cupR * 0.2),
      width: cupR * 0.7,
      height: cupR * 0.85,
    ),
    -1.2,
    2.2,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = gold,
  );
  final steam = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.05
    ..color = const Color(0xFFE8C88A).withValues(alpha: 0.5);
  for (var i = -1; i <= 1; i++) {
    final p = Path()
      ..moveTo(cx + i * 9, cy - cupR * 0.28)
      ..quadraticBezierTo(cx + i * 14, cy - cupR * 0.7, cx + i * 7, cy - cupR * 1.15);
    canvas.drawPath(p, steam);
  }
  canvas.drawCircle(
    Offset(cx - cupR * 0.55, cy - cupR * 0.55),
    cupR * 0.9,
    Paint()
      ..shader = RadialGradient(
        colors: [const Color(0x66E8A060), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: cupR * 1.6)),
  );
}

void paintPalmMotif(Canvas canvas, Size size) {
  final c = Offset(size.width * 0.5, size.height * 0.52);
  final gold = OraclySignaturePalette.goldEngrave(0.84);
  Paint stroke(double w, [double a = 1]) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..color = gold.withValues(alpha: a);
  final palm = Path()
    ..moveTo(c.dx, c.dy + size.height * 0.22)
    ..quadraticBezierTo(
      c.dx - size.width * 0.2,
      c.dy + size.height * 0.05,
      c.dx - size.width * 0.22,
      c.dy - size.height * 0.08,
    )
    ..quadraticBezierTo(
      c.dx - size.width * 0.2,
      c.dy - size.height * 0.28,
      c.dx - size.width * 0.08,
      c.dy - size.height * 0.32,
    )
    ..quadraticBezierTo(
      c.dx,
      c.dy - size.height * 0.22,
      c.dx + size.width * 0.08,
      c.dy - size.height * 0.32,
    )
    ..quadraticBezierTo(
      c.dx + size.width * 0.2,
      c.dy - size.height * 0.28,
      c.dx + size.width * 0.22,
      c.dy - size.height * 0.08,
    )
    ..quadraticBezierTo(
      c.dx + size.width * 0.2,
      c.dy + size.height * 0.05,
      c.dx,
      c.dy + size.height * 0.22,
    );
  canvas.drawPath(palm, stroke(1.2));
  canvas.drawArc(
    Rect.fromCenter(
      center: c.translate(0, -4),
      width: size.width * 0.28,
      height: size.height * 0.22,
    ),
    0.4,
    2.2,
    false,
    stroke(0.9),
  );
  for (var i = 0; i < 3; i++) {
    final y = c.dy - size.height * 0.02 - i * 8.0;
    canvas.drawLine(Offset(c.dx - 16, y), Offset(c.dx + 16, y - 4), stroke(0.85));
  }
  canvas.drawCircle(
    c.translate(-size.width * 0.12, -size.height * 0.16),
    size.width * 0.22,
    stroke(0.55, 0.35),
  );
}
