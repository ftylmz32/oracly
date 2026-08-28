/// Premium banner artwork + left reading scrim.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import 'home_living_sweep.dart';

class HomeReferencePremiumArt extends StatelessWidget {
  const HomeReferencePremiumArt({super.key, required this.crownSize});

  final double crownSize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF05030C)),
        Align(
          alignment: Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: 0.62,
            heightFactor: 1,
            child: RepaintBoundary(
              child: OraclyAssetImage(
                assetPath: AppAssets.homePremium,
                fit: BoxFit.cover,
                alignment: const Alignment(0.22, -0.04),
                cacheCapPx: 640,
                fallback: Icon(
                  Icons.workspace_premium_rounded,
                  color: OraclyChrome.goldLight.withValues(alpha: 0.86),
                  size: crownSize,
                ),
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                OraclyChrome.midnight.withValues(alpha: 0.97),
                OraclyChrome.midnight.withValues(alpha: 0.88),
                OraclyChrome.midnight.withValues(alpha: 0.42),
                OraclyChrome.midnight.withValues(alpha: 0.08),
                Colors.transparent,
              ],
              stops: const [0.0, 0.28, 0.5, 0.7, 0.9],
            ),
          ),
        ),
        const HomeLivingSweep(seed: 29, intensity: 0.08),
      ],
    );
  }
}
