/// Palm framing guide — full hand silhouette, natural placement.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';

class PalmHandCaptureGuide extends StatelessWidget {
  const PalmHandCaptureGuide({super.key, this.tip});

  final String? tip;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: const _HandOutlinePainter(),
        child: tip == null
            ? const SizedBox.expand()
            : Align(
                alignment: const Alignment(0, 0.78),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    tip!,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: OraclyChrome.cream.withValues(alpha: 0.82),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _HandOutlinePainter extends CustomPainter {
  const _HandOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = OraclyChrome.gold.withValues(alpha: 0.58);

    final w = size.width;
    final h = size.height;
    final path = Path();
    // Palm body + five fingers — subtle silhouette, not medical diagram.
    final ox = w * 0.5;
    final oy = h * 0.58;
    final pw = w * 0.28;
    final ph = h * 0.22;

    path.moveTo(ox - pw * 0.55, oy + ph * 0.55);
    path.quadraticBezierTo(ox - pw, oy, ox - pw * 0.85, oy - ph * 0.2);
    // Thumb
    path.quadraticBezierTo(
      ox - pw * 1.15,
      oy - ph * 0.55,
      ox - pw * 0.7,
      oy - ph * 0.75,
    );
    // Fingers
    path.quadraticBezierTo(ox - pw * 0.55, oy - ph * 1.35, ox - pw * 0.28, oy - ph * 0.9);
    path.quadraticBezierTo(ox - pw * 0.18, oy - ph * 1.55, ox - 0.02, oy - ph * 0.95);
    path.quadraticBezierTo(ox + pw * 0.12, oy - ph * 1.6, ox + pw * 0.28, oy - ph * 0.9);
    path.quadraticBezierTo(ox + pw * 0.42, oy - ph * 1.45, ox + pw * 0.55, oy - ph * 0.85);
    path.quadraticBezierTo(ox + pw * 0.95, oy - ph * 0.35, ox + pw * 0.75, oy + ph * 0.15);
    path.quadraticBezierTo(ox + pw * 0.55, oy + ph * 0.7, ox - pw * 0.55, oy + ph * 0.55);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
