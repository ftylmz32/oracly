/// Flagship OR CTA - canonical /chat only.
library;

import 'package:flutter/material.dart';

import '../../../core/accessibility/oracly_a11y.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/modules/oracly_feature_id.dart';
import '../../../core/modules/oracly_feature_navigation.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import 'home_reference_card_shell.dart';
import 'home_reference_or_emblem_well.dart';
import 'home_reference_or_flagship_copy.dart';
import 'home_reference_or_flagship_cta.dart';
import 'home_living_sweep.dart';
import 'home_reference_tokens.dart';

class HomeReferenceOrFlagship extends StatelessWidget {
  const HomeReferenceOrFlagship({super.key, this.height = 132});

  final double height;

  static String get title => OraclyL10n.t('home.or_flagship.title');
  static String get body => OraclyL10n.t('home.or_flagship.body');
  static String get cta => OraclyL10n.t('home.or_flagship.cta');

  void _open(BuildContext context) =>
      OraclyFeatureNavigation.open(context, OraclyFeatureId.aiChat);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $body. $cta',
      child: HomeReferenceCardShell(
        height: height,
        premium: true,
        glowStrength: 1.28,
        borderRadius: HomeReferenceTokens.orGuideRadius,
        padding: EdgeInsets.zero,
        onTap: () => _open(context),
        child: ClipRRect(
          borderRadius: HomeReferenceTokens.orGuideRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const RepaintBoundary(
                child: OraclyAssetImage(
                  assetPath: AppAssets.homeOrGuide,
                  fit: BoxFit.cover,
                  alignment: Alignment(0.62, -0.08),
                  cacheCapPx: 640,
                  fallback: ColoredBox(color: Color(0xFF140A28)),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xE605030C),
                      Color(0xCC0A0618),
                      Color(0x99140A28),
                      Color(0x33140A28),
                      Color(0x1405030C),
                    ],
                    stops: [0.0, 0.34, 0.58, 0.82, 1.0],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      OraclyChrome.violet.withValues(alpha: 0.10),
                      Colors.transparent,
                      OraclyChrome.midnight.withValues(alpha: 0.36),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              const HomeLivingSweep(seed: 11, intensity: 0.07),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: OraclyA11y.chromeTextScale(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const HomeReferenceOrEmblemWell(),
                      const SizedBox(width: 14),
                      Expanded(
                        child: HomeReferenceOrFlagshipCopy(
                          title: title,
                          body: body,
                        ),
                      ),
                      const SizedBox(width: 10),
                      HomeReferenceOrFlagshipCta(
                        label: cta,
                        onTap: () => _open(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
