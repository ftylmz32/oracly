/// OR-413 — Integrated luxury architecture for the Home screen.
///
/// Panels carved from the same mystical world — not pasted on top.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import 'home_focus.dart';
import 'home_presence.dart';
import 'home_atmosphere.dart';
import 'home_observatory.dart';

/// How close a surface sits to the hero orb chamber spill.
enum HomeOrbProximity {
  high,
  medium,
  low,
}

/// Engraving density on embedded crystal panels.
enum HomeSurfaceDetail {
  rich,
  standard,
  whisper,
}

/// Environment palette — glass inherits nebula and obsidian chamber tones.
abstract final class HomeArchitecture {
  HomeArchitecture._();

  static const Color _nebulaBleed = HomeAtmosphere.mysteryViolet;
  static const Color _chamberDeep = HomeAtmosphere.calmObsidian;
  static const Color _obsidianVeil = HomeAtmosphere.pureGlass;

  static HomeFocusZone _zoneForProximity(HomeOrbProximity proximity) =>
      switch (proximity) {
        HomeOrbProximity.high => HomeFocusZone.spread,
        HomeOrbProximity.medium => HomeFocusZone.daily,
        HomeOrbProximity.low => HomeFocusZone.cosmic,
      };

  static const Duration blendDuration = Duration(milliseconds: 420);

  static HomeOrbProximity proximityFor(HomeFocusZone? zone) =>
      switch (zone) {
        HomeFocusZone.spread => HomeOrbProximity.high,
        HomeFocusZone.daily || HomeFocusZone.premium => HomeOrbProximity.medium,
        HomeFocusZone.ai || HomeFocusZone.cosmic => HomeOrbProximity.low,
        _ => HomeOrbProximity.medium,
      };

  static double _orbTint(HomeOrbProximity proximity) => switch (proximity) {
        HomeOrbProximity.high => 0.16,
        HomeOrbProximity.medium => 0.09,
        HomeOrbProximity.low => 0.04,
      };

  /// Glass body — environment colour bleeds into the surface.
  static LinearGradient environmentGlass(HomeOrbProximity proximity) {
    final tint = _orbTint(proximity);
    final zone = _zoneForProximity(proximity);
    final top = HomeAtmosphere.temper(
      Color.lerp(AppColors.surfaceElevated, _nebulaBleed, tint)!,
      zone,
      strength: 0.12,
    );
    final mid = HomeAtmosphere.temper(
      Color.lerp(AppColors.surface, _obsidianVeil, tint * 0.65)!,
      zone,
    );
    final deep = Color.lerp(AppColors.surface, _chamberDeep, 0.42)!;

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [top, mid, deep],
      stops: const [0.0, 0.52, 1.0],
    );
  }

  /// Daily-energy variant — warmer mid-tone, hopeful light.
  static LinearGradient environmentDailyGlass() => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          HomeAtmosphere.temper(
            const Color(0xFF2C1847),
            HomeFocusZone.daily,
            strength: 0.14,
          ),
          HomeAtmosphere.temper(AppColors.surface, HomeFocusZone.daily),
          Color.lerp(
            HomeAtmosphere.pureGlass,
            HomeAtmosphere.calmObsidian,
            0.38,
          )!,
        ],
        stops: const [0.0, 0.48, 1.0],
      );

  /// Physically embedded shadows — settled into the chamber, not floating.
  static List<BoxShadow> embeddedShadows({
    required HomeOrbProximity proximity,
    double glowMult = 1.0,
  }) {
    final spill = switch (proximity) {
      HomeOrbProximity.high => 0.14,
      HomeOrbProximity.medium => 0.09,
      HomeOrbProximity.low => 0.05,
    };

    return [
      BoxShadow(
        color: AppColors.background.withValues(alpha: 0.55),
        blurRadius: 10,
        offset: const Offset(0, 3),
        spreadRadius: -3,
      ),
      BoxShadow(
        color: AppColors.purple.withValues(alpha: spill * glowMult),
        blurRadius: 28,
        offset: const Offset(0, 10),
        spreadRadius: -8,
      ),
      if (proximity != HomeOrbProximity.low)
        BoxShadow(
          color: AppColors.goldGlow.withValues(alpha: 0.05 * glowMult),
          blurRadius: 18,
          offset: const Offset(0, -2),
          spreadRadius: -10,
        ),
    ];
  }

  /// Border for embedded panels — must be uniform when [borderRadius] is set.
  static Border embeddedBorder({
    required double goldAlpha,
    HomeOrbProximity proximity = HomeOrbProximity.medium,
  }) {
    final sideAlpha = goldAlpha * 0.62;
    final violetSide = _orbTint(proximity) * 0.55 + 0.08;
    final color = Color.lerp(
      AppColors.goldLight.withValues(alpha: goldAlpha * 0.85),
      AppColors.purple.withValues(alpha: violetSide * 0.9),
      0.35,
    )!;

    return Border.all(
      color: color.withValues(alpha: (sideAlpha + violetSide) * 0.55),
      width: AppBorderWidth.hairline,
    );
  }

  /// Full embedded panel shell — glass carved from the chamber wall.
  static BoxDecoration embeddedPanel({
    required BorderRadius radius,
    required HomeOrbProximity proximity,
    double goldBorderAlpha = 0.26,
    double glowMult = 1.0,
  }) =>
      BoxDecoration(
        borderRadius: radius,
        gradient: environmentGlass(proximity),
        border: embeddedBorder(
          goldAlpha: goldBorderAlpha * glowMult.clamp(0.7, 1.25),
          proximity: proximity,
        ),
        boxShadow: embeddedShadows(
          proximity: proximity,
          glowMult: glowMult,
        ),
      );

  /// Downward orb spill connecting hero chamber to panels below.
  static RadialGradient get orbDownSpill => RadialGradient(
        center: const Alignment(0, -0.15),
        radius: 0.95,
        colors: [
          HomeAtmosphere.mysteryViolet.withValues(alpha: 0.10),
          HomeAtmosphere.wisdomGold.withValues(alpha: 0.028),
          AppColors.transparent,
        ],
        stops: const [0.0, 0.38, 1.0],
      );

  static double spillAlpha(HomeOrbProximity proximity) => switch (proximity) {
        HomeOrbProximity.high => 0.14,
        HomeOrbProximity.medium => 0.09,
        HomeOrbProximity.low => 0.05,
      };

  /// Glass purity veil — crystalline surface over embedded panels.
  static double glassPurityAlpha(HomeOrbProximity proximity) =>
      switch (proximity) {
        HomeOrbProximity.high => 0.04,
        HomeOrbProximity.medium => 0.03,
        HomeOrbProximity.low => 0.022,
      };
}

