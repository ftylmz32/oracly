/// EPIC-024 — Reusable CustomPainters for hero artwork layers.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_colors.dart';
import 'hero_art_tokens.dart';

/// Seeded pseudo-random helper — stable particle positions per hero.
class HeroArtSeed {
  HeroArtSeed(this.seed);

  final int seed;

  double unit(int index) {
    final n = math.sin((seed + index) * 12.9898) * 43758.5453;
    return n - n.floor();
  }

  Offset particleOffset(int index, double radius) {
    final a = unit(index) * math.pi * 2;
    final r = radius * (0.35 + unit(index + 17) * 0.65);
    return Offset(math.cos(a) * r, math.sin(a) * r);
  }
}

/// Layer 1 — deep cinematic background.
class HeroBackgroundPainter extends CustomPainter {
  const HeroBackgroundPainter({
    required this.theme,
    required this.phase,
  });

  final HeroArtTheme theme;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.46);
    final colors = HeroArtTokens.backgroundGradient(theme);

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Offset.zero & size),
    );

    final accent = HeroArtTokens.glowFor(theme);
    canvas.drawCircle(
      center,
      size.shortestSide * (0.52 + phase * 0.04),
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: 0.14 + phase * 0.06),
            accent.withValues(alpha: 0.04),
            AppColors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(
          Rect.fromCircle(center: center, radius: size.shortestSide * 0.55),
        ),
    );

    if (theme == HeroArtTheme.dream || theme == HeroArtTheme.astrology) {
      _drawStars(canvas, size, phase);
    }
  }

  void _drawStars(Canvas canvas, Size size, double phase) {
    final seed = HeroArtSeed(theme.index * 31);
    final paint = Paint()..color = AppColors.goldLight.withValues(alpha: 0.35);
    for (var i = 0; i < 28; i++) {
      final x = seed.unit(i) * size.width;
      final y = seed.unit(i + 7) * size.height * 0.72;
      final twinkle = 0.4 + math.sin(phase * math.pi * 2 + i) * 0.3;
      canvas.drawCircle(
        Offset(x, y),
        0.6 + seed.unit(i + 3) * 1.2,
        paint..color = AppColors.goldLight.withValues(alpha: 0.18 * twinkle),
      );
    }
  }

  @override
  bool shouldRepaint(covariant HeroBackgroundPainter old) =>
      old.phase != phase || old.theme != theme;
}

/// Layer 2 — soft cinematic light wash.
class HeroLightPainter extends CustomPainter {
  const HeroLightPainter({
    required this.theme,
    required this.phase,
  });

  final HeroArtTheme theme;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final drift = math.sin(phase * math.pi * 2) * 0.06;
    final center = Offset(
      size.width * (0.5 + drift),
      size.height * (0.38 + math.cos(phase * math.pi * 2) * 0.03),
    );
    final accent = HeroArtTokens.accentFor(theme);

    canvas.drawCircle(
      center,
      size.shortestSide * 0.38,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: 0.10 + phase * 0.05),
            AppColors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: size.shortestSide * 0.42),
        ),
    );

    final highlight = Offset(
      center.dx - size.width * 0.12,
      center.dy - size.height * 0.14,
    );
    canvas.drawCircle(
      highlight,
      size.shortestSide * 0.08,
      Paint()
        ..color = AppColors.textPrimary.withValues(alpha: 0.06 + phase * 0.03),
    );
  }

  @override
  bool shouldRepaint(covariant HeroLightPainter old) =>
      old.phase != phase || old.theme != theme;
}

/// Layer 4 — outer glow pulse.
class HeroGlowPainter extends CustomPainter {
  const HeroGlowPainter({
    required this.theme,
    required this.phase,
  });

