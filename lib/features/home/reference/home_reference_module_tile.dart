/// Image-first Home discovery portal — doorway, not a normal app card.
library;

import 'package:flutter/material.dart';

import '../../../core/accessibility/oracly_a11y.dart';
import '../../../core/copy/preview_capability_copy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/modules/oracly_feature_id.dart';
import '../../../core/modules/oracly_feature_navigation.dart';
import '../../../core/modules/oracly_feature_registry.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/craftsmanship_rhythm.dart';
import '../../../core/theme/reading_typography.dart';
import '../copy/home_discovery_copy.dart';
import 'home_discovery_module_arts.dart';
import 'home_discovery_portal.dart';
import 'home_discovery_tile_chrome.dart';
import 'home_module_visual.dart';
import 'home_reference_tokens.dart';

class HomeReferenceModuleSpec {
  const HomeReferenceModuleSpec({
    required this.id,
    required this.visual,
    this.premiumMark = false,
    this.isNew = false,
  });

  final OraclyFeatureId id;
  final HomeModuleVisual visual;
  final bool premiumMark;
  final bool isNew;
}

class HomeReferenceModuleTile extends StatelessWidget {
  const HomeReferenceModuleTile({super.key, required this.spec});

  final HomeReferenceModuleSpec spec;

  @override
  Widget build(BuildContext context) {
    final title = HomeDiscoveryCopy.title(spec.id);
    final icon = HomeDiscoveryModuleArt.iconFor(spec.visual);
    final showPreview =
        OraclyFeatureRegistry.byId(spec.id)?.isPreview ?? false;

    return Semantics(
      button: true,
      label: HomeDiscoveryCopy.semantics(spec.id),
      child: HomeDiscoveryPortal(
        borderRadius: HomeReferenceTokens.moduleRadius,
        onTap: () => OraclyFeatureNavigation.open(context, spec.id),
        art: HomeDiscoveryModuleArt(visual: spec.visual),
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x08000000),
                      Color(0x00000000),
                      Color(0x66080514),
                      Color(0xC002030A),
                    ],
                    stops: [0.0, 0.38, 0.68, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 7,
              left: 7,
              child: HomeDiscoveryIdentityIcon(icon: icon),
            ),
            if (showPreview)
              Positioned(
                top: 7,
                right: 7,
                child: HomeDiscoveryNewBadge(
                  label: PreviewCapabilityCopy.badge,
                ),
              )
            else if (spec.isNew)
              Positioned(
                top: 7,
                right: 7,
                child: HomeDiscoveryNewBadge(
                  label: OraclyL10n.t('home.discovery.new'),
                ),
              )
            else if (spec.premiumMark)
              Positioned(
                top: 7,
                right: 7,
                child: Icon(
                  Icons.workspace_premium_rounded,
                  size: 12,
                  color: AppColors.goldLight.withValues(alpha: 0.82),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
              child: LayoutBuilder(
                builder: (context, box) {
                  if (box.maxHeight < 14) return const SizedBox.shrink();
                  final showEnter = box.maxHeight >= 52;
                  return Align(
                    alignment: Alignment.bottomLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: box.maxWidth),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ReadingTypography.sectionTitle(
                                fontSize: HomeReferenceTokens.moduleTitleSize,
                              ).copyWith(
                                letterSpacing:
                                    CraftsmanshipRhythm.labelTracking,
                                height: 1.05,
                                fontWeight: FontWeight.w700,
                                color: OraclyA11y.goldReadable(
                                  AppColors.goldLight,
                                ),
                              ),
                            ),
                            if (showEnter) ...[
                              const SizedBox(height: 3),
                              const HomeDiscoveryEnterMark(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
