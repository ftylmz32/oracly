/// OR-UX — Per-deck visual identity for deck selection cards.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'deck_selection_data.dart';

enum DeckVisualStyle {
  classic,
  golden,
  standard,
}

extension DeckVisualStyleX on TarotDeckOption {
  DeckVisualStyle get visualStyle => switch (id) {
        'classic' => DeckVisualStyle.classic,
        'golden' => DeckVisualStyle.golden,
        _ => DeckVisualStyle.standard,
      };
}

/// Deck-specific atmosphere overlays for artwork preview.
class DeckArtworkAtmosphere extends StatelessWidget {
  const DeckArtworkAtmosphere({
    super.key,
    required this.style,
  });

  final DeckVisualStyle style;

  @override
  Widget build(BuildContext context) {
    return switch (style) {
      DeckVisualStyle.classic => const _ClassicAtmosphere(),
      DeckVisualStyle.golden => const _GoldenAtmosphere(),
      DeckVisualStyle.standard => const SizedBox.shrink(),
    };
  }
}

class _ClassicAtmosphere extends StatelessWidget {
  const _ClassicAtmosphere();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.white.withValues(alpha: 0.06),
              AppColors.transparent,
              AppColors.purpleDark.withValues(alpha: 0.12),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoldenAtmosphere extends StatelessWidget {
  const _GoldenAtmosphere();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.2, -0.3),
                radius: 1.1,
                colors: [
                  AppColors.goldLight.withValues(alpha: 0.22),
                  AppColors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.transparent,
                  AppColors.background.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
