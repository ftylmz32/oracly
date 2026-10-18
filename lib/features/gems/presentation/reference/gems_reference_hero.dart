/// Balance hero — luminous gem on velvet, live wallet, no fake packages.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(gemWalletProvider).formatted;
    final art = GemsReferenceTokens.heroArtSizeFor(context);
    final gem = art * 0.78;
    return OraclyGlassCard(
      borderRadius: GemsReferenceTokens.heroRadius,
      padding: GemsReferenceTokens.heroPadding,
      premium: true,
      glowStrength: 0.72,
      child: Column(
        children: [
          Center(
            child: OraclyGemFacet(size: gem, semanticsLabel: GemsCopy.gemUnit),
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
