/// Canonical ritual card size + clip for Oracly card-back / face.
///
/// Phase 7B: physicality sourced from [TarotTokens] ritual card tokens.
/// Phase 7G.1: settled overview uses [TarotCardFaceDensity.compact].
library;

import "package:flutter/material.dart";

import "../../art/tarot_card_back_art.dart";
import "../../art/tarot_card_face_density.dart";
import "../../theme/tarot_tokens.dart";
import "../../widgets/tarot_card_shell.dart";

abstract final class RitualCardMetrics {
  RitualCardMetrics._();

  static const width = TarotTokens.ritualCardWidth;
  static const height = TarotTokens.ritualCardHeight;
  static const radius = TarotTokens.ritualCardRadius;

  /// Proportional corner radius for compact settled faces.
  static double compactRadius(double cardWidth) =>
      (cardWidth * 0.12).clamp(6.0, 12.0);
}

class RitualCardBack extends StatelessWidget {
  const RitualCardBack({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return TarotCardShell(
      width: width ?? RitualCardMetrics.width,
      height: height ?? RitualCardMetrics.height,
      radius: RitualCardMetrics.radius,
      child: const TarotCardBackArt(),
    );
  }
}

class RitualCardFace extends StatelessWidget {
  const RitualCardFace({
    super.key,
    required this.label,
    required this.image,
    this.width,
    this.height,
    this.reversed = false,
    this.density = TarotCardFaceDensity.full,
  });

  final String label;
  final String image;
  final double? width;
  final double? height;
  final bool reversed;
  final TarotCardFaceDensity density;

  @override
  Widget build(BuildContext context) {
    final w = width ?? RitualCardMetrics.width;
    final h = height ?? RitualCardMetrics.height;
    final radius = density == TarotCardFaceDensity.compact
        ? RitualCardMetrics.compactRadius(w)
        : RitualCardMetrics.radius;
    return Transform.rotate(
      angle: reversed ? 3.14159 : 0,
      child: TarotCardFace(
        label: label,
        image: image,
        width: w,
        height: h,
        radius: radius,
        density: density,
      ),
    );
  }
}
