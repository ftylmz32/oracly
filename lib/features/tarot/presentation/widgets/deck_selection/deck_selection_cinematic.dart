/// OR-420 — Cinematic deck selection: sacred table, not a list.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/oracly_brand_signature.dart';
import 'deck_selection_data.dart';
import 'deck_visual_style.dart';

/// Handcrafted rest poses — never perfectly aligned.
abstract final class DeckCinematic {
  DeckCinematic._();

  static const _rotations = <double>[
    -0.011,
    0.008,
    -0.006,
    0.010,
    -0.009,
    0.007,
  ];

  static const _offsets = <Offset>[
    Offset(0.5, 2.0),
    Offset(-0.8, 1.5),
    Offset(1.2, 2.5),
    Offset(-0.4, 1.8),
    Offset(0.9, 2.2),
    Offset(-1.0, 1.6),
  ];

  static const _depths = <double>[0.0, 0.8, 1.2, 0.6, 1.4, 0.4];

  static DeckRestPose restPose(int index, {required bool selected}) {
    final i = index.clamp(0, _rotations.length - 1);
    if (selected) {
      return const DeckRestPose(
        rotation: 0,
        offset: Offset(0, -3),
        opacity: 1.0,
        depth: 0,
        lift: 1.0,
      );
    }
    return DeckRestPose(
      rotation: _rotations[i],
      offset: _offsets[i],
      opacity: 0.90 - _depths[i] * 0.015,
      depth: _depths[i],
      lift: 0,
    );
  }

  static List<BoxShadow> cardShadows({
    required bool selected,
    required Color accent,
    required double depth,
    double glow = 0,
  }) {
    final near = selected ? 1.0 : 0.55 - depth * 0.04;
    return [
      BoxShadow(
        color: AppColors.background.withValues(alpha: 0.55 * near),
        blurRadius: selected ? 18 : 22 + depth * 2,
        offset: Offset(0, selected ? 6 : 10 + depth),
        spreadRadius: selected ? -4 : -6,
      ),
      BoxShadow(
        color: accent.withValues(alpha: (selected ? 0.18 : 0.06) + glow * 0.08),
        blurRadius: selected ? 20 : 12,
        spreadRadius: selected ? -2 : -4,
      ),
    ];
  }

  static const pressLift = -5.0;
  static const pressDelay = Duration.zero;
  static const pressDuration = OraclySignatureMotion.press;
  static const lightTravelDuration = Duration(seconds: 26);
}

@immutable
class DeckRestPose {
  const DeckRestPose({
    required this.rotation,
    required this.offset,
    required this.opacity,
    required this.depth,
    required this.lift,
  });

  final double rotation;
  final Offset offset;
  final double opacity;
  final double depth;
  final double lift;
}

/// Premium deck card back — texture, gold emboss, traveling light.
class DeckSelectionCardBackPainter extends CustomPainter {
  DeckSelectionCardBackPainter({
    required this.deck,
    required this.lightPhase,
    required this.selected,
  });

  final TarotDeckOption deck;
  final double lightPhase;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final style = deck.visualStyle;
    final w = size.width;
    final h = size.height;
    final c = Offset(w / 2, h / 2);

