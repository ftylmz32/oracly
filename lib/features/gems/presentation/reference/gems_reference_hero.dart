/// Balance hero — luminous gem on velvet, live wallet, no fake packages.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/chamber_hero_stage.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_gem_facet.dart';
import '../../../../core/design_system/oracly_glass_card.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../copy/gems_copy.dart';
import '../../providers/gem_providers.dart';
import 'gems_reference_tokens.dart';

class GemsBalanceHero extends ConsumerWidget {
  const GemsBalanceHero({super.key});

  static const _velvet = Color(0xFF120814);
  static const _candle = Color(0xFFD4A86A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(gemWalletProvider).formatted;
    final art = GemsReferenceTokens.heroArtSizeFor(context);
    return OraclyGlassCard(
      borderRadius: GemsReferenceTokens.heroRadius,
      padding: GemsReferenceTokens.heroPadding,
      premium: true,
      glowStrength: 1.18,
      child: Column(
        children: [
          Center(
            child: SizedBox(
              width: art,
              height: art,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _candle.withValues(alpha: 0.10),
                      _velvet.withValues(alpha: 0.92),
                      const Color(0xFF07040F),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                  border: Border.all(
                    color: OraclyChrome.goldLight.withValues(alpha: 0.36),
                    width: 1.05,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: OraclyChrome.violet.withValues(alpha: 0.28),
                      blurRadius: 28,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: OraclyChrome.gold.withValues(alpha: 0.14),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: ChamberHeroStage(
                  warm: true,
                  glow: 1.05,
                  child: OraclyGemFacet(
                    size: art * 0.52,
                    glow: 1.18,
                    semanticsLabel: GemsCopy.gemUnit,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: GemsReferenceTokens.heroToIntro),
          Text(
            balance,
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: OraclyChrome.goldLight.withValues(alpha: 0.96),
              height: CraftsmanshipRhythm.displayLineHeight,
              letterSpacing: CraftsmanshipRhythm.displayTracking,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            GemsCopy.balanceLabel,
            textAlign: TextAlign.center,
            style: OraclyChrome.sectionLabel(size: 11).copyWith(
              color: OraclyChrome.goldPrimary.withValues(alpha: 0.88),
              letterSpacing: CraftsmanshipRhythm.sectionLabelTracking + 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
