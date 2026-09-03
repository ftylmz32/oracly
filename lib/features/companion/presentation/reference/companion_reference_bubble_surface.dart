/// Message surfaces -- violet user notes, dark Luna sanctuary bubbles.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import 'companion_reference_tokens.dart';

class CompanionReferenceBubbleSurface extends StatelessWidget {
  const CompanionReferenceBubbleSurface({
    super.key,
    required this.child,
    required this.isUser,
  });

  final Widget child;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      // User bubbles include a small “tail” on the bottom-right.
      return Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: CompanionReferenceTokens.userRadius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  OraclyChrome.violet.withValues(alpha: 0.48),
                  const Color(0xFF1A1230).withValues(alpha: 0.90),
                ],
              ),
              border: Border.all(
                color: OraclyChrome.violet.withValues(alpha: 0.40),
              ),
            ),
            child: child,
          ),
          Positioned(
            right: -4,
            bottom: -3,
            child: SizedBox(
              width: 14,
              height: 12,
              child: CustomPaint(
                painter: _UserBubbleTailPainter(
                  fill: const Color(0xFF1A1230).withValues(alpha: 0.90),
                  stroke: OraclyChrome.violet.withValues(alpha: 0.40),
                  strokeWidth: 1.1,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: CompanionReferenceTokens.orRadius,
        color: const Color(0xFF0E0B14).withValues(alpha: 0.92),
        border: Border.all(
          color: OraclyChrome.violet.withValues(alpha: 0.38),
        ),
        boxShadow: [
          BoxShadow(
            color: OraclyChrome.violet.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _UserBubbleTailPainter extends CustomPainter {
  _UserBubbleTailPainter({
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
  });

  final Color fill;
  final Color stroke;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(size.width * 0.35, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(p, fillPaint);
    canvas.drawPath(p, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _UserBubbleTailPainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.stroke != stroke ||
      oldDelegate.strokeWidth != strokeWidth;
}
