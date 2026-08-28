/// Crisp zodiac-wheel artwork — slow celestial drift, never natal fakes.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/app_icons.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_soft_reveal.dart';
import '../../../../core/theme/oracly_quiet_motion.dart';
import '../../../../shared/widgets/oracly_asset_image.dart';

class AstrologyReferenceWheelArt extends StatefulWidget {
  const AstrologyReferenceWheelArt({super.key, this.size = 112});

  final double size;

  @override
  State<AstrologyReferenceWheelArt> createState() =>
      _AstrologyReferenceWheelArtState();
}

class _AstrologyReferenceWheelArtState extends State<AstrologyReferenceWheelArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 72),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      OraclyQuietMotion.ambient(context, _spin, rest: 0);
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return OraclySoftReveal(
      child: SizedBox(
        width: size,
        height: size,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _spin,
            builder: (context, child) {
              final t = OraclyQuietMotion.still(context) ? 0.0 : _spin.value;
              return Transform.rotate(
                angle: t * 0.35,
                child: child,
              );
            },
          child: Stack(
            alignment: Alignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: OraclyChrome.violet.withValues(alpha: 0.42),
                      blurRadius: 34,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: OraclyChrome.gold.withValues(alpha: 0.28),
                      blurRadius: 26,
                    ),
                  ],
                ),
                child: SizedBox(width: size * 0.92, height: size * 0.92),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: OraclyChrome.midnight,
                  border: Border.all(
                    color: OraclyChrome.goldHighlight.withValues(alpha: 0.72),
                    width: AppBorderWidth.thin,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(size * 0.04),
                  child: OraclyAssetImage(
                    assetPath: AppAssets.featureAstrology,
                    width: size,
                    height: size,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    fallback: Icon(
                      AppIcons.empty,
                      size: size * 0.42,
                      color: OraclyChrome.goldLight.withValues(alpha: 0.88),
                    ),
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