  final HeroArtTheme theme;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.48);
    final pulse = HeroArtTokens.glowPulseMin +
        (HeroArtTokens.glowPulseMax - HeroArtTokens.glowPulseMin) * phase;
    final glow = HeroArtTokens.glowFor(theme);

    canvas.drawCircle(
      center,
      size.shortestSide * 0.34 * pulse,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18)
        ..color = glow.withValues(alpha: 0.22 + phase * 0.12),
    );

    canvas.drawCircle(
      center,
      size.shortestSide * 0.42 * pulse,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = HeroArtTokens.accentFor(theme).withValues(alpha: 0.08),
    );
  }

  @override
  bool shouldRepaint(covariant HeroGlowPainter old) =>
      old.phase != phase || old.theme != theme;
}

/// Layer 5 — floating dust particles.
class HeroParticlePainter extends CustomPainter {
  const HeroParticlePainter({
    required this.seed,
    required this.phase,
    required this.theme,
    this.density = 22,
  });

  final int seed;
  final double phase;
  final HeroArtTheme theme;
  final int density;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = HeroArtSeed(seed);
    final center = Offset(size.width / 2, size.height * 0.48);
    final accent = HeroArtTokens.accentFor(theme);

    for (var i = 0; i < density; i++) {
      final base = rng.particleOffset(i, size.shortestSide * 0.46);
      final drift = Offset(
        math.sin(phase * math.pi * 2 + i * 0.7) * 4,
        math.cos(phase * math.pi * 2 + i * 0.5) * 3,
      );
      final pos = center + base + drift;
      final alpha = (0.04 + rng.unit(i + 9) * 0.06) * (0.7 + phase * 0.3);
      final radius = 0.9 + rng.unit(i + 4) * 1.4;

      canvas.drawCircle(
        pos,
        radius,
        Paint()
          ..color = (i.isEven ? accent : AppColors.secondaryPurple)
              .withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant HeroParticlePainter old) =>
      old.phase != phase || old.seed != seed;
}

/// Layer 6 — small orbiting lights.
class HeroOrbitPainter extends CustomPainter {
  const HeroOrbitPainter({
    required this.seed,
    required this.phase,
    required this.theme,
    this.orbitCount = 5,
  });

  final int seed;
  final double phase;
  final HeroArtTheme theme;
  final int orbitCount;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.48);
    final rng = HeroArtSeed(seed + 11);
    final accent = HeroArtTokens.accentFor(theme);

    for (var i = 0; i < orbitCount; i++) {
      final orbitR = size.shortestSide * (0.28 + i * 0.05);
      final angle = phase * math.pi * 2 + i * 1.25 + rng.unit(i) * math.pi;
      final pos = center +
          Offset(math.cos(angle) * orbitR, math.sin(angle) * orbitR * 0.72);
      canvas.drawCircle(
        pos,
        1.4 + rng.unit(i + 2),
        Paint()
          ..color = accent.withValues(alpha: 0.45 + phase * 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant HeroOrbitPainter old) =>
      old.phase != phase || old.seed != seed;
}

/// Crystal orb — center artwork for [HeroOrb].
class OrbArtworkPainter extends CustomPainter {
  const OrbArtworkPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.5);
    final r = size.shortestSide * 0.28;

    canvas.drawCircle(
      center,
      r * 1.18,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
        ..color = AppColors.glowGold.withValues(alpha: 0.28 + phase * 0.14),
    );

    canvas.drawCircle(
      center,
      r * 1.08,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.goldLight.withValues(alpha: 0.12),
            AppColors.primaryPurple.withValues(alpha: 0.08),
            AppColors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r * 1.1)),
    );

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(-0.25 + phase * 0.08, -0.32),
          colors: [
            AppColors.goldLight.withValues(alpha: 0.95),
            AppColors.primaryPurple.withValues(alpha: 0.85),
            AppColors.purpleDark,
            AppColors.background.withValues(alpha: 0.92),
          ],
          stops: const [0.0, 0.32, 0.68, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    final highlight = center + Offset(-r * 0.28, -r * 0.32);
    canvas.drawOval(
      Rect.fromCenter(
        center: highlight,
        width: r * 0.42,
        height: r * 0.28,
      ),
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.textPrimary.withValues(alpha: 0.55),
            AppColors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: highlight, radius: r * 0.22)),
    );

    canvas.drawCircle(
      center + Offset(r * 0.08, r * 0.1),
      r * 0.22,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.secondaryPurple.withValues(alpha: 0.75),
            AppColors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r * 0.25)),
    );

    canvas.drawCircle(
      center,
      r * 1.02,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.gold.withValues(alpha: 0.35 + phase * 0.15),
    );
  }

  @override
  bool shouldRepaint(covariant OrbArtworkPainter old) => old.phase != phase;
}

