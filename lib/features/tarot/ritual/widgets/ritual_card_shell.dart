/// Canonical ritual card size + clip for Oracly card-back / face.
///
/// Phase 7B: physicality sourced from [TarotTokens] ritual card tokens.
library;

import "package:flutter/material.dart";

import "../../art/tarot_card_back_art.dart";
import "../../theme/tarot_tokens.dart";
import "../../widgets/tarot_card_shell.dart";

abstract final class RitualCardMetrics {
  RitualCardMetrics._();

  static const width = TarotTokens.ritualCardWidth;
  static const height = TarotTokens.ritualCardHeight;
  static const radius = TarotTokens.ritualCardRadius;
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
  });

  final String label;
  final String image;
  final double? width;
  final double? height;
  final bool reversed;

  @override
  Widget build(BuildContext context) {
    final w = width ?? RitualCardMetrics.width;
    final h = height ?? RitualCardMetrics.height;
    return Transform.rotate(
      angle: reversed ? 3.14159 : 0,
      child: TarotCardFace(
        label: label,
        image: image,
        width: w,
        height: h,
        radius: RitualCardMetrics.radius,
      ),
    );
  }
}
