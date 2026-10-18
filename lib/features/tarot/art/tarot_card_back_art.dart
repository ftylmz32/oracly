/// The Celestial Deck — engraved night-sky back with an integrated seal.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import '../presentation/widgets/deck/tarot_printed_material.dart';
import 'major_arcana_art.dart';
import 'tarot_card_asset.dart';
import 'tarot_card_back_stars.dart';

class TarotCardBackArt extends StatelessWidget {
  const TarotCardBackArt({
    super.key,
    this.fit = BoxFit.cover,
    this.lightBiasX = 0,
    this.lightBiasY = 0,
  });

  final BoxFit fit;
  final double lightBiasX;
  final double lightBiasY;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF070510)),
        const TarotCardBackStars(),
        // Lift the near-black print into night navy / plum and brighten the
        // engraved gold so the star map stays legible at phone size.
        ColorFiltered(
          colorFilter: const ColorFilter.matrix(_nightPrintMatrix),
          child: OraclyAssetImage(
            assetPath: TarotCardAsset.preview(MajorArcanaArt.cardBack),
            fallbackAsset: MajorArcanaArt.cardBack,
            fit: fit,
            filterQuality: FilterQuality.medium,
            cacheCapPx: TarotCardAsset.previewCapPx,
            fallback: Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.goldLight.withValues(alpha: 0.72),
            ),
          ),
        ),
        const _SoftCenterGlow(),
        const _CelestialDeckSeal(),
        TarotPrintedMaterial(
          lightBiasX: lightBiasX,
          lightBiasY: lightBiasY,
          foil: 0.62,
          matte: 0.7,
        ),
      ],
    );
  }
}

const List<double> _nightPrintMatrix = <double>[
  1.20, 0, 0, 0, 3, //
  0, 1.16, 0, 0, 5, //
  0, 0, 1.26, 0, 16, //
  0, 0, 0, 1, 0, //
];

class _CelestialDeckSeal extends StatelessWidget {
  const _CelestialDeckSeal();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(painter: _CelestialDeckSealPainter()),
    );
  }
}

class _CelestialDeckSealPainter extends CustomPainter {
  const _CelestialDeckSealPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Offset(w / 2, h / 2);
    final unit = math.min(w, h);
    // Sits inside the printed star band's inner circle (~0.29 of width).
    final radius = unit * 0.235;
    final hairline = math.max(0.6, unit * 0.0075);
    final gold = AppColors.goldLight;

    final auraRect = Rect.fromCircle(center: c, radius: radius * 1.5);
    canvas.drawCircle(
      c,
      radius * 1.46,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF5B3A9A).withValues(alpha: 0.16),
            AppColors.gold.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.56, 1.0],
        ).createShader(auraRect),
    );

    final engraved = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hairline
      ..color = gold.withValues(alpha: 0.86);
    final quiet = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hairline * 0.72
      ..color = gold.withValues(alpha: 0.48);

    canvas.drawCircle(c, radius, engraved);
    canvas.drawCircle(c, radius * 0.82, quiet);

    for (var i = 0; i < 16; i++) {
      final angle = -math.pi / 2 + i * math.pi / 8;
      final cardinal = i % 4 == 0;
      final inner = radius * (cardinal ? 0.86 : 0.91);
      final outer = radius * (cardinal ? 1.20 : 1.10);
      canvas.drawLine(
        c + Offset(math.cos(angle) * inner, math.sin(angle) * inner),
        c + Offset(math.cos(angle) * outer, math.sin(angle) * outer),
        cardinal ? engraved : quiet,
      );
    }

    // Four compass petals anchor the seal in both axes.
    for (var i = 0; i < 4; i++) {
      final angle = -math.pi / 2 + i * math.pi / 2;
      final tip = c + Offset(math.cos(angle), math.sin(angle)) * radius * 1.17;
      final left =
          c +
          Offset(math.cos(angle - 0.20), math.sin(angle - 0.20)) *
              radius *
              0.84;
      final right =
          c +
          Offset(math.cos(angle + 0.20), math.sin(angle + 0.20)) *
              radius *
              0.84;
      final petal = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(right.dx, right.dy)
        ..close();
      canvas.drawPath(
        petal,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gold.withValues(alpha: 0.86),
              AppColors.gold.withValues(alpha: 0.30),
            ],
          ).createShader(petal.getBounds()),
      );
    }

    // Crescent cut from two circles: a celestial mark, never a brand tile.
    final moonOuter = Path()
      ..addOval(Rect.fromCircle(center: c, radius: radius * 0.56));
    final moonCut = Path()
      ..addOval(
        Rect.fromCircle(
          center: c + Offset(radius * 0.22, -radius * 0.06),
          radius: radius * 0.48,
        ),
      );
    final crescent = Path.combine(PathOperation.difference, moonOuter, moonCut);
    canvas.drawPath(
      crescent,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFEDB8),
            AppColors.gold.withValues(alpha: 0.92),
            const Color(0xFF9A6526).withValues(alpha: 0.85),
          ],
        ).createShader(crescent.getBounds()),
    );

    final starCenter = c + Offset(radius * 0.24, -radius * 0.05);
    final star = Path();
    for (var i = 0; i < 16; i++) {
      final angle = -math.pi / 2 + i * math.pi / 8;
      final r = radius * (i.isEven ? 0.25 : 0.08);
      final point =
          starCenter + Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (i == 0) {
        star.moveTo(point.dx, point.dy);
      } else {
        star.lineTo(point.dx, point.dy);
      }
    }
    star.close();
    canvas.drawPath(
      star,
      Paint()..color = const Color(0xFFFFF0C0),
    );
    canvas.drawCircle(
      starCenter,
      math.max(0.8, unit * 0.012),
      Paint()..color = Colors.white.withValues(alpha: 0.70),
    );
  }

  @override
  bool shouldRepaint(covariant _CelestialDeckSealPainter oldDelegate) => false;
}

class _SoftCenterGlow extends StatelessWidget {
  const _SoftCenterGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 0.55,
            colors: [
              AppColors.gold.withValues(alpha: 0.07),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
