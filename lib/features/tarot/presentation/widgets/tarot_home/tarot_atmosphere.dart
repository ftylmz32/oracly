/// OR-417 — Tarot Home premium atmosphere: crystal light, spread identity, depth.
library;

import 'dart:math' show cos, pi, sin;

import 'package:flutter/material.dart';

import 'oracly_sacred_identity.dart';
import 'spread_visual_style.dart';

/// Emotional lighting and depth tokens — visual only, no layout impact.
abstract final class TarotAtmosphere {
  TarotAtmosphere._();

  // ── Hero dominance ─────────────────────────────────────────────────────────

  /// Non-hero sections yield visual presence to the crystal ball.
  static double sectionPresenceWeight(int sectionIndex) => switch (sectionIndex) {
        0 => 1.0,
        1 => 0.92,
        2 => 0.86,
        3 => 0.82,
        _ => 0.78,
      };

  /// Hero orb chamber glow — warm anchor, never competes with orb itself.
  static RadialGradient heroOrbChamberGlow(double phase) {
    final breathe = 0.96 + 0.04 * sin(phase * pi * 2);
    return RadialGradient(
      center: const Alignment(0, -0.18),
      radius: 0.88,
      colors: [
        OraclySacredPalette.champagne.withValues(alpha: 0.04 * breathe),
        OraclySacredPalette.purpleEnergySoft.withValues(alpha: 0.025 * breathe),
        Colors.transparent,
      ],
      stops: const [0.0, 0.38, 1.0],
    );
  }

  // ── Crystal light falloff from Hero ────────────────────────────────────────

  /// Warmth received by spread grid cell — top row warmer, bottom cooler.
  static double spreadCrystalWarmth(int gridIndex) {
    const warmth = [0.14, 0.11, 0.08, 0.05];
    return warmth[gridIndex.clamp(0, 3)];
  }

  /// Cool violet ambience increases with distance from orb.
  static double spreadCrystalCool(int gridIndex) {
    const cool = [0.06, 0.07, 0.09, 0.11];
    return cool[gridIndex.clamp(0, 3)];
  }

  /// Overlay gradient for spread cards — extremely subtle temperature shift.
  static Gradient spreadProximityLight(int gridIndex) {
    final warm = spreadCrystalWarmth(gridIndex);
    final cool = spreadCrystalCool(gridIndex);
    return RadialGradient(
      center: const Alignment(0, -0.72),
      radius: 1.45,
      colors: [
        OraclySacredPalette.champagne.withValues(alpha: warm * 0.55),
        OraclySacredPalette.purpleEnergySoft.withValues(alpha: cool * 0.45),
        Colors.transparent,
      ],
      stops: const [0.0, 0.38, 1.0],
    );
  }

  /// Composition-only depth — first tile invites, others recede quietly.
  static SpreadGridPresence spreadGridPresence(
    int gridIndex, {
    bool selected = false,
  }) {
    if (selected) {
      return const SpreadGridPresence(
        liftY: -2.5,
        scale: 1.0,
        shadowDepth: 1.1,
        warmthBoost: 0,
      );
    }
    const presences = <SpreadGridPresence>[
      SpreadGridPresence(
        liftY: -3.5,
        scale: 1.008,
        shadowDepth: 1.06,
        warmthBoost: 0.05,
      ),
      SpreadGridPresence(
        liftY: 0,
        scale: 0.994,
        shadowDepth: 0.93,
        warmthBoost: 0,
      ),
      SpreadGridPresence(
        liftY: 2,
        scale: 0.988,
        shadowDepth: 0.87,
        warmthBoost: -0.02,
      ),
      SpreadGridPresence(
        liftY: 3.5,
        scale: 0.982,
        shadowDepth: 0.81,
        warmthBoost: -0.04,
      ),
    ];
    return presences[gridIndex.clamp(0, presences.length - 1)];
  }

  // ── Premium depth ──────────────────────────────────────────────────────────

  static const glassThicknessBoost = 1.08;
  static const embedShadowDepth = 1.12;
  static const goldEngraveBoost = 1.0;
  static const backgroundVignette = 0.82;

  static double crystalShimmer(double phase) =>
      0.008 + 0.006 * sin((phase + 0.2) * pi * 2);

  static double microLightDrift(double phase) =>
      0.5 + 0.5 * sin((phase * 0.45 + 0.1) * pi * 2);

  static double dustAlpha(double phase, {double base = 0.06}) =>
      base + 0.025 * sin(phase * pi * 2);

  // ── Spread card identity ───────────────────────────────────────────────────

