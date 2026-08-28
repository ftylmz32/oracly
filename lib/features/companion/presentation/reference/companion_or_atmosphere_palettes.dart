/// Personality and presence palettes for OR glow.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../premium/models/personalization_models.dart';
import 'companion_or_living_tokens.dart';
import 'companion_or_presence.dart';

class OrModePalette {
  const OrModePalette({
    required this.glow,
    required this.core,
    required this.edge,
    required this.wash,
    required this.blur,
    required this.spread,
    required this.showDust,
  });

  final Color glow;
  final Color core;
  final Color edge;
  final double wash;
  final double blur;
  final double spread;
  final bool showDust;

  static OrModePalette of(AiPersonality personality) => switch (personality) {
        AiPersonality.gentle => const OrModePalette(
            glow: Color(0xFF9A8898),
            core: Color(0xFF2A2434),
            edge: Color(0xC8C4B59A),
            wash: 0.052,
            blur: 9,
            spread: 0.45,
            showDust: false,
          ),
        AiPersonality.mystical => OrModePalette(
            glow: OraclyChrome.violet,
            core: OraclyChrome.midnight,
            edge: OraclyChrome.violetSoft.withValues(alpha: 0.58),
            wash: 0.062,
            blur: 11,
            spread: 0.65,
            showDust: true,
          ),
        AiPersonality.poetic => OrModePalette(
            glow: OraclyChrome.gold,
            core: OraclyChrome.violet.withValues(alpha: 0.62),
            edge: OraclyChrome.gold.withValues(alpha: 0.62),
            wash: 0.068,
            blur: 12,
            spread: 0.85,
            showDust: true,
          ),
        AiPersonality.direct => const OrModePalette(
            glow: Color(0xFFD9C7A3),
            core: Color(0xFF16141C),
            edge: Color(0xE6E4D5C0),
            wash: 0.038,
            blur: 6,
            spread: 0.18,
            showDust: false,
          ),
      };
}

class OrStatePalette {
  const OrStatePalette({
    required this.breath,
    required this.glowMin,
    required this.glowSpan,
    this.washMul = 1,
    this.blurMul = 1,
    this.spreadMul = 1,
    this.tint = const Color(0x00000000),
    this.tintMix = 0,
    this.edge = const Color(0x00000000),
    this.edgeMix = 0,
  });

  final Duration breath;
  final double glowMin;
  final double glowSpan;
  final double washMul;
  final double blurMul;
  final double spreadMul;
  final Color tint;
  final double tintMix;
  final Color edge;
  final double edgeMix;

  static OrStatePalette of(CompanionOrPresence presence) => switch (presence) {
        CompanionOrPresence.idle => const OrStatePalette(
            breath: CompanionOrLivingTokens.idleBreath,
            glowMin: CompanionOrLivingTokens.idleGlowMin,
            glowSpan: CompanionOrLivingTokens.idleGlowSpan,
          ),
        CompanionOrPresence.thinking => const OrStatePalette(
            breath: CompanionOrLivingTokens.thinkingOrbit,
            glowMin: CompanionOrLivingTokens.thinkingGlowMin,
            glowSpan: CompanionOrLivingTokens.thinkingGlowSpan,
            washMul: 1.1,
            blurMul: 1.06,
            spreadMul: 1.04,
          ),
        CompanionOrPresence.speaking => const OrStatePalette(
            breath: CompanionOrLivingTokens.speakingPulse,
            glowMin: CompanionOrLivingTokens.speakingGlowMin,
            glowSpan: CompanionOrLivingTokens.speakingGlowSpan,
            washMul: 1.12,
            blurMul: 1.05,
            spreadMul: 1.04,
          ),
        // Error: return to idle look — never red flash.
        CompanionOrPresence.error => const OrStatePalette(
            breath: CompanionOrLivingTokens.idleBreath,
            glowMin: CompanionOrLivingTokens.idleGlowMin,
            glowSpan: CompanionOrLivingTokens.idleGlowSpan,
          ),
      };
}