    _paintTexture(canvas, size);
    _paintEmbossedFrame(canvas, size);
    _paintGeometry(canvas, c, w, style);
    _paintTravelingLight(canvas, size);
    if (selected) _paintSelectionGlow(canvas, size, deck.accent);
  }

  void _paintTexture(Canvas canvas, Size size) {
    for (var i = 0; i < 18; i++) {
      final seed = i * 13 + deck.id.hashCode;
      final x = _pseudo(seed) * size.width;
      final y = _pseudo(seed + 5) * size.height;
      canvas.drawCircle(
        Offset(x, y),
        0.4 + _pseudo(seed + 9) * 0.35,
        Paint()
          ..color = AppColors.white.withValues(alpha: 0.02 + _pseudo(seed + 11) * 0.02),
      );
    }
  }

  void _paintEmbossedFrame(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(5, 5, size.width - 10, size.height - 10),
      const Radius.circular(5),
    );
    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 10, size.width - 20, size.height - 20),
      const Radius.circular(3.5),
    );
    canvas.drawRRect(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = AppColors.gold.withValues(alpha: 0.48),
    );
    canvas.drawRRect(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.45
        ..color = AppColors.goldLight.withValues(alpha: 0.22),
    );
    for (var i = 0; i < 4; i++) {
      final corner = [
        const Offset(8, 8),
        Offset(size.width - 8, 8),
        Offset(size.width - 8, size.height - 8),
        Offset(8, size.height - 8),
      ][i];
      canvas.drawCircle(
        corner,
        1.4,
        Paint()..color = AppColors.gold.withValues(alpha: 0.55),
      );
    }
  }

  void _paintGeometry(Canvas canvas, Offset c, double w, DeckVisualStyle style) {
    final gold = style == DeckVisualStyle.golden
        ? AppColors.goldLight
        : AppColors.gold.withValues(alpha: 0.75);
    canvas.drawCircle(
      c,
      w * 0.22,
      Paint()..color = deck.accent.withValues(alpha: 0.10),
    );
    canvas.drawCircle(
      c,
      w * 0.14,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.55
        ..color = gold.withValues(alpha: 0.45),
    );
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        c + Offset(math.cos(a) * w * 0.08, math.sin(a) * w * 0.08),
        c + Offset(math.cos(a) * w * 0.20, math.sin(a) * w * 0.20),
        Paint()
          ..strokeWidth = 0.35
          ..color = gold.withValues(alpha: 0.20),
      );
    }
    canvas.drawCircle(c, 2, Paint()..color = AppColors.goldLight.withValues(alpha: 0.75));
  }

  void _paintTravelingLight(Canvas canvas, Size size) {
    // Non-linear sweep — avoids obvious mechanical loop.
    final t = lightPhase;
    final eased = math.sin(t * math.pi * 2) * 0.5 + 0.5;
    final bandCenter = -0.4 + eased * 1.6;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(bandCenter - 0.35, -1),
          end: Alignment(bandCenter + 0.35, 1),
          colors: [
            Colors.transparent,
            AppColors.white.withValues(alpha: 0.04),
            AppColors.goldLight.withValues(alpha: 0.07),
            AppColors.white.withValues(alpha: 0.03),
            Colors.transparent,
          ],
          stops: const [0.0, 0.38, 0.5, 0.62, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.drawLine(
      Offset(size.width * (0.15 + eased * 0.55), 0),
      Offset(size.width * (0.05 + eased * 0.45), size.height),
      Paint()
        ..strokeWidth = 0.35
        ..color = AppColors.goldLight.withValues(alpha: 0.05),
    );
  }

  void _paintSelectionGlow(Canvas canvas, Size size, Color accent) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: [
            accent.withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  double _pseudo(int seed) {
    final x = math.sin(seed * 12.9898) * 43758.5453;
    return x - x.floor();
  }

  @override
  bool shouldRepaint(covariant DeckSelectionCardBackPainter old) =>
      old.lightPhase != lightPhase ||
      old.selected != selected ||
      old.deck.id != deck.id;
}

/// Crystal reflection on deck artwork edge.
class DeckArtworkReflectionPainter extends CustomPainter {
  const DeckArtworkReflectionPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final drift = 0.5 + 0.5 * math.sin(phase * math.pi * 2);
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * (0.08 + drift * 0.04)),
      Offset(size.width * 0.55, size.height * (0.06 + drift * 0.03)),
      Paint()
        ..strokeWidth = 0.5
        ..color = AppColors.goldLight.withValues(alpha: 0.06),
    );
  }

  @override
  bool shouldRepaint(covariant DeckArtworkReflectionPainter old) =>
      old.phase != phase;
}

/// Sacred table glow — bottom atmospheric anchor.
class DeckSelectionTableGlowPainter extends CustomPainter {
  const DeckSelectionTableGlowPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final breathe = 0.94 + math.sin(phase * math.pi * 2) * 0.06;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 1.15),
          radius: 0.95,
          colors: [
            AppColors.gold.withValues(alpha: 0.05 * breathe),
            AppColors.purple.withValues(alpha: 0.04),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 0.72],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant DeckSelectionTableGlowPainter old) =>
      old.phase != phase;
}
