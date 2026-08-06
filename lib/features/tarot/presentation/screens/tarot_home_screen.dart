/// OR-1010 / OR-409 — Production Tarot Home screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../theme/tarot_tokens.dart';
import '../../domain/models/tarot_spread.dart';
import '../../shared/tarot_scope.dart';
import '../widgets/tarot_home/oracly_sacred_identity.dart';
import '../widgets/tarot_home/tarot_continue_reading_section.dart';
import '../widgets/tarot_home/tarot_daily_banner.dart';
import '../widgets/tarot_home/tarot_home_background.dart';
import '../widgets/tarot_home/tarot_home_cinematic_scroll.dart';
import '../widgets/tarot_home/tarot_home_entrance.dart';
import '../widgets/tarot_home/tarot_home_hero_section.dart';
import '../widgets/tarot_home/tarot_home_premium_cta.dart';
import '../widgets/tarot_home/tarot_home_section_bridge.dart';
import '../widgets/tarot_home/tarot_spread_section.dart';

/// Sacred tarot ritual entry — progressive chamber discovery.
class TarotHomeScreen extends ConsumerWidget {
  const TarotHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    OraclyNavigationService.logScreen(ref, 'tarot_home');

    return OraclyScaffold(
      backgroundOverlay: const TarotHomeBackground(),
      child: TarotHomeCinematicScroll(
        builder: (context, scrollOffset, ambientPhase) {
          return Padding(
            padding: TarotTokens.screenPadding.copyWith(
              top: OraclyRhythm.screenTop,
              bottom: OraclyRhythm.screenBottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: TarotTokens.maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TarotHomeDepthSection(
                      scrollOffset: scrollOffset,
                      ambientPhase: ambientPhase,
                      index: 0,
                      child: TarotHomeEntrance(
                        hero: true,
                        delay: TarotHomeStagger.hero,
                        child: const TarotHomeHeroSection(),
                      ),
                    ),
                    TarotHomeSectionBridge(
                      kind: TarotHomeBridgeKind.orbSpill,
                      phase: ambientPhase,
                    ),
                    TarotHomeDepthSection(
                      scrollOffset: scrollOffset,
                      ambientPhase: ambientPhase,
                      index: 1,
                      child: TarotSpreadSection(
                        onSpreadSelected: (spread) async {
                          final spreadType =
                              TarotSpreadType.fromTitle(spread.title) ??
                                  TarotSpreadType.single;
                          TarotScope.of(context).flow.selectSpread(spreadType);
                          ref.read(selectedSpreadProvider.notifier).state =
                              spread.title;
                          await ref
                              .read(tarotServiceProvider)
                              .selectSpread(spread.title);
                          if (!context.mounted) return;
                          OraclyNavigationService.startTarotFlow(
                            context,
                            spreadType: spread.title,
                          );
                        },
                      ),
                    ),
                    TarotHomeSectionBridge(
                      kind: TarotHomeBridgeKind.purpleMist,
                      phase: ambientPhase,
                    ),
                    const TarotHomeBreathGap(size: OraclyRhythm.breathGapAfterBridge),
                    TarotHomeDepthSection(
                      scrollOffset: scrollOffset,
                      ambientPhase: ambientPhase,
                      index: 2,
                      child: TarotContinueReadingSection(
                        onViewAll: () => OraclyNavigationService.openReadingHistory(
                          context,
                        ),
                      ),
                    ),
                    TarotHomeSectionBridge(
                      kind: TarotHomeBridgeKind.constellation,
                      phase: ambientPhase,
                    ),
                    const TarotHomeBreathGap(),
                    TarotHomeDepthSection(
                      scrollOffset: scrollOffset,
                      ambientPhase: ambientPhase,
                      index: 3,
                      child: TarotDailyBanner(
                        onTap: () =>
                            OraclyNavigationService.startDailyCardDraw(context),
                      ),
                    ),
                    TarotHomeSectionBridge(
                      kind: TarotHomeBridgeKind.sacredGeometry,
                      phase: ambientPhase,
                    ),
                    const TarotHomeBreathGap(size: OraclyRhythm.breathGapAfterBridge),
                    TarotHomeDepthSection(
                      scrollOffset: scrollOffset,
                      ambientPhase: ambientPhase,
                      index: 4,
                      child: TarotHomePremiumCta(
                        onTap: () =>
                            OraclyNavigationService.openPremium(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
