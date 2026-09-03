/// Decorative closing from the approved Kahve Fali reference.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/coffee_copy.dart';

class CoffeeLandingClose extends StatelessWidget {
  const CoffeeLandingClose({super.key});

  @override
  Widget build(BuildContext context) {
    final gold = OraclyChrome.goldLight.withValues(alpha: 0.72);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s16),
      child: Column(
        children: [
          _hairline(gold),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
            child: Text(
              CoffeeCopy.overallTitle,
              textAlign: TextAlign.center,
              softWrap: true,
              style: ReadingTypography.sectionLabel(fontSize: 9.5).copyWith(
                letterSpacing: 0.85,
                height: 1.25,
                color: gold,
              ),
            ),
          ),
          _hairline(gold),
          const SizedBox(height: AppSpacing.s8),
          CustomPaint(
            size: const Size(36, 18),
            painter: _CoffeeCloseMark(gold),
          ),
        ],
      ),
    );
  }

  Widget _hairline(Color gold) {
    return SizedBox(
      height: 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(height: 0.7, color: gold),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Transform.rotate(
                angle: 0.785398,
                child: Container(width: 4, height: 4, color: gold),
              ),
              Transform.rotate(
                angle: 0.785398,
                child: Container(width: 4, height: 4, color: gold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoffeeCloseMark extends CustomPainter {
  const _CoffeeCloseMark(this.gold);

  final Color gold;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gold
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final c = Offset(size.width / 2, 4);
    canvas.drawCircle(c, 2.2, paint);
    for (var i = -3; i <= 3; i++) {
      final t = i / 3;
      final end = Offset(c.dx + t * 14, size.height - 1);
      canvas.drawLine(c, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CoffeeCloseMark oldDelegate) =>
      oldDelegate.gold != gold;
}