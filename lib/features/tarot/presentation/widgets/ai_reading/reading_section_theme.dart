/// OR-301+ — Per-section visual identity for premium reading cards.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/oracly_brand_signature.dart';

enum ReadingSectionKind {
  general,
  love,
  career,
  money,
  spiritual,
  hidden,
  warning,
  lucky,
}

@immutable
class ReadingSectionTheme {
  const ReadingSectionTheme({
    required this.kind,
    required this.icon,
    required this.glowColor,
    required this.gradientColors,
    required this.borderColor,
    required this.iconGlow,
    required this.accentColor,
    this.particleKind = ReadingParticleKind.dust,
    this.metallicSheen = false,
  });

  final ReadingSectionKind kind;
  final IconData icon;
  final Color glowColor;
  final List<Color> gradientColors;
  final Color borderColor;
  final Color iconGlow;
  final Color accentColor;
  final ReadingParticleKind particleKind;
  final bool metallicSheen;

  static ReadingSectionTheme forKind(ReadingSectionKind kind) {
    return switch (kind) {
      ReadingSectionKind.general => ReadingSectionTheme(
          kind: ReadingSectionKind.general,
          icon: Icons.auto_awesome_rounded,
          glowColor: OraclySignaturePalette.purpleGlow(0.25),
          gradientColors: OraclySignatureReading.generalGradient,
          borderColor: OraclySignatureReading.generalBorder,
          iconGlow: OraclySignaturePalette.champagneDeep,
          accentColor: OraclySignatureReading.generalAccent,
          particleKind: ReadingParticleKind.dust,
        ),
      ReadingSectionKind.love => const ReadingSectionTheme(
          kind: ReadingSectionKind.love,
          icon: Icons.favorite_rounded,
          glowColor: Color(0x55E879A8),
          gradientColors: [
            Color(0x66381828),
            Color(0xCC120C14),
            Color(0x55281020),
          ],
          borderColor: Color(0x55F0A0C0),
          iconGlow: Color(0xFFFF8FB8),
          accentColor: Color(0xFFFFB4D0),
          particleKind: ReadingParticleKind.hearts,
        ),
      ReadingSectionKind.career => const ReadingSectionTheme(
          kind: ReadingSectionKind.career,
          icon: Icons.work_outline_rounded,
          glowColor: Color(0x55D4AF37),
          gradientColors: [
            Color(0x66382810),
            Color(0xCC141010),
            Color(0x55281808),
          ],
          borderColor: Color(0x66E8C860),
          iconGlow: Color(0xFFF0D77A),
          accentColor: Color(0xFFE8C860),
          particleKind: ReadingParticleKind.dust,
          metallicSheen: true,
        ),
      ReadingSectionKind.money => const ReadingSectionTheme(
          kind: ReadingSectionKind.money,
          icon: Icons.payments_outlined,
          glowColor: Color(0x55F5A623),
          gradientColors: [
            Color(0x66402808),
            Color(0xCC100E08),
            Color(0x55382006),
          ],
          borderColor: Color(0x66FFB830),
          iconGlow: Color(0xFFFFC850),
          accentColor: Color(0xFFFFD060),
          particleKind: ReadingParticleKind.dust,
        ),
      ReadingSectionKind.spiritual => ReadingSectionTheme(
          kind: ReadingSectionKind.spiritual,
          icon: Icons.self_improvement_rounded,
          glowColor: OraclySignaturePalette.purpleGlow(0.33),
          gradientColors: OraclySignatureReading.spiritualGradient,
          borderColor: OraclySignaturePalette.purpleEnergy.withValues(alpha: 0.33),
          iconGlow: OraclySignaturePalette.purpleEnergy,
          accentColor: OraclySignaturePalette.champagne,
          particleKind: ReadingParticleKind.sparkles,
        ),
      ReadingSectionKind.hidden => const ReadingSectionTheme(
          kind: ReadingSectionKind.hidden,
          icon: Icons.nightlight_round,
          glowColor: Color(0x556B7FD7),
          gradientColors: [
            Color(0x66101838),
            Color(0xCC080818),
            Color(0x55081028),
          ],
          borderColor: Color(0x557B8FD0),
          iconGlow: Color(0xFF9BB0FF),
          accentColor: Color(0xFFB0C4FF),
          particleKind: ReadingParticleKind.dust,
        ),
      ReadingSectionKind.warning => const ReadingSectionTheme(
          kind: ReadingSectionKind.warning,
          icon: Icons.shield_outlined,
          glowColor: Color(0x44E07050),
          gradientColors: [
            Color(0x55301818),
            Color(0xCC100C0C),
            Color(0x44201010),
          ],
          borderColor: Color(0x55D08060),
          iconGlow: Color(0xFFE89070),
          accentColor: Color(0xFFFFA080),
          particleKind: ReadingParticleKind.dust,
        ),
      ReadingSectionKind.lucky => const ReadingSectionTheme(
          kind: ReadingSectionKind.lucky,
          icon: Icons.star_rounded,
          glowColor: Color(0x55FFD060),
          gradientColors: [
            Color(0x66402818),
            Color(0xCC100E10),
            Color(0x55301828),
          ],
          borderColor: Color(0x66FFD060),
          iconGlow: Color(0xFFFFE080),
          accentColor: Color(0xFFFFE8A0),
          particleKind: ReadingParticleKind.stars,
        ),
    };
  }
}

enum ReadingParticleKind { dust, hearts, sparkles, stars }
