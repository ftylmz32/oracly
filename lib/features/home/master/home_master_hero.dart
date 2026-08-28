/// Home hero — cinematic plate; first-reading CTA when intent is pending.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/copy/first_session_copy.dart';
import '../../../core/copy/home_personal_copy.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/universe/oracly_universe_layer.dart';
import '../../../core/universe/oracly_universe_state.dart';
import '../reference/home_reference_hero.dart';

class HomeMasterHero extends ConsumerWidget {
  const HomeMasterHero({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(firstReadingPendingProvider);
    if (!pending) {
      return HomeReferenceHero(height: height ?? 156);
    }

    final profile = ref.watch(userProfileProvider).valueOrNull;
    final universe =
        OraclyUniverseScope.maybeOf(context) ?? OraclyUniverseState.current();
    final hello = HomePersonalCopy.greeting(
      time: universe.ritualTime,
      profileName: profile?.name,
    );

    return HomeReferenceHero(
      height: height ?? 156,
      hello: hello,
      invite: FirstSessionCopy.homeSubtitleNew,
      ctaLabel: FirstSessionCopy.homeCta,
      onCta: () => OraclyNavigationService.openTarotHome(context),
    );
  }
}