/// Micro-engraving, crystal imperfections, and gold specular on embedded panels.
class HomeArchitectureOverlay extends StatelessWidget {
  const HomeArchitectureOverlay({
    super.key,
    required this.borderRadius,
    this.proximity = HomeOrbProximity.medium,
    this.detail = HomeSurfaceDetail.standard,
  });

  final BorderRadius borderRadius;
  final HomeOrbProximity proximity;
  final HomeSurfaceDetail detail;

  @override
  Widget build(BuildContext context) {
    final scope = HomeFocusScope.maybeOf(context);
    final presence = scope?.presence;

    Widget buildOverlay(double phase) {
      final specular = HomePresenceRhythm.goldSpecular(phase);
      final veil = HomePresenceRhythm.ambientVeil(phase);
      final crystal = HomeObservatoryTime.shimmer(proximity.index);
      final highlight = HomeAtmosphere.microHighlight(phase);
      final purity = HomeArchitecture.glassPurityAlpha(proximity);
      final memory = scope?.orbLightMemory(proximity, seed: detail.index) ??
          HomeArchitecture.spillAlpha(proximity);
      final specInset = AppSpacing.lg +
          specular * 6 +
          HomeObservatoryImperfection.goldSpecularOffset(detail.index) * 4;
      final inset = specInset;

      return ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.92),
                  radius: 1.05,
                  colors: [
                    HomeAtmosphere.mysteryViolet
                        .withValues(alpha: memory * veil),
                    HomeAtmosphere.wisdomGold
                        .withValues(alpha: memory * 0.38 * specular),
                    AppColors.transparent,
                  ],
                  stops: const [0.0, 0.35, 1.0],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.transparent,
                    HomeAtmosphere.wisdomGold
                        .withValues(alpha: crystal + purity * 0.5),
                    AppColors.transparent,
                  ],
                  stops: [
                    (highlight * 0.35).clamp(0.0, 0.4),
                    (0.42 + highlight * 0.12).clamp(0.35, 0.55),
                    1.0,
                  ],
                ),
              ),
            ),
            CustomPaint(
              painter: _HomeEngravedSurfacePainter(detail: detail),
            ),
            Positioned(
              top: 0,
              left: inset,
              right: inset,
              child: Container(
                height: 0.6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.transparent,
                      AppColors.goldLight.withValues(
                        alpha: 0.10 + specular * 0.06,
                      ),
                      AppColors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.05,
                    colors: [
                      AppColors.transparent,
                      HomeAtmosphere.calmObsidian
                          .withValues(alpha: 0.05 * veil),
                    ],
                    stops: const [0.72, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (presence == null) {
      return buildOverlay(HomePresenceRhythm.clockPhase());
    }

    return AnimatedBuilder(
      animation: presence,
      builder: (context, _) => buildOverlay(presence.value),
    );
  }
}

class _HomeEngravedSurfacePainter extends CustomPainter {
  const _HomeEngravedSurfacePainter({required this.detail});

  final HomeSurfaceDetail detail;

  @override
  void paint(Canvas canvas, Size size) {
    final meridian = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.35
      ..color = AppColors.gold.withValues(alpha: 0.055);

    final crystal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.25
      ..color = AppColors.purpleLight.withValues(alpha: 0.04);

    if (detail != HomeSurfaceDetail.whisper) {
      canvas.drawLine(
        Offset(size.width * 0.08, size.height * 0.28),
        Offset(size.width * 0.92, size.height * 0.28),
        meridian,
      );
    }

    if (detail == HomeSurfaceDetail.rich) {
      canvas.drawLine(
        Offset(size.width * 0.12, size.height * 0.72),
        Offset(size.width * 0.88, size.height * 0.72),
        crystal,
      );
    }

    for (var i = 0; i < 4; i++) {
      final x = size.width * (0.15 + i * 0.22);
      canvas.drawLine(
        Offset(x, size.height * 0.06),
        Offset(x, size.height * 0.10),
        meridian,
      );
    }

    _drawCrystalSpeck(canvas, Offset(size.width * 0.86, size.height * 0.14));
    _drawCrystalSpeck(canvas, Offset(size.width * 0.11, size.height * 0.82), dim: true);
    if (detail == HomeSurfaceDetail.rich) {
      _drawGoldMicroReflection(canvas, Offset(size.width * 0.72, size.height * 0.22));
    }
  }

  void _drawCrystalSpeck(Canvas canvas, Offset center, {bool dim = false}) {
    canvas.drawCircle(
      center,
      0.55,
      Paint()
        ..color = AppColors.purpleLight.withValues(alpha: dim ? 0.06 : 0.10),
    );
  }

  void _drawGoldMicroReflection(Canvas canvas, Offset center) {
    canvas.drawCircle(
      center,
      0.35,
      Paint()..color = AppColors.goldLight.withValues(alpha: 0.12),
    );
  }

  @override
  bool shouldRepaint(covariant _HomeEngravedSurfacePainter oldDelegate) =>
      oldDelegate.detail != detail;
}

/// Chamber architecture painted into the cosmic background — not on panels.
class HomeChamberArchitecturePainter extends CustomPainter {
  const HomeChamberArchitecturePainter({this.lightPhase = 0.5});

  final double lightPhase;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final meridianAlpha = 0.035 + lightPhase * 0.012;
    final meridian = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4
      ..color = AppColors.gold.withValues(alpha: meridianAlpha);

    final arch = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.35
      ..color = AppColors.purpleLight.withValues(alpha: 0.04);

    canvas.drawLine(Offset(w * 0.12, h * 0.18), Offset(w * 0.12, h * 0.88), meridian);
    canvas.drawLine(Offset(w * 0.88, h * 0.18), Offset(w * 0.88, h * 0.88), meridian);

    final archPath = Path()
      ..moveTo(w * 0.12, h * 0.32)
      ..quadraticBezierTo(w * 0.5, h * 0.24, w * 0.88, h * 0.32);
    canvas.drawPath(archPath, arch);

    canvas.drawLine(Offset(0, h * 0.92), Offset(w, h * 0.92), meridian);

    for (var i = 0; i < 6; i++) {
      final t = i / 5;
      final x = w * (0.18 + t * 0.64);
      canvas.drawLine(
        Offset(x, h * 0.905),
        Offset(x + 4, h * 0.915),
        Paint()
          ..color = AppColors.gold.withValues(alpha: 0.03)
          ..strokeWidth = 0.3,
      );
    }

    final orbWell = Offset(w * 0.5, h * 0.26);
    canvas.drawCircle(
      orbWell,
      w * 0.22,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.35
        ..color = AppColors.purple.withValues(alpha: 0.045),
    );
  }

  @override
  bool shouldRepaint(covariant HomeChamberArchitecturePainter oldDelegate) =>
      oldDelegate.lightPhase != lightPhase;
}

