/// OR-405 / OR-406 / OR-407 — ORACLY Design DNA (Tarot Home visual language).
library;

import 'dart:math' show pi, sin;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/design_system/app_layout.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/oracly_brand_signature.dart';
import '../../../../../core/widgets/oracly_signature_motifs.dart';

export '../../../../../shared/widgets/oracly_pressable.dart'
    show OraclyPressable, OraclyTouchFeedback;
export '../../../../../core/widgets/oracly_signature_motifs.dart'
    show
        OraclySignatureCelestialArc,
        OraclySignatureCornerOrnaments,
        OraclySignatureDivider,
        OraclySignatureFacetSheen,
        OraclySignatureMicroFrame;

typedef OraclySacredDivider = OraclySignatureDivider;
typedef OraclySacredCornerOrnaments = OraclySignatureCornerOrnaments;

/// Canonical ORACLY material and light tokens — delegates to brand signature.
abstract final class OraclySacredPalette {
  OraclySacredPalette._();

  static const obsidian = OraclySignaturePalette.obsidian;
  static const deepViolet = OraclySignaturePalette.deepViolet;
  static const royalPurple = OraclySignaturePalette.royalPurple;
  static const crystalVeil = OraclySignaturePalette.crystalVeil;

  static const champagne = OraclySignaturePalette.champagne;
  static const champagneDeep = OraclySignaturePalette.champagneDeep;
  static const champagneShadow = OraclySignaturePalette.champagneShadow;

  static const purpleEnergy = OraclySignaturePalette.purpleEnergy;
  static const purpleEnergySoft = OraclySignaturePalette.purpleEnergySoft;

  static Color goldEngrave([double alpha = OraclySignatureMaterials.goldEngrave]) =>
      OraclySignaturePalette.goldEngrave(alpha);

  static Color goldHairline([double alpha = OraclySignatureMaterials.goldHairline]) =>
      OraclySignaturePalette.goldHairline(alpha);
}

/// Light distance from the Hero Orb — subtle warmth, never competing.
enum OraclyLightTier {
  orbAdjacent,
  upperChamber,
  midChamber,
  lowerChamber,
}

extension OraclyLightTierX on OraclyLightTier {
  double get warmth {
    return switch (this) {
      OraclyLightTier.orbAdjacent => 0.10,
      OraclyLightTier.upperChamber => 0.07,
      OraclyLightTier.midChamber => 0.035,
      OraclyLightTier.lowerChamber => 0.008,
    };
  }

  double get purpleAmbience {
    return switch (this) {
      OraclyLightTier.orbAdjacent => 0.03,
      OraclyLightTier.upperChamber => 0.04,
      OraclyLightTier.midChamber => 0.06,
      OraclyLightTier.lowerChamber => 0.08,
    };
  }
}

/// Applies orb-connected lighting without moving child layout.
class OraclyLightFalloff extends StatelessWidget {
  const OraclyLightFalloff({
    super.key,
    required this.tier,
    required this.child,
  });

  final OraclyLightTier tier;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.88),
                  radius: 2.0,
                  colors: [
                    OraclySacredPalette.champagne
                        .withValues(alpha: tier.warmth * 1.05),
                    OraclySacredPalette.purpleEnergySoft
                        .withValues(alpha: tier.purpleAmbience * 0.55),
                    OraclySacredPalette.purpleEnergy
                        .withValues(alpha: tier.purpleAmbience * 0.42),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.22, 0.48, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Crystal facet refraction + inner shimmer (shared across panels).
class OraclyCrystalFacetPainter extends CustomPainter {
  const OraclyCrystalFacetPainter({this.intensity = 1.0});

  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final facet = Paint()
      ..strokeWidth = 0.35
      ..style = PaintingStyle.stroke
      ..color = OraclySacredPalette.champagne.withValues(
        alpha: OraclySignatureMotifs.crystalFacetAlpha * intensity,
      );
    canvas.drawLine(
      Offset(0, size.height * 0.16),
      Offset(size.width * 0.34, 0),
      facet,
    );
    canvas.drawLine(
      Offset(size.width, size.height * 0.20),
      Offset(size.width * 0.64, 0),
      facet,
    );

    final shimmer = Paint()
      ..shader = OraclySignatureReflection.facetSheen(intensity: intensity)
          .createShader(Rect.fromLTWH(0, 0, size.width * 0.55, size.height * 0.48));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.48), shimmer);
  }

  @override
  bool shouldRepaint(covariant OraclyCrystalFacetPainter old) =>
      old.intensity != intensity;
}

