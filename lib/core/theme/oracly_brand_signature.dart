/// OR-425 — ORACLY brand signature: recognizable without logo or title.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';

/// Canonical palette — one world, every screen.
abstract final class OraclySignaturePalette {
  OraclySignaturePalette._();

  static const obsidian = Color(0xFF050208);
  static const deepViolet = Color(0xFF0E0618);
  static const royalPurple = Color(0xFF150A24);
  static const crystalVeil = Color(0xFF221538);
  static const chamberMid = Color(0xFF0A0512);

  static const champagne = Color(0xFFE8CF82);
  static const champagneDeep = Color(0xFFC9A961);
  static const champagneShadow = Color(0xFF9A7848);

  static const purpleEnergy = Color(0xFF9B6DFF);
  static const purpleEnergySoft = Color(0xFF6E4A9E);
  static const purpleMist = Color(0xFF352058);

  static const calmObsidian = obsidian;
  static const wisdomGold = champagneDeep;
  static const hopefulWarm = Color(0xFF3D2A4A);
  static const coolMist = Color(0xFF120E1C);
  static const pureGlass = crystalVeil;

  static Color goldEngrave([double alpha = OraclySignatureMaterials.goldEngrave]) =>
      champagne.withValues(alpha: alpha);

  static Color goldHairline([double alpha = OraclySignatureMaterials.goldHairline]) =>
      champagneDeep.withValues(alpha: alpha);

  static Color purpleGlow([double alpha = 0.20]) =>
      purpleEnergy.withValues(alpha: alpha);
}

/// Physical materials — glass, gold, crystal speak one language.
abstract final class OraclySignatureMaterials {
  OraclySignatureMaterials._();

  static const blurTile = 14.0;
  static const blurGlass = 16.0;
  static const blurChamber = 20.0;
  static const blurNebula = 80.0;

  static const goldEngrave = 0.28;
  static const goldHairline = 0.16;
  static const goldBorder = 0.20;
  static const innerPurpleHairline = 0.05;

  static const specularIntensity = 0.42;
  static const particleAlpha = 0.06;
  static const constellationAlpha = 0.08;
  static const reflectionAlpha = 0.028;

  static const pressDuration = Duration(milliseconds: 220);
  static const pressReleaseDuration = Duration(milliseconds: 280);
  static const breathDuration = Duration(seconds: 8);
  static const ambientDuration = Duration(seconds: 64);
  static const curve = Curves.easeOutCubic;
  static const releaseCurve = Curves.easeOutQuart;
  static const pressScale = 0.982;
  static const pressOpacity = 0.96;
  static const pressDepth = 1.2;
}

/// Recurring OL motifs — subtle, intentional, never repetitive.
abstract final class OraclySignatureMotifs {
  OraclySignatureMotifs._();

  static const cornerMeridianAlpha = 0.30;
  static const cornerTriadAlpha = 0.16;
  static const anchorNodeAlpha = 0.32;
  static const vesicaAlpha = 0.26;
  static const vesicaTriadAlpha = 0.18;
  static const dividerLineAlpha = 0.16;
  static const crystalFacetAlpha = 0.05;
}

/// Chamber gradients — cosmic sanctuary backdrop everywhere.
abstract final class OraclySignatureChamber {
  OraclySignatureChamber._();