/// Soft floor plane where panels meet the chamber ground.
class HomeChamberFloorGradient extends StatelessWidget {
  const HomeChamberFloorGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: HomeAtmosphere.lowerChamberCalm,
      ),
      child: const SizedBox.expand(),
    );
  }
}

/// Vertical light shaft from the hero orb into the scroll chamber.
class HomeOrbSpillColumn extends StatelessWidget {
  const HomeOrbSpillColumn({
    super.key,
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              HomeAtmosphere.mysteryViolet.withValues(alpha: 0.09),
              HomeAtmosphere.wisdomGold.withValues(alpha: 0.025),
              AppColors.transparent,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Subtle ambient shimmer on the chamber background (tertiary motion).
class HomeChamberShimmerPainter extends CustomPainter {
  const HomeChamberShimmerPainter({
    required this.phase,
    this.layerOpacity = 1,
  });

  final double phase;
  final double layerOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final drift = sin(phase * pi * 2) * 0.012;

    canvas.drawCircle(
      Offset(w * (0.5 + drift), h * 0.27),
      w * 0.18,
      Paint()
        ..color = AppColors.goldLight.withValues(alpha: 0.025 * layerOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48),
    );
  }

  @override
  bool shouldRepaint(covariant HomeChamberShimmerPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.layerOpacity != layerOpacity;
}