/// Tiny constellation fragments — OL-5 inspired.
class OraclyConstellationFragmentPainter extends CustomPainter {
  const OraclyConstellationFragmentPainter({
    this.alpha = OraclySignatureMaterials.constellationAlpha,
  });

  final double alpha;

  static const _clusters = <(double x, double y, List<Offset> nodes)>[
    (0.14, 0.22, [Offset(0, 0), Offset(8, 4), Offset(14, -2)]),
    (0.86, 0.18, [Offset(0, 0), Offset(-10, 5), Offset(-6, -4)]),
    (0.82, 0.78, [Offset(0, 0), Offset(-8, -3), Offset(-14, 2)]),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..strokeWidth = 0.3
      ..color = OraclySacredPalette.goldHairline(alpha * 0.85);
    final star = Paint()..color = OraclySacredPalette.champagne.withValues(alpha: alpha);

    for (final (x, y, nodes) in _clusters) {
      final origin = Offset(size.width * x, size.height * y);
      for (var i = 0; i < nodes.length - 1; i++) {
        canvas.drawLine(origin + nodes[i], origin + nodes[i + 1], line);
      }
      for (final n in nodes) {
        canvas.drawCircle(origin + n, 0.7, star);
      }
    }
  }

  @override
  bool shouldRepaint(covariant OraclyConstellationFragmentPainter old) =>
      old.alpha != alpha;
}

/// Top champagne specular highlight bar.
class OraclyChampagneSpecular extends StatelessWidget {
  const OraclyChampagneSpecular({
    super.key,
    this.intensity = 1.0,
    this.horizontalInset = AppSpacing.lg,
    this.topOffset = 0,
  });

