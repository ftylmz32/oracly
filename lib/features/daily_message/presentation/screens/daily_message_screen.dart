/// Compact Günün Mesajı — one ritual sentence, one real next step.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/auth/user_local_data_isolation.dart';
import '../../../../core/providers/backend_providers.dart' as backend;
import '../../../../core/data/datasources/local_storage.dart';
import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/oracly_app_bar.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../features/gems/widgets/oracly_live_gem_capsule.dart';
import '../../../../shared/widgets/oracly_cinematic_loading.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../../personal_discovery/copy/discovery_recommendation_copy.dart';
import '../../../personal_discovery/models/discovery_recommended_feature.dart';
import '../../../personal_discovery/providers/personal_discovery_providers.dart';
import '../../../personal_discovery/services/personal_discovery_refresh.dart';
import '../../copy/daily_message_copy.dart';
import '../../data/daily_return_store.dart';
import '../../models/daily_message.dart';
import '../../services/daily_message_action.dart';
import '../../services/daily_message_readiness.dart';
import '../../services/daily_message_session.dart';
import '../widgets/daily_message_atmosphere.dart';
import '../widgets/daily_message_body.dart';

class DailyMessageScreen extends ConsumerStatefulWidget {
  const DailyMessageScreen({super.key});

  @override
  ConsumerState<DailyMessageScreen> createState() => _DailyMessageScreenState();
}

class _DailyMessageScreenState extends ConsumerState<DailyMessageScreen> {
  bool _recorded = false;
  int _boundEpoch = UserLocalDataIsolation.accountSwitchEpoch.value;

  void _persistOnce(LocalStorage storage, DailyMessage message) {
    if (_recorded) return;
    _recorded = true;
    final epoch = _boundEpoch;
    DailyMessageSession.persistAfterFrame(
      ownerEpoch: epoch,
      isMounted: () => mounted,
      write: () async {
        await DailyMessageSession.persist(
          store: DailyReturnStore(storage),
          memory: ref.read(discoverySurfaceMemoryProvider),
          message: message,
          ownerEpoch: epoch,
        );
        if (!mounted) return;
        if (UserLocalDataIsolation.accountSwitchEpoch.value != epoch) return;
        PersonalDiscoveryRefresh.invalidate(ref);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final epoch = ref.watch(backend.localDataOwnerEpochProvider);
    if (_boundEpoch != epoch) {
      _boundEpoch = epoch;
      _recorded = false;
    }
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
    if (cached == null && !settled) {
      return _shell(const OraclyCinematicLoading(compact: true));
    }
    final message = DailyMessageSession.resolve(
      store: store,
      day: day,
      profileName: profile.value?.name,
      discovery: discovery.valueOrNull,
      recent: ref.watch(discoverySurfaceMemoryProvider).all(),
      personality: settings.value?.aiPersonality,
    );
    _persistOnce(storage, message);
    final discoverySettled = DailyMessageReadiness.settled(discovery);
    final recommendation = ref.watch(discoveryRecommendationProvider);
    final reason = discoverySettled
        ? DiscoveryRecommendationCopy.reason(recommendation)
        : null;
    final showReentry =
        discoverySettled &&
        (recommendation.feature != DiscoveryRecommendedFeature.dailyMessage ||
            recommendation.hasEvidence);
    final ctaAction = discoverySettled
        ? dailyReturnActionFor(recommendation.feature, message.action)
        : message.action;
    return _shell(
      DailyMessageBody(
        message: message,
        showReentry: showReentry,
        reason: reason,
        recommendationLabel: DiscoveryRecommendationCopy.cta(
          recommendation.feature,
        ),
        ctaAction: ctaAction,
      ),
    );
  }

  Widget _shell(Widget child) {
    return OraclyScaffold(
      safeArea: false,
      usePremiumBackground: false,
      backgroundOverlay: const DailyMessageAtmosphere(child: SizedBox.shrink()),
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
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
