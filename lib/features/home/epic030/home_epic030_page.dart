/// EPIC-030 — Approved Home (Evren) screen assembly.
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
import 'home_epic030_background.dart';
import 'home_epic030_daily_energy.dart';
import 'home_epic030_explore.dart';
import 'home_epic030_feature_grid.dart';
import 'home_epic030_header.dart';
import 'home_epic030_hero.dart';
import 'home_epic030_premium.dart';
import 'home_epic030_reflection.dart';
import 'home_epic030_spec.dart';
import 'home_epic030_welcome.dart';

/// Reverse-engineered Home portal — EPIC-030 approved design.
class HomeEpic030Page extends StatelessWidget {
  const HomeEpic030Page({super.key});

  static const String _energyDescription =
      'Bugün sezgilerin güçleniyor. İç sesine güven ve adımlarını bilinçle at.';

  @override
  Widget build(BuildContext context) {
    final horizontal = HomeEpic030Spec.horizontalInset;
    final bottom = AppLayout.scrollBottomInset(context);

    return OraclyUniverseTicker(
      child: OraclyScaffold(
        ambience: OraclyAmbience.home,
        backgroundOverlay: const HomeEpic030Background(
          child: SizedBox.shrink(),
        ),
        child: OraclyAdaptiveScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            HomeEpic030Spec.screenTop,
            horizontal,
            bottom,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: HomeEpic030Spec.contentWidth(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HomeEpic030Header(),
                  SizedBox(height: HomeEpic030Spec.headerToWelcome),
                  Consumer(
                    builder: (context, ref, _) {
                      final profile = ref.watch(userProfileProvider);
                      final name = profile.value?.name.trim();
                      final universe = OraclyUniverseState.current();
                      return HomeEpic030Welcome(
                        userName: (name != null && name.isNotEmpty)
                            ? name
                            : FirstSessionCopy.homeGuestName,
                        welcomeDay: universe.moment,
                      );
                    },
                  ),
                  SizedBox(height: HomeEpic030Spec.blockGap(context)),
                  const HomeEpic030Hero(description: _energyDescription),
                  SizedBox(height: HomeEpic030Spec.blockGap(context)),
                  const HomeEpic030FeatureGrid(),
                  SizedBox(height: HomeEpic030Spec.blockGap(context)),
                  const HomeEpic030Premium(),
                  SizedBox(height: HomeEpic030Spec.blockGap(context)),
                  const HomeEpic030Reflection(),
                  SizedBox(height: HomeEpic030Spec.blockGap(context)),
                  const HomeEpic030Explore(),
                  SizedBox(height: HomeEpic030Spec.blockGap(context)),
                  const HomeEpic030DailyEnergy(
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
