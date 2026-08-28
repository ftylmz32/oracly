/// Compact daily return on Profile — opens Günün Mesajı, not Home.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../features/daily_message/copy/daily_message_copy.dart';
import '../../../features/daily_message/data/daily_return_store.dart';
import '../../../features/daily_message/models/daily_return_action.dart';
import '../../../features/daily_message/presentation/widgets/daily_message_moon.dart';
import '../../../features/daily_message/services/daily_message_session.dart';
import '../../../features/personal_discovery/providers/personal_discovery_providers.dart';
import '../../../features/personal_discovery/models/discovery_recommended_feature.dart';
import 'profile_reference_card_shell.dart';

class ProfileDailyReturnCard extends ConsumerStatefulWidget {
  const ProfileDailyReturnCard({super.key});

  @override
  ConsumerState<ProfileDailyReturnCard> createState() =>
      _ProfileDailyReturnCardState();
}

class _ProfileDailyReturnCardState
    extends ConsumerState<ProfileDailyReturnCard> {
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
    final palette = AppColors.of(context);
    final storage = ref.watch(localStorageProvider);
    final message = DailyMessageSession.resolve(
      store: DailyReturnStore(storage),
      day: DateTime.now(),
      profileName: ref.watch(userProfileProvider).value?.name,
      discovery: ref.watch(personalDiscoveryProfileProvider).valueOrNull,
      recent: ref.watch(discoverySurfaceMemoryProvider).all(),
    );
    final recommendation = ref.watch(discoveryRecommendationProvider);
    final ctaAction = _actionFor(recommendation.feature, message.action);
    if (!_recorded) {
      _recorded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DailyMessageSession.persist(
          store: DailyReturnStore(storage),
          memory: ref.read(discoverySurfaceMemoryProvider),
          message: message,
        );
      });
    }
    return Semantics(
      button: true,
      label: DailyMessageCopy.prompt,
      child: ProfileReferenceCardShell(
        onTap: () => OraclyNavigationService.openDailyMessage(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const DailyMessageMoon(size: 28),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      DailyMessageCopy.prompt,
                      style: ReadingTypography.sectionLabel(
                        color: palette.goldLight,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                message.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ReadingTypography.body(color: palette.textSecondary),
              ),
              SizedBox(height: AppSpacing.s8),
              Text(
                DailyMessageCopy.action(ctaAction),
                style: ReadingTypography.bodyCore(
                  color: palette.goldLight.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