/// Floating tarot cards artwork.
class TarotArtworkPainter extends CustomPainter {
  const TarotArtworkPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.5);
    _drawCard(
      canvas,
      center + Offset(-size.width * 0.12, 6 + math.sin(phase * math.pi * 2) * 4),
      size.shortestSide * 0.22,
      -0.14,
      phase,
    );
    _drawCard(
      canvas,
      center + Offset(size.width * 0.1, -8 + math.cos(phase * math.pi * 2) * 3),
      size.shortestSide * 0.24,
      0.1,
      phase * 0.9,
    );

    final fog = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primaryPurple.withValues(alpha: 0.18),
          AppColors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: size.shortestSide * 0.42),
      );
    canvas.drawCircle(center, size.shortestSide * 0.38, fog);
  }

  void _drawCard(
    Canvas canvas,
    Offset center,
    double h,
    double tilt,
    double phase,
  ) {
    final w = h * 0.62;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tilt);
    final rect = Rect.fromCenter(center: Offset.zero, width: w, height: h);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceElevated,
            AppColors.surface,
            AppColors.purpleDark.withValues(alpha: 0.9),
          ],
        ).createShader(rect),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.gold.withValues(alpha: 0.55 + phase * 0.2),
    );

    canvas.drawCircle(
      Offset(0, -h * 0.12),
      w * 0.12,
      Paint()..color = AppColors.goldLight.withValues(alpha: 0.35),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TarotArtworkPainter old) => old.phase != phase;
}

/// Moonlit dream portal artwork.
class DreamArtworkPainter extends CustomPainter {
  const DreamArtworkPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.46);
    final portalR = size.shortestSide * 0.26;

    canvas.drawCircle(
      center,
      portalR * 1.35,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.secondaryPurple.withValues(alpha: 0.22),
            AppColors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: portalR * 1.4)),
    );

    canvas.drawCircle(
      center + Offset(0, math.sin(phase * math.pi * 2) * 2),
      portalR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.goldLight.withValues(alpha: 0.35),
            AppColors.secondaryPurple.withValues(alpha: 0.55),
            AppColors.purpleDark.withValues(alpha: 0.85),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: portalR)),
    );

    final moonC = center + Offset(-portalR * 0.55, -portalR * 0.35);
    canvas.drawCircle(
      moonC,
      portalR * 0.38,
      Paint()..color = AppColors.goldLight.withValues(alpha: 0.88),
    );
    canvas.drawCircle(
      moonC + Offset(portalR * 0.18, -portalR * 0.06),
      portalR * 0.34,
      Paint()..color = AppColors.purpleDark.withValues(alpha: 0.92),
    );

    for (var i = 0; i < 3; i++) {
      final y = center.dy + portalR * 0.55 + i * 8;
      final w = size.width * (0.35 + i * 0.08);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(center.dx, y), width: w, height: 14),
          const Radius.circular(20),
        ),
        Paint()
          ..color = AppColors.surfaceElevated.withValues(alpha: 0.22 - i * 0.04),
      );
    }
  }

  @override
  bool shouldRepaint(covariant DreamArtworkPainter old) => old.phase != phase;
}

