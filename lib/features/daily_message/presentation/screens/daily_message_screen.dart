/// Compact Günün Mesajı — one ritual sentence, one real next step.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/oracly_app_bar.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/insight_copy/widgets/insight_copy_link.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../features/gems/widgets/oracly_live_gem_capsule.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../../discovery_share/services/discovery_share_builder.dart';
import '../../../discovery_share/widgets/discovery_share_action.dart';
import '../../../favorite_moments/presentation/widgets/save_favorite_moment_link.dart';
import '../../../favorite_moments/services/favorite_moment_factory.dart';
import '../../../personal_discovery/providers/personal_discovery_providers.dart';
import '../../../personal_discovery/copy/discovery_recommendation_copy.dart';
import '../../../personal_discovery/models/discovery_recommended_feature.dart';
import '../../../personal_discovery/services/personal_discovery_refresh.dart';
import '../../copy/daily_message_copy.dart';
import '../../data/daily_return_store.dart';
import '../../models/daily_return_action.dart';
import '../../services/daily_message_session.dart';
import '../widgets/daily_message_atmosphere.dart';
import '../widgets/daily_message_card.dart';
import '../widgets/daily_return_cta.dart';

class DailyMessageScreen extends ConsumerStatefulWidget {
  const DailyMessageScreen({super.key});

  @override
  ConsumerState<DailyMessageScreen> createState() => _DailyMessageScreenState();
}

class _DailyMessageScreenState extends ConsumerState<DailyMessageScreen> {
  bool _recorded = false;

  DailyReturnAction _actionFor(
    DiscoveryRecommendedFeature feature,
    DailyReturnAction fallback,
  ) {
    return switch (feature) {
      DiscoveryRecommendedFeature.companion => DailyReturnAction.talkToOr,
      DiscoveryRecommendedFeature.dream => DailyReturnAction.tellDream,
      DiscoveryRecommendedFeature.tarot => DailyReturnAction.askTarot,
      DiscoveryRecommendedFeature.starMap => DailyReturnAction.exploreStarMap,
      DiscoveryRecommendedFeature.coffee => DailyReturnAction.readCoffee,
      DiscoveryRecommendedFeature.palm => DailyReturnAction.readPalm,
      DiscoveryRecommendedFeature.astrology => DailyReturnAction.readAstrology,
      DiscoveryRecommendedFeature.dailyMessage => fallback,
    };
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(localStorageProvider);
    final message = DailyMessageSession.resolve(
      store: DailyReturnStore(storage),
      day: DateTime.now(),
      profileName: ref.watch(userProfileProvider).value?.name,
      discovery: ref.watch(personalDiscoveryProfileProvider).valueOrNull,
      recent: ref.watch(discoverySurfaceMemoryProvider).all(),
      personality: ref.watch(settingsProvider).value?.aiPersonality,
    );
    final recommendation = ref.watch(discoveryRecommendationProvider);
    final reason = DiscoveryRecommendationCopy.reason(recommendation);
    final showReentry = recommendation.feature !=
            DiscoveryRecommendedFeature.dailyMessage ||
        recommendation.hasEvidence;
    final ctaAction = _actionFor(recommendation.feature, message.action);
    if (!_recorded) {
      _recorded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DailyMessageSession.persist(
          store: DailyReturnStore(storage),
          memory: ref.read(discoverySurfaceMemoryProvider),
          message: message,
        );
        PersonalDiscoveryRefresh.invalidate(ref);
      });
    }
    return OraclyScaffold(
      safeArea: false,
      usePremiumBackground: false,
      backgroundOverlay: const DailyMessageAtmosphere(
        child: SizedBox.shrink(),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            OraclyChrome.screenSide,
            OraclyChrome.screenTop,
            OraclyChrome.screenSide,
            AppLayout.scrollBottomInset(context),
          ),
          child: Column(
            children: [
              OraclyAppBar(
                title: DailyMessageCopy.screenTitle,
                titleIcon: Icons.nightlight_round,
                onLeadingTap: () => Navigator.of(context).maybePop(),
                trailing: OraclyLiveGemCapsule(
                  onTap: () => OraclyNavigationService.openGems(context),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: const Alignment(0, -0.18),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DailyMessageCard(message: message),
                        InsightCopyLink(text: message.text),
                        SaveFavoriteMomentLink(
                          draft: FavoriteMomentFactory.daily(message),
                        ),
                        DiscoveryShareAction(
                          discovery: DiscoveryShareBuilder.dailyInsight(
                            highlight: message.text,
                          ),
                        ),
                        if (showReentry) ...[
                          const SizedBox(height: AppSpacing.s8),
                          Text(
                            DailyMessageCopy.discoveryTitle,
                            textAlign: TextAlign.center,
                            style: ReadingTypography.sectionLabel(
                              color: OraclyChrome.goldLight.withValues(alpha: 0.9),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          if (reason != null) ...[
                            Text(
                              reason,
                              textAlign: TextAlign.center,
                              style: ReadingTypography.body(
                                color: OraclyChrome.cream.withValues(alpha: 0.78),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s8),
                          ],
                          Text(
                            DiscoveryRecommendationCopy.cta(
                              recommendation.feature,
                            ),
                            textAlign: TextAlign.center,
                            style: ReadingTypography.bodyCore(
                              color: OraclyChrome.goldLight.withValues(alpha: 0.94),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.s8),
                        DailyReturnCta(action: ctaAction, message: message),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
