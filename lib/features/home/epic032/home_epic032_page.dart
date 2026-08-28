/// EPIC-032 — Approved Home (Evren) screen assembly.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/copy/first_session_copy.dart';
import '../../../core/design_system/app_layout.dart';
import '../../../core/theme/oracly_visual_rebirth.dart';
import '../../../core/universe/oracly_universe_layer.dart';
import '../../../core/universe/oracly_universe_state.dart';
import '../../../shared/widgets/oracly_adaptive_scroll_view.dart';
import '../../../shared/widgets/oracly_scaffold.dart';
import 'home_epic032_background.dart';
import 'home_epic032_daily_energy.dart';
import 'home_epic032_explore.dart';
import 'home_epic032_feature_grid.dart';
import 'home_epic032_header.dart';
import 'home_epic032_hero.dart';
import 'home_epic032_premium.dart';
import 'home_epic032_reflection.dart';
import 'home_epic032_spec.dart';
import 'home_epic032_welcome.dart';

/// Reverse-engineered Home portal — EPIC-032 approved Figma translation.
class HomeEpic032Page extends StatelessWidget {
  const HomeEpic032Page({super.key});

  static const String _energyDescription =
      'Bugün sezgilerin güçleniyor. İç sesine güven ve adımlarını bilinçle at.';

  @override
  Widget build(BuildContext context) {
    final horizontal = HomeEpic032Spec.horizontalInset;
    final bottom = AppLayout.scrollBottomInset(context);

    return OraclyUniverseTicker(
      child: OraclyScaffold(
        ambience: OraclyAmbience.home,
        backgroundOverlay: const HomeEpic032Background(
          child: SizedBox.shrink(),
        ),
        child: OraclyAdaptiveScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            HomeEpic032Spec.screenTop,
            horizontal,
            bottom,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: HomeEpic032Spec.contentWidth(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HomeEpic032Header(),
                  SizedBox(height: HomeEpic032Spec.headerToWelcome),
                  Consumer(
                    builder: (context, ref, _) {
                      final profile = ref.watch(userProfileProvider);
                      final name = profile.value?.name.trim();
                      final universe = OraclyUniverseState.current();
                      return HomeEpic032Welcome(
                        userName: (name != null && name.isNotEmpty)
                            ? name
                            : FirstSessionCopy.homeGuestName,
                        welcomeDay: universe.moment,
                      );
                    },
                  ),
                  SizedBox(height: HomeEpic032Spec.blockGap(context)),
                  const HomeEpic032Hero(description: _energyDescription),
                  SizedBox(height: HomeEpic032Spec.blockGap(context)),
                  const HomeEpic032FeatureGrid(),
                  SizedBox(height: HomeEpic032Spec.blockGap(context)),
                  const HomeEpic032Premium(),
                  SizedBox(height: HomeEpic032Spec.blockGap(context)),
                  const HomeEpic032Reflection(),
                  SizedBox(height: HomeEpic032Spec.blockGap(context)),
                  const HomeEpic032Explore(),
                  SizedBox(height: HomeEpic032Spec.blockGap(context)),
                  const HomeEpic032DailyEnergy(
                    description: _energyDescription,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