/// Golden zodiac wheel artwork.
class AstrologyArtworkPainter extends CustomPainter {
  const AstrologyArtworkPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.5);
    final r = size.shortestSide * 0.30;

    canvas.drawCircle(
      center,
      r * 1.06,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = AppColors.gold.withValues(alpha: 0.55),
    );

    canvas.drawCircle(
      center,
      r * 0.72,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = AppColors.goldLight.withValues(alpha: 0.28),
    );

    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6 + phase * 0.08;
      final outer = center + Offset(math.cos(a) * r, math.sin(a) * r);
      final inner = center + Offset(math.cos(a) * r * 0.86, math.sin(a) * r * 0.86);
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..strokeWidth = 1.4
          ..color = AppColors.gold.withValues(alpha: 0.45),
      );
      final sym = center + Offset(math.cos(a) * r * 1.14, math.sin(a) * r * 1.14);
      canvas.drawCircle(
        sym,
        2.2,
        Paint()..color = AppColors.goldLight.withValues(alpha: 0.65),
      );
    }

    _drawConstellation(canvas, center, r, phase);
  }

  void _drawConstellation(Canvas canvas, Offset center, double r, double phase) {
    final pts = [
      Offset(-0.3, -0.1),
      Offset(-0.05, 0.05),
      Offset(0.18, -0.18),
      Offset(0.32, 0.08),
    ];
    final paint = Paint()
      ..strokeWidth = 0.8
      ..color = AppColors.secondaryPurple.withValues(alpha: 0.5);
    for (var i = 0; i < pts.length - 1; i++) {
      final a = Offset(pts[i].dx * r, pts[i].dy * r) + center;
      final b = Offset(pts[i + 1].dx * r, pts[i + 1].dy * r) + center;
      canvas.drawLine(a, b, paint);
      canvas.drawCircle(a, 1.8, Paint()..color = AppColors.goldLight.withValues(alpha: 0.7));
    }
    canvas.drawCircle(
      Offset(pts.last.dx * r, pts.last.dy * r) + center,
      1.8,
      Paint()..color = AppColors.goldLight.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(covariant AstrologyArtworkPainter old) => old.phase != phase;
}

/// Natal birth chart wheel artwork.
class BirthChartArtworkPainter extends CustomPainter {
  const BirthChartArtworkPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.5);
    final r = size.shortestSide * 0.30;

    for (var ring = 1; ring <= 3; ring++) {
      canvas.drawCircle(
        center,
        r * (0.45 + ring * 0.18),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring == 3 ? 1.8 : 0.7
          ..color = AppColors.gold.withValues(alpha: ring == 3 ? 0.5 : 0.22),
      );
    }

    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6 + phase * 0.05;
      canvas.drawLine(
        center,
        center + Offset(math.cos(a) * r, math.sin(a) * r),
        Paint()
          ..strokeWidth = 0.6
          ..color = AppColors.goldLight.withValues(alpha: 0.18),
      );
    }

    for (var i = 0; i < 6; i++) {
      final a = phase * math.pi * 2 + i * 1.05;
      final p = center + Offset(math.cos(a) * r * 0.62, math.sin(a) * r * 0.62);
      canvas.drawCircle(
        p,
        2.5,
        Paint()..color = AppColors.secondaryPurple.withValues(alpha: 0.75),
      );
    }
  }

  @override
  bool shouldRepaint(covariant BirthChartArtworkPainter old) =>
      old.phase != phase;
}