  static SpreadCardIdentity identity(SpreadVisualStyle style) =>
      switch (style) {
        SpreadVisualStyle.single => const SpreadCardIdentity(
              accent: Color(0xFFC8C0D0),
              accentSoft: Color(0xFF6A6478),
              ornament: SpreadOrnamentKind.solitaryStar,
              lightBias: 0.06,
            ),
        SpreadVisualStyle.threeCard => const SpreadCardIdentity(
              accent: Color(0xFF9B7EC8),
              accentSoft: Color(0xFF5A4088),
              ornament: SpreadOrnamentKind.triadArc,
              lightBias: 0.08,
            ),
        SpreadVisualStyle.fiveCard => const SpreadCardIdentity(
              accent: Color(0xFF6A8FD4),
              accentSoft: Color(0xFF3A5088),
              ornament: SpreadOrnamentKind.pentacleArc,
              lightBias: 0.10,
            ),
        SpreadVisualStyle.celticCross => const SpreadCardIdentity(
              accent: Color(0xFFD4BC7A),
              accentSoft: Color(0xFF8A6848),
              ornament: SpreadOrnamentKind.sacredCross,
              lightBias: 0.11,
            ),
      };
}

/// Per-spread emotional accent and ornament personality.
@immutable
class SpreadCardIdentity {
  const SpreadCardIdentity({
    required this.accent,
    required this.accentSoft,
    required this.ornament,
    required this.lightBias,
  });

  final Color accent;
  final Color accentSoft;
  final SpreadOrnamentKind ornament;
  final double lightBias;
}

enum SpreadOrnamentKind {
  solitaryStar,
  triadArc,
  pentacleArc,
  sacredCross,
}

/// Handcrafted grid presence — composition, not selection chrome.
@immutable
class SpreadGridPresence {
  const SpreadGridPresence({
    required this.liftY,
    required this.scale,
    required this.shadowDepth,
    required this.warmthBoost,
  });

  final double liftY;
  final double scale;
  final double shadowDepth;
  final double warmthBoost;
}

/// Handcrafted micro-ornament painted inside spread ritual tiles.
class SpreadCardOrnamentPainter extends CustomPainter {
  const SpreadCardOrnamentPainter({
    required this.kind,
    required this.phase,
    this.alpha = 0.14,
  });

  final SpreadOrnamentKind kind;
  final double phase;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case SpreadOrnamentKind.solitaryStar:
        _paintSolitaryStar(canvas, size);
      case SpreadOrnamentKind.triadArc:
        _paintTriadArc(canvas, size);
      case SpreadOrnamentKind.pentacleArc:
        _paintPentacleArc(canvas, size);
      case SpreadOrnamentKind.sacredCross:
        _paintSacredCross(canvas, size);
    }
  }

  void _paintSolitaryStar(Canvas canvas, Size size) {
    final cx = size.width * 0.84;
    final cy = size.height * 0.16;
    final pulse = 0.85 + sin(phase * pi * 2) * 0.15;

    canvas.drawCircle(
      Offset(cx, cy),
      10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.35
        ..color = OraclySacredPalette.goldEngrave(alpha * 0.65 * pulse),
    );
    for (var i = 0; i < 4; i++) {
      final a = i * pi / 2 + phase * 0.15;
      canvas.drawLine(
        Offset(cx + cos(a) * 4, cy + sin(a) * 4),
        Offset(cx + cos(a) * 9, cy + sin(a) * 9),
        Paint()
          ..strokeWidth = 0.3
          ..color = OraclySacredPalette.champagne.withValues(alpha: alpha * 0.5),
      );
    }
  }

  void _paintTriadArc(Canvas canvas, Size size) {
    final cx = size.width * 0.14;
    final cy = size.height * 0.18;
    final path = Path()
      ..moveTo(cx - 8, cy + 4)
      ..quadraticBezierTo(cx, cy - 6, cx + 8, cy + 4);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.35
        ..color = OraclySacredPalette.goldEngrave(alpha * 0.7),
    );
    for (var i = -1; i <= 1; i++) {
      canvas.drawCircle(
        Offset(cx + i * 7.0, cy + 5),
        0.8,
        Paint()
          ..color = OraclySacredPalette.champagne.withValues(alpha: alpha * 0.55),
      );
    }
  }

  void _paintPentacleArc(Canvas canvas, Size size) {
    final cx = size.width * 0.86;
    final cy = size.height * 0.82;
    for (var i = 0; i < 5; i++) {
      final a = -pi / 2 + i * 2 * pi / 5 + phase * 0.08;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + cos(a) * 11, cy + sin(a) * 11),
        Paint()
          ..strokeWidth = 0.28
          ..color = OraclySacredPalette.goldHairline(alpha * 0.55),
      );
    }
    canvas.drawCircle(
      Offset(cx, cy),
      4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.3
        ..color = OraclySacredPalette.goldEngrave(alpha * 0.6),
    );
  }

  void _paintSacredCross(Canvas canvas, Size size) {
    final cx = size.width * 0.12;
    final cy = size.height * 0.78;
    final geo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.35
      ..color = OraclySacredPalette.goldEngrave(alpha * 0.75);
    canvas.drawLine(Offset(cx - 7, cy), Offset(cx + 7, cy), geo);
    canvas.drawLine(Offset(cx, cy - 9), Offset(cx, cy + 5), geo);
    canvas.drawCircle(
      Offset(cx, cy),
      12,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.28
        ..color = OraclySacredPalette.goldHairline(alpha * 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant SpreadCardOrnamentPainter old) =>
      old.kind != kind || old.phase != phase || old.alpha != alpha;
}
