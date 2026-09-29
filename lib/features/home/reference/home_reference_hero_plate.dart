/// Home hero cinematic plate — stable portrait + quiet celestial breath.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/oracly_quiet_motion.dart';
import '../../../core/universe/oracly_universe_layer.dart';
import '../../../core/universe/oracly_universe_state.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import '../theme/home_ritual_visuals.dart';
import 'home_reference_hero_atmosphere.dart';

/// Image + atmosphere only. Greeting copy lives in [HomeReferenceHero].
class HomeReferenceHeroPlate extends StatefulWidget {
  const HomeReferenceHeroPlate({super.key});

  @override
  State<HomeReferenceHeroPlate> createState() => _HomeReferenceHeroPlateState();
}

class _HomeReferenceHeroPlateState extends State<HomeReferenceHeroPlate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16000),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _breath, reverse: true, rest: 0.38);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final universe =
        OraclyUniverseScope.maybeOf(context) ?? OraclyUniverseState.current();
    final visual = HomeRitualVisuals.of(universe.ritualTime);
    final still = OraclyQuietMotion.still(context);
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [visual.skyTop, visual.skyBottom],
              ),
            ),
          ),
          Opacity(
            opacity: visual.heroPlateOpacity,
            child: const OraclyAssetImage(
              assetPath: AppAssets.homeHeroMoon,
              fit: BoxFit.cover,
              alignment: Alignment(0.18, -0.04),
              cacheCapPx: 960,
              fallback: ColoredBox(color: Color(0xFF05030C)),
            ),
          ),
          still
              ? HomeReferenceHeroAtmosphere(t: 0.38, visual: visual)
              : AnimatedBuilder(
                  animation: _breath,
                  builder: (_, _) => HomeReferenceHeroAtmosphere(
                    t: _breath.value,
                    visual: visual,
                  ),
                ),
        ],
      ),
    );
  }
}
