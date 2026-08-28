/// Photoreal gem object — velvet plate, brass whisper. Never an emoji diamond.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/premium_copy.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_gem_facet.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../gems/economy/gem_economy.dart';
import '../../../tarot/economy/tarot_economy.dart';
import 'premium_reference_tokens.dart';

class PremiumReferenceGemNote extends StatelessWidget {
  const PremiumReferenceGemNote({super.key});

  static const double _gemSize = 92;

  @override
  Widget build(BuildContext context) {
    final cost = TarotEconomy.readingCost;
    if (cost <= 0) return const SizedBox.shrink();
    return Column(
      children: [
        Text(
          PremiumCopy.gemSectionTitle,
          textAlign: TextAlign.center,
          style: ReadingTypography.sectionLabel(
            color: OraclyChrome.goldLight.withValues(alpha: 0.82),
            fontSize: 10,
          ),
        ),
        SizedBox(height: PremiumReferenceTokens.sectionLabelToContent),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: OraclyChrome.cardRadius,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A100C), Color(0xFF0A0608)],
            ),
            border: Border.all(
              color: OraclyChrome.gold.withValues(alpha: 0.32),
              width: 0.95,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: OraclyChrome.violet.withValues(alpha: 0.12),
                blurRadius: 18,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              children: [
                const OraclyGemFacet(size: _gemSize, glow: 1.2),
                const SizedBox(height: 12),
                Text(
                  PremiumCopy.gemNote(GemEconomy.tarotReading),
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: ReadingTypography.body(
                    color: OraclyChrome.cream.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
