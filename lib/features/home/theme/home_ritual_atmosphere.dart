/// Home-only ritual wash. Layout-neutral. Does not restyle other chambers.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/universe/oracly_universe_layer.dart';
import '../../../core/universe/oracly_universe_state.dart';
import 'home_ritual_visuals.dart';

/// Resolves the active [OraclyRitualTime] and paints [HomeRitualWash].
class HomeRitualAtmosphere extends StatelessWidget {
  const HomeRitualAtmosphere({super.key});

  @override
  Widget build(BuildContext context) {
    final universe =
        OraclyUniverseScope.maybeOf(context) ?? OraclyUniverseState.current();
    return HomeRitualWash(visual: HomeRitualVisuals.of(universe.ritualTime));
  }
}

/// Static gradients over the shared cosmic base. No blur, no ticker.
class HomeRitualWash extends StatelessWidget {
  const HomeRitualWash({super.key, required this.visual});

  final HomeRitualVisual visual;

  @override
  Widget build(BuildContext context) {
    final edge = visual.pageWashAlpha;
    final crown = edge * (1 - visual.starBias * 0.8);
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              visual.skyTop.withValues(alpha: edge),
              visual.skyBottom.withValues(alpha: edge * 0.85),
            ],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: visual.lightCenter,
              radius: 1.2,
              colors: [
                AppColors.goldLight.withValues(alpha: visual.goldAlpha * 0.65),
                AppColors.accentPink.withValues(alpha: visual.roseAlpha * 0.4),
                AppColors.primaryPurple.withValues(
                  alpha: visual.violetAlpha * 0.32,
                ),
                AppColors.midnightNavy.withValues(alpha: crown),
              ],
              stops: const [0.0, 0.3, 0.58, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