  static const BoxDecoration cosmic = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment(-0.3, -1),
      end: Alignment(0.4, 1.15),
      colors: [
        OraclySignaturePalette.royalPurple,
        OraclySignaturePalette.deepViolet,
        OraclySignaturePalette.chamberMid,
        OraclySignaturePalette.obsidian,
      ],
      stops: [0.0, 0.35, 0.72, 1.0],
    ),
  );

  static const BoxDecoration selection = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment(-0.2, -1),
      end: Alignment(0.3, 1.1),
      colors: [
        OraclySignaturePalette.deepViolet,
        OraclySignaturePalette.chamberMid,
        OraclySignaturePalette.obsidian,
      ],
      stops: [0.0, 0.55, 1.0],
    ),
  );

  static const BoxDecoration reveal = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment(-0.2, -1),
      end: Alignment(0.3, 1.1),
      colors: [
        OraclySignaturePalette.chamberMid,
        OraclySignaturePalette.obsidian,
        Color(0xFF020104),
      ],
      stops: [0.0, 0.55, 1.0],
    ),
  );

  static LinearGradient crystalBody({double richness = 1.0}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        OraclySignaturePalette.crystalVeil.withValues(alpha: 0.92 * richness),
        OraclySignaturePalette.deepViolet.withValues(alpha: 0.88 * richness),
        OraclySignaturePalette.obsidian.withValues(alpha: 0.94 * richness),
      ],
      stops: const [0.0, 0.48, 1.0],
    );
  }

  static BoxDecoration crystalBorder({
    required BorderRadius radius,
    double goldAlpha = OraclySignatureMaterials.goldBorder,
  }) {
    return BoxDecoration(
      borderRadius: radius,
      border: Border.all(
        color: OraclySignaturePalette.goldEngrave(goldAlpha),
        width: AppBorderWidth.hairline + 0.35,
      ),
    );
  }
}

/// Engraved typography — gallery calm, confident hierarchy.
abstract final class OraclySignatureTypography {
  OraclySignatureTypography._();

  static TextStyle sectionLabel({double fontSize = 12}) => TextStyle(
        color: OraclySignaturePalette.champagne.withValues(alpha: 0.78),
        fontWeight: FontWeight.w500,
        letterSpacing: 2.2,
        fontSize: fontSize,
        height: 1.35,
      );

  static TextStyle tileTitle({double fontSize = 14.5}) => TextStyle(
        color: OraclySignaturePalette.champagne.withValues(alpha: 0.90),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        fontSize: fontSize,
        height: 1.35,
      );

  static TextStyle whisperBody({
    double fontSize = 14,
    double alpha = 0.68,
  }) =>
      TextStyle(
        color: AppColors.textSecondary.withValues(alpha: alpha),
        height: 1.75,
        letterSpacing: 0.35,
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
      );

  static Shader heroTitleShader(Rect bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          OraclySignaturePalette.champagne.withValues(alpha: 0.95),
          OraclySignaturePalette.champagneDeep,
        ],
      ).createShader(bounds);
}

/// Shared motion philosophy — slow, elegant, confident.
abstract final class OraclySignatureMotion {
  OraclySignatureMotion._();

  static const curve = OraclySignatureMaterials.curve;
  static const releaseCurve = OraclySignatureMaterials.releaseCurve;
  static const press = OraclySignatureMaterials.pressDuration;
  static const pressRelease = OraclySignatureMaterials.pressReleaseDuration;
  static const breath = OraclySignatureMaterials.breathDuration;
  static const ambient = OraclySignatureMaterials.ambientDuration;
  static const pressScale = OraclySignatureMaterials.pressScale;
  static const pressOpacity = OraclySignatureMaterials.pressOpacity;
  static const pressDepth = OraclySignatureMaterials.pressDepth;
}

/// Crystal facet + specular reflection — signature surface detail.
abstract final class OraclySignatureReflection {
  OraclySignatureReflection._();

  static LinearGradient topSpecular({double intensity = 1.0}) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(
          alpha: OraclySignatureMaterials.reflectionAlpha * 4 * intensity,
        ),
        Colors.transparent,
      ],
    );
  }

  static LinearGradient facetSheen({double intensity = 1.0}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: const Alignment(0.3, 0.6),
      colors: [
        Colors.white.withValues(
          alpha: OraclySignatureMaterials.reflectionAlpha * intensity,
        ),
        Colors.transparent,
      ],
    );
  }
}

/// Reading surfaces inherit chamber DNA while keeping section identity.
abstract final class OraclySignatureReading {
  OraclySignatureReading._();

  static const generalGradient = [
    Color(0x66221538),
    Color(0xCC0E0618),
    Color(0x55150824),
  ];

  static const spiritualGradient = [
    Color(0x66281850),
    Color(0xCC0C0818),
    Color(0x55150824),
  ];

  static Color get generalBorder => OraclySignaturePalette.goldEngrave(0.33);
  static Color get generalAccent => OraclySignaturePalette.champagne;
}
