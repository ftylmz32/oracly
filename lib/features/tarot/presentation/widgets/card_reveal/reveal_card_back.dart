/// Premium mystical tarot card back for cinematic reveal — no giant glow.
library;

import 'package:flutter/material.dart';

import '../../../art/tarot_card_back_art.dart';
import '../../../theme/tarot_tokens.dart';
import '../deck/physical_card_thickness.dart';
import '../deck/tarot_printed_material.dart';

class RevealPremiumCardBack extends StatelessWidget {
  const RevealPremiumCardBack({
    super.key,
    required this.width,
    required this.height,
    this.elevation = 0.85,
    this.particlePhase = 0,
    this.lightBiasX = 0,
    this.lightBiasY = 0,
  });

  final double width;
  final double height;
  final double elevation;
  final double particlePhase;
  final double lightBiasX;
  final double lightBiasY;

  @override
  Widget build(BuildContext context) {
    final radius = TarotTokens.cardCornerRadius;
    final lift = elevation.clamp(0.0, 1.0);
    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: tarotContactShadow(elevation: lift, goldWhisper: 0.35),
          border: Border.all(
            color: const Color(0xFF9A7420).withValues(alpha: 0.55),
            width: 1.05,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 0.5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              TarotCardBackArt(lightBiasX: lightBiasX, lightBiasY: lightBiasY),
              PhysicalCardThickness(elevation: lift),
              TarotPrintedMaterial(
                lightBiasX: lightBiasX,
                lightBiasY: lightBiasY,
                foil: 0.7,
                matte: 0.65,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
