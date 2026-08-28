/// Restrained scan sweep + corner marks — never fake palm lines.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import 'palm_tokens.dart';

class PalmAnalysisScanPainter extends CustomPainter {
  const PalmAnalysisScanPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || progress <= 0 || progress >= 1) return;
    final y = size.height * (-0.08 + progress * 1.16);
    final band = Rect.fromCenter(
      center: Offset(size.width * 0.5, y),
      width: size.width * 1.08,
      height: size.height * 0.11,
    );
    canvas.drawRect(
      band,
      Paint()
        ..shader = ui.Gradient.linear(
          band.topCenter,
          band.bottomCenter,
          [
            Colors.transparent,
            OraclyChrome.gold.withValues(alpha: 0.04),
            OraclyChrome.goldLight.withValues(alpha: 0.12),
            OraclyChrome.cream.withValues(alpha: 0.08),
            OraclyChrome.gold.withValues(alpha: 0.03),
            Colors.transparent,
          ],
          const [0.0, 0.22, 0.48, 0.58, 0.78, 1.0],
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRect(
      Rect.fromCenter(center: band.center, width: size.width * 0.92, height: 1.0),
      Paint()..color = OraclyChrome.goldLight.withValues(alpha: 0.22),
    );
  }

  @override
  bool shouldRepaint(covariant PalmAnalysisScanPainter old) =>
      old.progress != progress;
}

/// Corner targeting brackets — decorative only.
class PalmAnalysisMarkersPainter extends CustomPainter {
  const PalmAnalysisMarkersPainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || opacity <= 0.01) return;
    final a = opacity.clamp(0.0, 1.0);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = OraclyChrome.goldLight.withValues(alpha: 0.34 * a);
    const inset = 14.0;
    const len = 16.0;
    final corners = [
      Offset(inset, inset),
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      Offset(size.width - inset, size.height - inset),
    ];
    for (var i = 0; i < corners.length; i++) {
      final p = corners[i];
      final path = Path();
      if (i == 0) {
        path.moveTo(p.dx, p.dy + len);
        path.lineTo(p.dx, p.dy);
        path.lineTo(p.dx + len, p.dy);
      } else if (i == 1) {
        path.moveTo(p.dx - len, p.dy);
        path.lineTo(p.dx, p.dy);
        path.lineTo(p.dx, p.dy + len);
      } else if (i == 2) {
        path.moveTo(p.dx, p.dy - len);
        path.lineTo(p.dx, p.dy);
        path.lineTo(p.dx + len, p.dy);
      } else {
        path.moveTo(p.dx - len, p.dy);
        path.lineTo(p.dx, p.dy);
        path.lineTo(p.dx, p.dy - len);
      }
      canvas.drawPath(path, stroke);
    }
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * 0.5, size.height * 0.42),
          size.shortestSide * 0.78,
          [
            Colors.transparent,
            PalmTokens.veilInk.withValues(alpha: 0.06 * a),
            PalmTokens.veilInk.withValues(alpha: 0.18 * a),
          ],
          const [0.42, 0.74, 1.0],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant PalmAnalysisMarkersPainter old) =>
      old.opacity != opacity;
}

class PalmAnalysisFxLayer extends StatelessWidget {
  const PalmAnalysisFxLayer({super.key, required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final scan = Curves.easeInOutCubic.transform(
      ((t - 0.12) / 0.48).clamp(0.0, 1.0),
    );
    final markers = Curves.easeOutCubic.transform(
      ((t - 0.55) / 0.35).clamp(0.0, 1.0),
    );
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: PalmAnalysisScanPainter(progress: scan)),
          CustomPaint(painter: PalmAnalysisMarkersPainter(opacity: markers)),
        ],
      ),
    );
  }
}
