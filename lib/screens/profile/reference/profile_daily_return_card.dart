/// Compact daily return on Profile — opens Günün Mesajı, not Home.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/auth/user_local_data_isolation.dart';
import '../../../core/providers/backend_providers.dart' as backend;
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../features/daily_message/copy/daily_message_copy.dart';
import '../../../features/daily_message/data/daily_return_store.dart';
import '../../../features/daily_message/presentation/widgets/daily_message_moon.dart';
import '../../../features/daily_message/services/daily_message_action.dart';
import '../../../features/daily_message/services/daily_message_readiness.dart';
import '../../../features/daily_message/services/daily_message_session.dart';
import '../../../features/personal_discovery/providers/personal_discovery_providers.dart';
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
  int _boundEpoch = UserLocalDataIsolation.accountSwitchEpoch.value;

  @override
  Widget build(BuildContext context) {
    final epoch = ref.watch(backend.localDataOwnerEpochProvider);
    if (_boundEpoch != epoch) {
      _boundEpoch = epoch;
      _recorded = false;
    }
    final palette = AppColors.of(context);
    final storage = ref.watch(localStorageProvider);
    final profile = ref.watch(userProfileProvider);
    final discovery = ref.watch(personalDiscoveryProfileProvider);
    final settings = ref.watch(settingsProvider);
    final day = DateTime.now();
    final store = DailyReturnStore(storage);
    final cached = store.readToday(day);
    final settled = DailyMessageReadiness.all(
      profile: profile,
      discovery: discovery,
      settings: settings,
    );
    final ready = cached != null || settled;
    final message = ready
        ? DailyMessageSession.resolve(
            store: store,
            day: day,
            profileName: profile.value?.name,
            discovery: discovery.valueOrNull,
            recent: ref.watch(discoverySurfaceMemoryProvider).all(),
            personality: settings.value?.aiPersonality,
          )
        : null;
    if (message != null && !_recorded) {
      _recorded = true;
      final captured = _boundEpoch;
      DailyMessageSession.persistAfterFrame(
        ownerEpoch: captured,
        isMounted: () => mounted,
        write: () => DailyMessageSession.persist(
          store: DailyReturnStore(storage),
          memory: ref.read(discoverySurfaceMemoryProvider),
          message: message,
          ownerEpoch: captured,
        ),
      );
    }
    final recommendation = ref.watch(discoveryRecommendationProvider);
    final discoverySettled = DailyMessageReadiness.settled(discovery);
    final ctaAction = message == null
        ? null
        : discoverySettled
        ? dailyReturnActionFor(recommendation.feature, message.action)
        : message.action;
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
                message?.text ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ReadingTypography.body(color: palette.textSecondary),
              ),
              if (ctaAction != null) ...[
                SizedBox(height: AppSpacing.s8),
                Text(
                  DailyMessageCopy.action(ctaAction),
                  style: ReadingTypography.bodyCore(
                    color: palette.goldLight.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
