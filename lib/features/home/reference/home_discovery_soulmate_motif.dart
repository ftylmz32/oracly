/// SoulMate discovery motif — cinematic portrait language beside Tarot.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/oracly_brand_signature.dart';

void paintSoulMateMotif(Canvas canvas, Size size) {
  final cx = size.width * 0.52;
  final base = size.height * 0.84;
  final gold = OraclySignaturePalette.goldEngrave(0.85);

  canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.05, 0.15),
        radius: 1.05,
        colors: [
          const Color(0x55E8C88A),
          const Color(0x44201838),
          const Color(0x22080614),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.7, 1],
      ).createShader(Offset.zero & size),
  );

  // Soft portrait plate — depth behind figures.
  canvas.drawOval(
    Rect.fromCenter(center: Offset(cx, base - 48), width: 88, height: 110),
    Paint()
      ..shader = RadialGradient(
        colors: [const Color(0x66C4A574), const Color(0x220E0820), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(cx, base - 48), radius: 64)),
  );

  void figure({
    required double dx,
    required double headW,
    required double headH,
    required double bodyW,
    required double bodyH,
    required double alpha,
    required bool rim,
  }) {
    final fill = Paint()..color = Color.fromRGBO(8, 4, 14, alpha);
    final hx = cx + dx;
    final hy = base - bodyH * 0.95;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(hx, hy), width: headW, height: headH),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(hx, base - bodyH * 0.28),
          width: bodyW,
          height: bodyH,
        ),
        Radius.circular(bodyW * 0.42),
      ),
      fill,
    );
    if (rim) {
      final edge = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = gold.withValues(alpha: 0.8);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(hx, hy), width: headW, height: headH),
        edge,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(hx + 2, base - bodyH * 0.28),
          width: bodyW,
          height: bodyH,
        ),
        -1.2,
        1.75,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.05
          ..color = gold.withValues(alpha: 0.72),
      );
    }
  }

  figure(dx: -16, headW: 24, headH: 30, bodyW: 36, bodyH: 52, alpha: 0.82, rim: false);
  figure(dx: 10, headW: 32, headH: 38, bodyW: 48, bodyH: 64, alpha: 0.96, rim: true);

  canvas.drawCircle(Offset(cx + 34, base - 92), 2.1, Paint()..color = gold);
  canvas.drawCircle(Offset(cx + 44, base - 80), 1.35, Paint()..color = gold);
  canvas.drawLine(
    Offset(cx + 34, base - 92),
    Offset(cx + 44, base - 80),
    Paint()
      ..strokeWidth = 0.6
      ..color = gold.withValues(alpha: 0.55),
  );
}
