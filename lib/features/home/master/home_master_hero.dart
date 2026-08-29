/// Home hero — cinematic plate; first-reading CTA when intent is pending.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/copy/first_session_copy.dart';
import '../../../core/copy/home_personal_copy.dart';
import '../../../core/experience/domain/models/experience_context.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/universe/oracly_universe_layer.dart';
import '../../../core/universe/oracly_universe_state.dart';
import '../../premium/models/personalization_models.dart';
import '../reference/home_reference_hero.dart';
import '../services/first_continuity_home.dart';
import '../services/home_hero_returning_copy.dart';

class HomeMasterHero extends ConsumerWidget {
  const HomeMasterHero({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(firstReadingPendingProvider);
    if (pending) {
      return _firstReadingHero(context, ref);
    }

    // Loading/error → null → existing copy (no blank hero).
    final living = ref.watch(livingExperienceProvider).valueOrNull;
    final continuity = _continuityOf(ref);
    if (continuity != null) {
      return _continuityHero(context, ref, continuity, living);
    }

    return _defaultHero(context, ref, living);
  }

  Widget _firstReadingHero(BuildContext context, WidgetRef ref) {
    return HomeReferenceHero(
      height: height ?? 156,
      hello: _hello(context, ref),
      invite: FirstSessionCopy.homeSubtitleNew,
      ctaLabel: FirstSessionCopy.homeCta,
      onCta: () => OraclyNavigationService.openTarotHome(context),
    );
  }

  Widget _continuityHero(
    BuildContext context,
    WidgetRef ref,
    FirstContinuityHomeState continuity,
    ExperienceContext? living,
  ) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final softHello = HomeHeroReturningCopy.greetingOnly(
      experience: living,
      userName: profile?.name,
    );
    return HomeReferenceHero(
      height: height ?? 156,
      hello: softHello ?? _hello(context, ref),
      invite: FirstSessionCopy.continuityInvite(continuity.cardName),
      ctaLabel: FirstSessionCopy.continuityCta,
      // Existing OR thread only — never re-offer handoff or free deepen.
      onCta: () => OraclyNavigationService.openChat(context),
    );
  }

  Widget _defaultHero(
    BuildContext context,
    WidgetRef ref,
    ExperienceContext? living,
  ) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final settings =
        ref.watch(settingsProvider).valueOrNull ??
        const PersonalizationSettings();
    final universe =
        OraclyUniverseScope.maybeOf(context) ?? OraclyUniverseState.current();
    final returning = HomeHeroReturningCopy.defaultPlate(
      experience: living,
      universe: universe,
      settings: settings,
      userName: profile?.name,
    );
    if (returning == null) {
      return HomeReferenceHero(height: height ?? 156);
    }
    return HomeReferenceHero(
      height: height ?? 156,
      hello: returning.hello,
      invite: returning.invite,
    );
  }

  String _hello(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final universe =
        OraclyUniverseScope.maybeOf(context) ?? OraclyUniverseState.current();
    return HomePersonalCopy.greeting(
      time: universe.ritualTime,
      profileName: profile?.name,
    );
  }

  FirstContinuityHomeState? _continuityOf(WidgetRef ref) {
    final storage = ref.watch(localStorageProvider);
    final history = ref.watch(readingHistoryProvider).asData?.value;
    if (history == null) return null;
    return FirstContinuityHome.resolve(storage: storage, history: history);
  }
}
