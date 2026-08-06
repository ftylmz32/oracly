/// OR-403 / OR-408 — Architectural bridges connecting sanctuary chambers.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'oracly_sacred_identity.dart';
import 'tarot_home_cinematic_scroll.dart';

/// Transition ornament between narrative sections.
enum TarotHomeBridgeKind {
  orbSpill,
  purpleMist,
  constellation,
  sacredGeometry,
}

class TarotHomeSectionBridge extends StatelessWidget {
  const TarotHomeSectionBridge({
    super.key,
    required this.kind,
    this.phase = 0,
  });

  final TarotHomeBridgeKind kind;
  final double phase;

  @override
  Widget build(BuildContext context) {
    final scroll = TarotHomeScrollScope.maybeOf(context)?.scrollOffset ?? 0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: OraclyRhythm.bridgeVertical),
      child: SizedBox(
        height: kind == TarotHomeBridgeKind.orbSpill ? 36 : 32,
        width: double.infinity,
        child: CustomPaint(
          painter: _SectionBridgePainter(
            kind: kind,
            phase: phase,
            scrollOffset: scroll,
          ),
        ),
      ),
    );
  }
}

class _SectionBridgePainter extends CustomPainter {
  const _SectionBridgePainter({
    required this.kind,
    required this.phase,
    required this.scrollOffset,
  });

  final TarotHomeBridgeKind kind;
  final double phase;
  final double scrollOffset;

  @override
  void paint(Canvas canvas, Size size) {
    _paintChamberMeridians(canvas, size);

    switch (kind) {
      case TarotHomeBridgeKind.orbSpill:
        _paintOrbSpill(canvas, size);
      case TarotHomeBridgeKind.purpleMist:
        _paintPurpleMist(canvas, size);
      case TarotHomeBridgeKind.constellation:
        _paintConstellation(canvas, size);
      case TarotHomeBridgeKind.sacredGeometry:
        _paintSacredGeometry(canvas, size);
    }
  }

  void _paintChamberMeridians(Canvas canvas, Size size) {
    final parallax = scrollOffset * 0.015;
    final leftX = size.width * 0.10;
    final rightX = size.width * 0.90;

    final meridian = Paint()
      ..strokeWidth = 0.25
      ..color = OraclySacredPalette.goldHairline(0.035);

    canvas.drawLine(
      Offset(leftX, -parallax),
      Offset(leftX, size.height + parallax),
      meridian,
    );
    canvas.drawLine(
      Offset(rightX, -parallax),
      Offset(rightX, size.height + parallax),
      meridian,
    );
  }

  void _paintOrbSpill(Canvas canvas, Size size) {
    final cx = size.width / 2;
    canvas.drawLine(
      Offset(cx, 0),
      Offset(cx, size.height),
      Paint()
        ..strokeWidth = 0.5
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OraclySacredPalette.champagne.withValues(alpha: 0.10),
            OraclySacredPalette.purpleEnergySoft.withValues(alpha: 0.05),
            AppColors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.drawCircle(
      Offset(cx, size.height * 0.35),
      1.5,
      Paint()..color = OraclySacredPalette.champagne.withValues(alpha: 0.16),
    );

    final archY = size.height * 0.5;
    final path = Path()
      ..moveTo(cx - size.width * 0.22, archY)
      ..quadraticBezierTo(cx, archY - 10, cx + size.width * 0.22, archY);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.35
        ..color = OraclySacredPalette.goldEngrave(0.04),
    );
  }

  void _paintPurpleMist(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, -8, size.width, size.height + 16);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OraclySacredPalette.purpleEnergy.withValues(alpha: 0.03 + phase * 0.01),
            AppColors.transparent,
            OraclySacredPalette.deepViolet.withValues(alpha: 0.04),
            OraclySacredPalette.purpleEnergySoft.withValues(alpha: 0.025),
          ],
          stops: const [0.0, 0.35, 0.72, 1.0],
        ).createShader(rect),
    );
  }

  void _paintConstellation(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const nodes = [(-24.0, 0.0), (0.0, -3.0), (24.0, 0.0)];

    final line = Paint()
      ..strokeWidth = 0.35
      ..color = OraclySacredPalette.goldHairline(0.06);
    for (var i = 0; i < nodes.length - 1; i++) {
      canvas.drawLine(
        Offset(cx + nodes[i].$1, cy + nodes[i].$2),
        Offset(cx + nodes[i + 1].$1, cy + nodes[i + 1].$2),
        line,
      );
    }

    for (final (dx, dy) in nodes) {
      canvas.drawCircle(
        Offset(cx + dx, cy + dy),
        1.0,
        Paint()..color = OraclySacredPalette.champagne.withValues(alpha: 0.24),
      );
    }
  }

  void _paintSacredGeometry(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final tri = Path()
      ..moveTo(cx, cy - 7)
      ..lineTo(cx - 6, cy + 4)
      ..lineTo(cx + 6, cy + 4)
      ..close();
    canvas.drawPath(
      tri,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.4
        ..color = OraclySacredPalette.goldEngrave(0.08),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      0.8,
      Paint()..color = OraclySacredPalette.champagne.withValues(alpha: 0.18),
    );

    canvas.drawCircle(
      Offset(cx, cy),
      12,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.3
        ..color = OraclySacredPalette.goldHairline(0.05),
    );
  }

  @override
  bool shouldRepaint(covariant _SectionBridgePainter old) =>
      old.kind != kind ||
      old.phase != phase ||
      old.scrollOffset != scrollOffset;
}

/// Calm breathing gap in the visual rhythm.
class TarotHomeBreathGap extends StatelessWidget {
  const TarotHomeBreathGap({super.key, this.size = OraclyRhythm.breathGap});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(height: size);
}