/// Sacred AI chamber artwork.
class AiArtworkPainter extends CustomPainter {
  const AiArtworkPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.5);
    final chamberW = size.width * 0.52;
    final chamberH = size.height * 0.42;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: chamberW, height: chamberH),
        const Radius.circular(18),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surfaceElevated.withValues(alpha: 0.65),
            AppColors.surface.withValues(alpha: 0.35),
          ],
        ).createShader(Rect.fromCenter(
          center: center,
          width: chamberW,
          height: chamberH,
        )),
    );

    final orbR = size.shortestSide * 0.14;
    canvas.drawCircle(
      center + Offset(0, math.sin(phase * math.pi * 2) * 2),
      orbR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.secondaryPurple,
            AppColors.primaryPurple,
            AppColors.purpleDark,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: orbR)),
    );

    const runes = ['ᚠ', 'ᛟ', 'ᚨ', 'ᚱ'];
    for (var i = 0; i < runes.length; i++) {
      final a = phase * math.pi * 2 + i * math.pi / 2;
      final pos = center +
          Offset(math.cos(a) * chamberW * 0.34, math.sin(a) * chamberH * 0.38);
      final tp = TextPainter(
        text: TextSpan(
          text: runes[i],
          style: TextStyle(
            color: AppColors.gold.withValues(alpha: 0.55),
            fontSize: 14,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant AiArtworkPainter old) => old.phase != phase;
}

/// Premium royal crown glow artwork.
class PremiumArtworkPainter extends CustomPainter {
  const PremiumArtworkPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.52);
    final crownW = size.width * 0.38;
    final crownH = size.height * 0.22;

    canvas.drawCircle(
      center + Offset(0, -crownH * 0.4),
      crownW * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.goldLight.withValues(alpha: 0.35 + phase * 0.15),
            AppColors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: crownW)),
    );

    final path = Path()
      ..moveTo(center.dx - crownW / 2, center.dy + crownH * 0.35)
      ..lineTo(center.dx - crownW * 0.28, center.dy - crownH * 0.15)
      ..lineTo(center.dx - crownW * 0.12, center.dy + crownH * 0.05)
      ..lineTo(center.dx, center.dy - crownH * 0.42)
      ..lineTo(center.dx + crownW * 0.12, center.dy + crownH * 0.05)
      ..lineTo(center.dx + crownW * 0.28, center.dy - crownH * 0.15)
      ..lineTo(center.dx + crownW / 2, center.dy + crownH * 0.35)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.goldLight,
            AppColors.gold,
            AppColors.gold.withValues(alpha: 0.75),
          ],
        ).createShader(Rect.fromCenter(
          center: center,
          width: crownW,
          height: crownH,
        )),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.goldLight.withValues(alpha: 0.65),
    );
  }

  @override
  bool shouldRepaint(covariant PremiumArtworkPainter old) => old.phase != phase;
}

/// Celestial profile identity artwork.
class ProfileArtworkPainter extends CustomPainter {
  const ProfileArtworkPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.5);
    final r = size.shortestSide * 0.26;

    canvas.drawCircle(
      center,
      r * 1.22,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = AppColors.gold.withValues(alpha: 0.28),
    );

    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + phase * 0.12;
      final p = center + Offset(math.cos(a) * r * 1.18, math.sin(a) * r * 1.18);
      canvas.drawCircle(
        p,
        2.0,
        Paint()..color = AppColors.goldLight.withValues(alpha: 0.6),
      );
      if (i > 0) {
        final prev = i - 1;
        final a0 = prev * math.pi / 4 + phase * 0.12;
        final p0 = center + Offset(math.cos(a0) * r * 1.18, math.sin(a0) * r * 1.18);
        canvas.drawLine(
          p0,
          p,
          Paint()
            ..strokeWidth = 0.6
            ..color = AppColors.gold.withValues(alpha: 0.22),
        );
      }
    }

    canvas.drawCircle(
      center,
      r * 0.78,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.purpleGlow.withValues(alpha: 0.55),
            AppColors.purpleDark.withValues(alpha: 0.9),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    canvas.drawCircle(
      center,
      r * 0.78,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = AppColors.gold.withValues(alpha: 0.55 + phase * 0.15),
    );
  }

  @override
  bool shouldRepaint(covariant ProfileArtworkPainter old) => old.phase != phase;
}