  final double intensity;
  final double horizontalInset;
  final double topOffset;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topOffset,
      left: horizontalInset,
      right: horizontalInset,
      child: IgnorePointer(
        child: Container(
          height: 0.8,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                OraclySacredPalette.champagne.withValues(alpha: 0.22 * intensity),
                OraclySacredPalette.champagneDeep.withValues(alpha: 0.12 * intensity),
                Colors.transparent,
              ],
              stops: const [0.0, 0.38, 0.62, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared obsidian crystal body gradient layers.
class OraclyCrystalBodyLayers extends StatelessWidget {
  const OraclyCrystalBodyLayers({
    super.key,
    required this.lightTier,
    this.borderRadius,
    this.discoveryRichness = 1.0,
  });

  final OraclyLightTier lightTier;
  final BorderRadius? borderRadius;
  final double discoveryRichness;

  @override
  Widget build(BuildContext context) {
    final warm = lightTier.warmth * (0.88 + discoveryRichness * 0.12);
    final detail = 0.85 + discoveryRichness * 0.15;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                OraclySacredPalette.royalPurple.withValues(alpha: 0.97),
                OraclySacredPalette.deepViolet.withValues(alpha: 0.96),
                OraclySacredPalette.obsidian.withValues(alpha: 0.95),
              ],
              stops: const [0.0, 0.48, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: RadialGradient(
              center: const Alignment(0, -0.28),
              radius: 1.35,
              colors: [
                OraclySacredPalette.purpleEnergy.withValues(
                  alpha: 0.06 + lightTier.purpleAmbience * 0.65,
                ),
                Colors.transparent,
                OraclySacredPalette.obsidian.withValues(alpha: 0.22),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: RadialGradient(
              center: const Alignment(0, -0.75),
              radius: 1.2,
              colors: [
                OraclySacredPalette.champagne.withValues(alpha: warm * 0.85),
                Colors.transparent,
              ],
              stops: const [0.0, 0.68],
            ),
          ),
        ),
        CustomPaint(painter: OraclyCrystalFacetPainter(intensity: (0.55 + warm * 0.4) * detail)),
        CustomPaint(
          painter: OraclyConstellationFragmentPainter(
            alpha: (0.06 + warm * 0.15) * detail,
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                OraclySacredPalette.obsidian.withValues(alpha: 0.24),
              ],
              stops: const [0.62, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

/// Standard ORACLY crystal border — champagne outer hairline + engraved inner.
BoxDecoration oraclyCrystalBorderDecoration({
  required BorderRadius radius,
  double goldAlpha = 0.22,
}) {
  return BoxDecoration(
    borderRadius: radius,
    border: Border.all(
      color: OraclySacredPalette.goldEngrave(goldAlpha),
      width: AppBorderWidth.hairline + 0.25,
    ),
    boxShadow: [
      BoxShadow(
        color: OraclySacredPalette.champagneShadow.withValues(alpha: goldAlpha * 0.35),
        blurRadius: 0,
        spreadRadius: -0.5,
        offset: const Offset(0, 0.5),
      ),
    ],
  );
}

/// Decorative stars used consistently across tiles.
class OraclySacredStarsPainter extends CustomPainter {
  const OraclySacredStarsPainter({this.alpha = 0.10});

  final double alpha;

  static const _stars = <(double x, double y, double r)>[
    (0.12, 0.18, 0.7),
    (0.88, 0.14, 0.5),
    (0.92, 0.72, 0.55),
    (0.08, 0.82, 0.45),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (x, y, r) in _stars) {
      canvas.drawCircle(
        Offset(size.width * x, size.height * y),
        r,
        Paint()..color = OraclySacredPalette.champagne.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant OraclySacredStarsPainter old) =>
      old.alpha != alpha;
}

/// Almost invisible ambient dust — slow drift via [phase].
class OraclySacredDustPainter extends CustomPainter {
  const OraclySacredDustPainter({required this.phase, this.alpha = 0.07});

  final double phase;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final dust = Paint()..color = OraclySacredPalette.champagne.withValues(alpha: alpha);
    for (var i = 0; i < 8; i++) {
      final t = (phase + i * 0.17) % 1.0;
      final x = size.width * (0.10 + (i * 0.09) % 0.80);
      final y = size.height * (0.14 + sin(t * pi * 2 + i) * 0.03 + (i % 4) * 0.16);
      canvas.drawCircle(Offset(x, y), 0.5 + (i % 2) * 0.1, dust);
    }
  }

  @override
  bool shouldRepaint(covariant OraclySacredDustPainter old) =>
      old.phase != phase || old.alpha != alpha;
}

/// Shared motion tokens — slow, elegant, confident.
abstract final class OraclyMotion {
  OraclyMotion._();

  static const curve = OraclySignatureMotion.curve;

  static const press = OraclySignatureMotion.press;
  static const breath = OraclySignatureMotion.breath;
  static const ambient = OraclySignatureMotion.ambient;
  static const ambientDrift = OraclySignatureMaterials.ambientDuration;
  static const orbBreath = Duration(seconds: 14);
  static const entrance = Duration(milliseconds: 1200);

  static const pressScale = OraclySignatureMotion.pressScale;
  static const pressScaleCrystal = OraclySignatureMotion.pressScale;
  static const pressOpacity = OraclySignatureMotion.pressOpacity;
  static const pressRelease = OraclySignatureMotion.pressRelease;
  static const releaseCurve = OraclySignatureMotion.releaseCurve;
  static const entranceSlide = 0.018;
  static const entranceScaleBegin = 0.98;

  static const staggerHero = Duration.zero;
  static const staggerSpreads = Duration(milliseconds: 200);
  static const staggerRecent = Duration(milliseconds: 380);
  static const staggerDaily = Duration(milliseconds: 540);
  static const staggerPremium = Duration(milliseconds: 700);
}

/// Back-compat alias — prefer [OraclyMotion].
typedef OraclySilentMotion = OraclyMotion;

/// OR-407 — Physical material language: obsidian, crystal glass, champagne.
abstract final class OraclyMaterials {
  OraclyMaterials._();

  static const blurChamber = OraclySignatureMaterials.blurGlass;
  static const blurPanel = OraclySignatureMaterials.blurChamber;
  static const blurTile = OraclySignatureMaterials.blurTile;
  static const blurNebula = OraclySignatureMaterials.blurNebula;
  static const blurOrbFloor = 40.0;

  static const goldBorderPanel = OraclySignatureMaterials.goldBorder;
  static const goldBorderChamber = 0.17;
  static const goldBorderTile = 0.14;
  static const innerPurpleHairline = OraclySignatureMaterials.innerPurpleHairline;

  static List<BoxShadow> chamberShadows() => [
        BoxShadow(
          color: OraclySacredPalette.obsidian.withValues(alpha: 0.52),
          blurRadius: 22,
          offset: const Offset(0, 10),
          spreadRadius: -10,
        ),
        BoxShadow(
          color: OraclySacredPalette.obsidian.withValues(alpha: 0.28),
          blurRadius: 8,
          offset: const Offset(0, 3),
          spreadRadius: -2,
        ),
      ];

  static List<BoxShadow> panelShadows() => [
        BoxShadow(
          color: OraclySacredPalette.obsidian.withValues(alpha: 0.62),
          blurRadius: 28,
          offset: const Offset(0, 14),
          spreadRadius: -8,
        ),
        BoxShadow(
          color: OraclySacredPalette.obsidian.withValues(alpha: 0.32),
          blurRadius: 10,
          offset: const Offset(0, 4),
          spreadRadius: -3,
        ),
      ];

  static List<BoxShadow> tileShadows({
    bool selected = false,
    double breathPhase = 0,
    Color? accent,
  }) {
    return [
      BoxShadow(
        color: OraclySacredPalette.obsidian.withValues(alpha: 0.48),
        blurRadius: 14,
        offset: const Offset(0, 6),
        spreadRadius: -4,
      ),
      BoxShadow(
        color: OraclySacredPalette.obsidian.withValues(alpha: 0.22),
        blurRadius: 4,
        offset: const Offset(0, 2),
        spreadRadius: -1,
      ),
      if (selected)
        BoxShadow(
          color: (accent ?? OraclySacredPalette.purpleEnergy)
              .withValues(alpha: 0.10 + breathPhase * 0.05),
          blurRadius: 16,
          spreadRadius: -2,
        ),
    ];
  }

  static double specularIntensity(OraclyLightTier tier, {double boost = 0}) =>
      OraclySignatureMaterials.specularIntensity + tier.warmth + boost;

  static double starsAlpha(OraclyLightTier tier, {bool panel = false}) =>
      OraclySignatureMaterials.particleAlpha +
      tier.warmth * (panel ? 0.08 : 0.06);
}

/// OR-407 / OR-410 — Decorative spacing rhythm — gallery calm, never crowded.
abstract final class OraclyRhythm {
  OraclyRhythm._();

  /// Silence between narrative bridges and chambers.
  static const bridgeVertical = AppSpacing.xl;

  /// Standard breath between major focus areas.
  static const breathGap = AppSpacing.xl + AppSpacing.sm;

  /// Lighter breath after a bridge transition.
  static const breathGapAfterBridge = AppSpacing.xl;

  /// Space below section headings before content.
  static const sectionTitleGap = AppLayout.labelToContent;

  /// Heading block to first content element.
  static const sectionContentGap = AppLayout.sectionGapMedium;

  /// Spread ritual grid — panels never touch visually.
  static const spreadGridGap = AppSpacing.xxl;
  static const spreadColumnGap = AppSpacing.xl;

  /// Hero chamber — orb dominates, title breathes below.
  static const heroOrbToTitle = AppSpacing.xl + AppSpacing.sm;
  static const heroTitleToSubtitle = AppSpacing.lg;
  static const heroSubtitleInset = AppSpacing.xl + AppSpacing.lg;

  /// Screen edge calm.
  static const screenTop = AppLayout.screenTop;
  static const screenBottom = AppLayout.screenBottom;

  /// Crystal panel interior gallery padding.
  static const panelInsetHorizontal = AppSpacing.xl + AppSpacing.sm;
  static const panelInsetTop = AppSpacing.xl + AppSpacing.lg;
  static const panelInsetBottom = AppSpacing.xl + AppSpacing.lg;

  /// Section shell interior.
  static const chamberInset = AppSpacing.xl;

  /// Carousel tile interior.
  static const tileInset = AppSpacing.insetCard + AppSpacing.md;

  /// Ritual tile interior.
  static const spreadCardInsetH = AppSpacing.lg;
  static const spreadCardInsetTop = AppSpacing.xl;
  static const spreadCardInsetBottom = AppSpacing.xl;

  /// Horizontal carousel separation.
  static const carouselGap = AppSpacing.xl;

  /// Premium CTA breathing.
  static const premiumDividerGap = AppSpacing.lg;
  static const premiumButtonInset = AppSpacing.xl + AppSpacing.sm;

  /// Button vertical clearance inside shells.
  static const buttonVerticalClearance = AppSpacing.sm;
}

/// OR-407 — Engraved typography — gold engraving studio style.
abstract final class OraclyTypography {
  OraclyTypography._();

  static Shader heroTitleShader(Rect bounds) =>
      OraclySignatureTypography.heroTitleShader(bounds);

  static TextStyle sectionLabel({double fontSize = 12}) =>
      OraclySignatureTypography.sectionLabel(fontSize: fontSize);

  static TextStyle tileTitle({double fontSize = 14.5}) =>
      OraclySignatureTypography.tileTitle(fontSize: fontSize);

  static TextStyle bodyWhisper({
    double fontSize = 14,
    double alpha = 0.68,
  }) =>
      OraclySignatureTypography.whisperBody(fontSize: fontSize, alpha: alpha);

  static TextStyle captionWhisper({double alpha = 0.68}) => TextStyle(
        color: AppColors.textSecondary.withValues(alpha: alpha),
        height: 1.72,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.28,
      );
}

/// Crystal surface scale — chamber, panel, or ritual tile.
enum OraclyCrystalFrameKind { chamber, panel, tile }

/// Unified crystal glass frame — one studio, every premium surface.
class OraclyCrystalFrame extends StatelessWidget {
  const OraclyCrystalFrame({
    super.key,
    required this.child,
    required this.radius,
    required this.lightTier,
    this.kind = OraclyCrystalFrameKind.chamber,
    this.padding,
    this.showOrnaments = true,
    this.showStars = false,
    this.specularBoost = 0,
  });

  final Widget child;
  final BorderRadius radius;
  final OraclyLightTier lightTier;
  final OraclyCrystalFrameKind kind;
  final EdgeInsetsGeometry? padding;
  final bool showOrnaments;
  final bool showStars;
  final double specularBoost;

  double get _blur => switch (kind) {
        OraclyCrystalFrameKind.panel => OraclyMaterials.blurPanel,
        OraclyCrystalFrameKind.chamber => OraclyMaterials.blurChamber,
        OraclyCrystalFrameKind.tile => OraclyMaterials.blurTile,
      };

  double get _goldAlpha => switch (kind) {
        OraclyCrystalFrameKind.panel => OraclyMaterials.goldBorderPanel,
        OraclyCrystalFrameKind.chamber => OraclyMaterials.goldBorderChamber,
        OraclyCrystalFrameKind.tile => OraclyMaterials.goldBorderTile,
      };

  List<BoxShadow> get _shadows => switch (kind) {
        OraclyCrystalFrameKind.panel => OraclyMaterials.panelShadows(),
        OraclyCrystalFrameKind.chamber => OraclyMaterials.chamberShadows(),
        OraclyCrystalFrameKind.tile => OraclyMaterials.chamberShadows(),
      };

  double get _specularInset => kind == OraclyCrystalFrameKind.panel
      ? AppSpacing.xl
      : AppSpacing.lg;

  EdgeInsetsGeometry get _defaultPadding => switch (kind) {
        OraclyCrystalFrameKind.panel => EdgeInsets.fromLTRB(
              OraclyRhythm.panelInsetHorizontal,
              OraclyRhythm.panelInsetTop,
              OraclyRhythm.panelInsetHorizontal,
              OraclyRhythm.panelInsetBottom,
            ),
        OraclyCrystalFrameKind.chamber =>
            EdgeInsets.all(OraclyRhythm.chamberInset),
        OraclyCrystalFrameKind.tile =>
            EdgeInsets.all(OraclyRhythm.tileInset),
      };

  @override
  Widget build(BuildContext context) {
    final showPanelStars = showStars || kind == OraclyCrystalFrameKind.panel;
    final discovery = TarotHomeDiscoveryScope.maybeOf(context);
    final richness = discovery?.richness ?? 1.0;
    final goldAlpha = _goldAlpha * (0.82 + richness * 0.18);
    final specular = OraclyMaterials.specularIntensity(
      lightTier,
      boost: specularBoost,
    ) * (0.85 + richness * 0.15);
    final starsAlpha = OraclyMaterials.starsAlpha(
      lightTier,
      panel: kind == OraclyCrystalFrameKind.panel,
    ) * (0.75 + richness * 0.25);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: _shadows,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: OraclyCrystalBodyLayers(
                lightTier: lightTier,
                borderRadius: radius,
                discoveryRichness: richness,
              ),
            ),
            if (showPanelStars)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: OraclySacredStarsPainter(
                      alpha: starsAlpha,
                    ),
                  ),
                ),
              ),
            OraclyChampagneSpecular(
              intensity: specular,
              horizontalInset: _specularInset,
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
              child: DecoratedBox(
                decoration: oraclyCrystalBorderDecoration(
                  radius: radius,
                  goldAlpha: goldAlpha,
                ),
                child: kind == OraclyCrystalFrameKind.panel
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          border: Border.all(
                            color: OraclySacredPalette.purpleEnergySoft
                                .withValues(alpha: OraclyMaterials.innerPurpleHairline),
                            width: AppBorderWidth.hairline,
                          ),
                        ),
                        child: Padding(
                          padding: padding ?? _defaultPadding,
                          child: child,
                        ),
                      )
                    : Padding(
                        padding: padding ?? _defaultPadding,
                        child: child,
                      ),
              ),
            ),
            if (showOrnaments) const OraclySacredCornerOrnaments(),
          ],
        ),
      ),
    );
  }
}

/// OR-407 entry point — canonical design language for Tarot Home.
///
/// Use [OraclySacredPalette], [OraclyMaterials], [OraclyRhythm],
/// [OraclyMotion], [OraclyTypography], and [OraclyCrystalFrame].
abstract final class OraclyDesignDna {
  OraclyDesignDna._();
}

/// OR-409 — Propagates scroll discovery richness to crystal surfaces.
class TarotHomeDiscoveryScope extends InheritedWidget {
  const TarotHomeDiscoveryScope({
    super.key,
    required this.revealProgress,
    required this.richness,
    required this.focusWeight,
    required super.child,
  });

  final double revealProgress;
  final double richness;
  final double focusWeight;

  static TarotHomeDiscoveryScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TarotHomeDiscoveryScope>();
  }

  @override
  bool updateShouldNotify(covariant TarotHomeDiscoveryScope oldWidget) {
    return oldWidget.revealProgress != revealProgress ||
        oldWidget.richness != richness ||
        oldWidget.focusWeight != focusWeight;
  }
}
