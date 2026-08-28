/// Full-bleed cup table — heat, steam, candle. Not a framed card.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/oracly_quiet_motion.dart';
import '../../../../shared/widgets/oracly_asset_image.dart';
import '../../copy/coffee_copy.dart';
import 'coffee_cup_art.dart';

class CoffeeCupHero extends StatefulWidget {
  const CoffeeCupHero({super.key, this.height});

  final double? height;

  @override
  State<CoffeeCupHero> createState() => _CoffeeCupHeroState();
}

class _CoffeeCupHeroState extends State<CoffeeCupHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _breath, rest: 0.12);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = widget.height ??
            (constraints.maxHeight.isFinite ? constraints.maxHeight : 420.0);
        final w =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
        return Semantics(
          label: CoffeeCopy.screenTitle,
          child: SizedBox(
            height: h,
            width: w,
            child: AnimatedBuilder(
              animation: _breath,
              child: RepaintBoundary(
                child: Transform.scale(
                  scale: 1.02,
                  alignment: Alignment.center,
                  child: OraclyAssetImage(
                    assetPath: AppAssets.coffeeRitualHero,
                    width: w,
                    height: h,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0.12, -0.06),
                    filterQuality: FilterQuality.high,
                    fallback: CustomPaint(
                      size: Size(w, h),
                      painter: const CoffeeCupFallback(phase: 0.12),
                    ),
                  ),
                ),
              ),
              builder: (context, child) {
                final t =
                    OraclyQuietMotion.still(context) ? 0.12 : _breath.value;
                return CoffeeCupArt(
                  width: w,
                  height: h,
                  phase: t,
                  photo: child,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
