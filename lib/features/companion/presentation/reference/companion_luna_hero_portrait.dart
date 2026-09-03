/// Luna hero portrait — soft-edge cinematic likeness over violet nebula.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../shared/widgets/oracly_asset_image.dart';

class CompanionLunaHeroPortrait extends StatelessWidget {
  const CompanionLunaHeroPortrait({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.08, -0.18),
              radius: 1.12,
              colors: [
                OraclyChrome.violet.withValues(alpha: 0.28),
                OraclyChrome.violetSoft.withValues(alpha: 0.12),
                Colors.transparent,
              ],
              stops: const [0.0, 0.42, 1.0],
            ),
          ),
        ),
        ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) {
            return const RadialGradient(
              center: Alignment(-0.28, -0.12),
              radius: 1.08,
              colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
              stops: [0.0, 0.72, 1.0],
            ).createShader(rect);
          },
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: const [
                  Color(0xFFFFFFFF),
                  Color(0xFFFFFFFF),
                  Color(0x00FFFFFF),
                ],
                stops: const [0.0, 0.84, 1.0],
              ).createShader(rect);
            },
            child: OraclyAssetImage(
              assetPath: AppAssets.lunaPortraitHero,
              fit: BoxFit.cover,
              alignment: const Alignment(-0.20, -0.28),
              fallback: ColoredBox(
                color: OraclyChrome.violet.withValues(alpha: 0.22),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: OraclyChrome.goldLight.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFF08050D),
                  const Color(0xFF08050D).withValues(alpha: 0.72),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.14, 0.42],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
