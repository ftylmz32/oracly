/// El Falı hero — photoreal hand on velvet. Silhouette only as fallback.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/oracly_quiet_motion.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import '../copy/palm_copy.dart';
import '../models/palm_hand.dart';
import 'palm_hero_field.dart';
import 'palm_photo_frame.dart';
import 'palm_photo_veil.dart';
import 'palm_silhouette_art.dart';

class PalmHero extends StatefulWidget {
  const PalmHero({super.key, this.height, this.hand = PalmHand.right});

  final double? height;

  /// palm_ritual_hero.webp is a right palm (wrist at the right edge, thumb
  /// toward the top); the left choice shows it mirrored.
  final PalmHand hand;

  @override
  State<PalmHero> createState() => _PalmHeroState();
}

class _PalmHeroState extends State<PalmHero>
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
    OraclyQuietMotion.ambient(context, _breath, rest: 0.14);
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
        final h =
            widget.height ??
            (constraints.maxHeight.isFinite ? constraints.maxHeight : 220.0);
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
        final mirror = widget.hand == PalmHand.left;
        return Semantics(
          label: '${PalmCopy.screenTitle}, ${widget.hand.label}',
          child: SizedBox(
            height: h,
            width: w,
            child: AnimatedBuilder(
              animation: _breath,
              child: RepaintBoundary(
                child: PalmPhotoFrame(
                  hero: true,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedSwitcher(
                        duration: OraclyQuietMotion.still(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 260),
                        child: Transform(
                          key: ValueKey('palm-hero-${widget.hand.name}'),
                          alignment: Alignment.center,
                          transform: Matrix4.diagonal3Values(
                            mirror ? -1 : 1,
                            1,
                            1,
                          ),
                          child: Transform.scale(
                            scale: 1.02,
                            alignment: const Alignment(0.04, -0.06),
                            child: OraclyAssetImage(
                              assetPath: AppAssets.palmRitualHero,
                              width: w,
                              height: h,
                              fit: BoxFit.cover,
                              alignment: const Alignment(0.06, 0.04),
                              filterQuality: FilterQuality.high,
                              fallback: ColoredBox(
                                color: OraclyChrome.midnight,
                                child: Center(
                                  child: PalmSilhouetteArt(
                                    size: (h * 0.72).clamp(100.0, 220.0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const IgnorePointer(child: PalmPhotoVeil()),
                    ],
                  ),
                ),
              ),
              builder: (context, child) {
                final t = OraclyQuietMotion.still(context)
                    ? 0.14
                    : _breath.value;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    PalmHeroField(size: math.max(w, h), phase: t),
                    child!,
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
