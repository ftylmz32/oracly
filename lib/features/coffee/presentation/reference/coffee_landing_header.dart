/// Landing identity — celestial mark · KAHVE FALI · quiet invitation.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/coffee_copy.dart';

class CoffeeLandingHeader extends StatelessWidget {
  const CoffeeLandingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s20,
        AppSpacing.s4,
        AppSpacing.s20,
        0,
      ),
      child: Column(
        children: [
          const CustomPaint(
            size: Size(120, 22),
            painter: _CoffeeCelestialMark(),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            CoffeeCopy.landingTitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ReadingTypography.display(
              color: OraclyChrome.goldLight,
            ).copyWith(
              fontSize: 30,
              letterSpacing: 4.0,
              height: 1.05,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            '"${CoffeeCopy.hubLead}"',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ReadingTypography.opening(
              color: OraclyChrome.cream.withValues(alpha: 0.90),
            ).copyWith(
              fontSize: 15,
              height: 1.35,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          const CustomPaint(
            size: Size(8, 8),
            painter: _CoffeeLeadStar(),
          ),
        ],
      ),
    );
  }
}

class _CoffeeCelestialMark extends CustomPainter {
  const _CoffeeCelestialMark();

  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()
      ..color = OraclyChrome.goldLight.withValues(alpha: 0.86)
      ..strokeWidth = 0.95
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final cx = size.width / 2;
    final cy = size.height * 0.58;
    canvas.drawLine(Offset(4, cy), Offset(cx - 18, cy), gold);
    canvas.drawLine(Offset(cx + 18, cy), Offset(size.width - 4, cy), gold);
    canvas.drawCircle(Offset(6, cy), 1.35, gold);
    canvas.drawCircle(Offset(size.width - 6, cy), 1.35, gold);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx - 2.5, cy + 1), radius: 6.5),
      0.55,
      4.5,
      false,
      gold,
    );
    canvas.drawCircle(Offset(cx + 5.5, cy - 5.5), 1.7, gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CoffeeLeadStar extends CustomPainter {
  const _CoffeeLeadStar();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = OraclyChrome.goldLight.withValues(alpha: 0.82)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.42;
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), paint);
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), paint);
    final d = r * 0.55;
    canvas.drawLine(Offset(c.dx - d, c.dy - d), Offset(c.dx + d, c.dy + d), paint);
    canvas.drawLine(Offset(c.dx + d, c.dy - d), Offset(c.dx - d, c.dy + d), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
