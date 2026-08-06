/// OR-030 / OR-1021 — Tarot home hero: layered deck with mystical ambience.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import 'tarot_deck_ambience.dart';
import 'tarot_fanned_deck.dart';

/// Layered tarot deck with fog, aura, particles, and focus subtitle.
class TarotHomeHero extends StatelessWidget {
  const TarotHomeHero({super.key});

  static const String _subtitle =
      'Kartlarına odaklan, enerjini hisset ve kartları seç.';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: AppSpacing.xxl + AppSpacing.xxl + AppSpacing.xxl + AppSpacing.lg,
          child: Center(
            child: TarotDeckAmbience(
              width: 300,
              height: 220,
              child: const TarotFannedDeck(
                cardCount: 7,
                cardWidth: 76,
                cardHeight: 124,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            _subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}
