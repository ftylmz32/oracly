/// Thin gold line-light filaments — atmosphere only, never anatomy or scan HUD.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import 'palm_tokens.dart';

class PalmLineLightPainter extends CustomPainter {
  const PalmLineLightPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = Curves.easeInOutCubic.transform(phase);
    final breath = 0.5 + 0.5 * math.sin(phase * math.pi * 2);

    // Soft chamber vignette — keeps the hand primary.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * 0.5, size.height * 0.42),
          size.shortestSide * 0.72,
          [
            Colors.transparent,
            PalmTokens.veilInk.withValues(alpha: 0.10 + breath * 0.04),
            PalmTokens.veilInk.withValues(alpha: 0.28),
          ],
          const [0.38, 0.72, 1.0],
        ),
    );

    _filament(
      canvas,
      size,
      travel: -0.35 + t * 1.55,
      angle: -math.pi / 11,
      alpha: 0.55 + breath * 0.12,
      width: size.width * 0.018,
    );
    _filament(
      canvas,
      size,
      travel: -0.55 + ((t + 0.38) % 1.0) * 1.7,
      angle: math.pi / 15,
      alpha: 0.28 + breath * 0.08,
      width: size.width * 0.010,
    );

    // Quiet progress hairline — never a percentage or scan bar.
    final progress = Curves.easeInOut.transform(phase);
    final barW = size.width * (0.18 + progress * 0.42);
    final barY = size.height * 0.90;
    final bar = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, barY),
        width: barW,
        height: 1.15,
      ),
      const Radius.circular(99),
    );
    canvas.drawRRect(
      bar,
      Paint()..color = OraclyChrome.gold.withValues(alpha: 0.14 + breath * 0.06),
    );
    canvas.drawRRect(
      bar,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = OraclyChrome.goldLight.withValues(alpha: 0.42),
    );
  }

  void _filament(
    Canvas canvas,
    Size size, {
    required double travel,
    required double angle,
    required double alpha,
    required double width,
  }) {
    canvas.save();
    canvas.translate(size.width * travel, size.height * 0.06);
    canvas.rotate(angle);
    final band = Rect.fromCenter(
      center: Offset(size.width * 0.1, size.height * 0.45),
      width: width,
      height: size.height * 1.45,
    );
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          OraclyChrome.gold.withValues(alpha: 0.04 * alpha),
          OraclyChrome.cream.withValues(alpha: 0.16 * alpha),
          OraclyChrome.goldLight.withValues(alpha: 0.22 * alpha),
          OraclyChrome.cream.withValues(alpha: 0.14 * alpha),
          OraclyChrome.gold.withValues(alpha: 0.04 * alpha),
          Colors.transparent,
        ],
        stops: const [0.0, 0.18, 0.38, 0.5, 0.62, 0.82, 1.0],
      ).createShader(band)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRect(band, paint);

    // Core line — a thread of light, not a grid.
    final core = Rect.fromCenter(
      center: band.center,
      width: math.max(1.0, width * 0.22),
      height: band.height * 0.92,
    );
    canvas.drawRect(
      core,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            OraclyChrome.cream.withValues(alpha: 0.28 * alpha),
            OraclyChrome.goldLight.withValues(alpha: 0.38 * alpha),
            OraclyChrome.cream.withValues(alpha: 0.22 * alpha),
            Colors.transparent,
          ],
          stops: const [0.0, 0.28, 0.5, 0.72, 1.0],
        ).createShader(core),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PalmLineLightPainter old) => old.phase != phase;
}
