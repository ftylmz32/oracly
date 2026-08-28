/// Hub plate layers — hero art, sign portal, polished ring.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../shared/widgets/oracly_asset_image.dart';
import 'astrology_sign_light_sweep.dart';
import 'astrology_sign_transition.dart';
import 'astrology_supported_sky.dart';
import 'astrology_zodiac_illustration.dart';
import 'astrology_zodiac_ring.dart';

class AstrologyHubWheelPlate extends StatelessWidget {
  const AstrologyHubWheelPlate({
    super.key,
    required this.signId,
    required this.plate,
    required this.portal,
    required this.sky,
    required this.phase,
  });

  final String signId;
  final double plate;
  final double portal;
  final AstrologySupportedSky sky;
  final double phase;

  @override
  Widget build(BuildContext context) {
    final pulse = 0.18 + (phase - 0.5).abs() * 0.12;
    return Stack(
      alignment: Alignment.center,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: OraclyChrome.gold.withValues(alpha: 0.16 + pulse),
                blurRadius: 26 + pulse * 20,
              ),
              BoxShadow(
                color: OraclyChrome.violet.withValues(alpha: 0.22 + pulse * 0.4),
                blurRadius: 40,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SizedBox(width: plate, height: plate),
        ),
        SizedBox(
          width: plate,
          height: plate,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: OraclyChrome.midnight),
                    const OraclyAssetImage(
                      assetPath: AppAssets.astrologyHeroWheel,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                      fallback: SizedBox.expand(),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.15),
                          radius: 0.95,
                          colors: [
                            Colors.transparent,
                            OraclyChrome.midnight.withValues(alpha: 0.16),
                            OraclyChrome.midnight.withValues(alpha: 0.40),
                          ],
                          stops: const [0.42, 0.72, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: portal,
                height: portal,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: OraclyChrome.goldLight.withValues(alpha: 0.58),
                      width: 1.25,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: OraclyChrome.gold
                            .withValues(alpha: 0.16 + pulse * 0.5),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AstrologySignTransition(
                          signId: signId,
                          scaleFrom: 0.94,
                          child: AstrologyZodiacIllustration(
                            signId: signId,
                            size: portal,
                          ),
                        ),
                        AstrologySignLightSweep(signId: signId),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: AstrologySignTransition(
                  signId: signId,
                  scaleFrom: 0.985,
                  child: CustomPaint(
                    painter:
                        AstrologyZodiacRingPainter(sky: sky, phase: phase),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
