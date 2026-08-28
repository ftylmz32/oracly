/// SPRINT-005 — Registry-driven feature launcher for the home portal.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/micro_details/micro_details.dart';
import '../../../core/modules/oracly_feature_l10n.dart';
import '../../../core/modules/oracly_feature_module.dart';
import '../../../core/modules/oracly_feature_navigation.dart';
import '../../../core/modules/oracly_feature_registry.dart';
import '../../../core/navigation/universe/universe_navigation_copy.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/oracly_signature_motifs.dart';
import '../theme/home_composition.dart';
import '../theme/home_focus.dart';
import '../theme/home_atmosphere.dart';
import 'mystic_feature_card.dart';

/// Universe band launcher — composition driven by [OraclyFeatureRegistry].
class MysticFeatureGrid extends StatelessWidget {
  const MysticFeatureGrid({
    super.key,
    this.band = HomeCompositionBand.understand,
    this.entranceDelayMs = 0,
  });

  final HomeCompositionBand band;
  final int entranceDelayMs;

  HomeFocusZone get _zone => HomeFocus.zoneForBand(band);

  String get _bandKey => switch (band) {
        HomeCompositionBand.explore => 'explore',
        HomeCompositionBand.reflect => 'reflect',
        HomeCompositionBand.understand => 'understand',
      };

  String get _sectionLabel => switch (band) {
        HomeCompositionBand.explore => UniverseNavigationCopy.bandExplore,
        HomeCompositionBand.reflect => UniverseNavigationCopy.bandReflect,
        HomeCompositionBand.understand => UniverseNavigationCopy.bandUnderstand,
      };

  HomeVisualTier get _defaultTier => switch (band) {
        HomeCompositionBand.explore => HomeVisualTier.featured,
        HomeCompositionBand.reflect => HomeVisualTier.primary,
        HomeCompositionBand.understand => HomeVisualTier.whisper,
      };

  @override
  Widget build(BuildContext context) {
    final modules = OraclyFeatureRegistry.forHomeBand(_bandKey);
    if (modules.isEmpty) return const SizedBox.shrink();

    final scope = HomeFocusScope.of(context);
    final labelGlow = scope.glowFor(_zone);
    final isTertiaryLabel = HomeFocus.tierFor(_zone) == HomeFocusTier.tertiary;
    final labelBase = HomeAtmosphere.temper(
      AppColors.textSecondary,
      _zone,
      strength: 0.14,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.zero,
          child: AnimatedOpacity(
            opacity: isTertiaryLabel
                ? (0.62 + labelGlow * 0.22).clamp(0.0, 1.0)
                : (0.78 + labelGlow * 0.18).clamp(0.0, 1.0),
            duration: HomeFocus.transition,
            curve: HomeFocus.curve,
            child: Text(
              _sectionLabel,
              style: AppTextStyles.labelMedium.copyWith(
                color: labelBase.withValues(
                  alpha: band == HomeCompositionBand.understand ? 0.64 : 0.74,
                ),
                letterSpacing: AppFontSizes.letterWide / 2,
                height: 1.35,
              ),
            ),
          ),
        ),
        const OraclySignatureDivider(compact: true),
        SizedBox(height: HomeComposition.labelToContent - AppSpacing.xs),
        _ModuleRow(
          modules: modules,
          band: band,
          focusZone: _zone,
          defaultTier: _defaultTier,
          entranceDelayMs: entranceDelayMs,
        ),
      ],
    );
  }
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({
    required this.modules,
    required this.band,
    required this.focusZone,
    required this.defaultTier,
    required this.entranceDelayMs,
  });

  final List<OraclyFeatureModule> modules;
  final HomeCompositionBand band;
  final HomeFocusZone focusZone;
  final HomeVisualTier defaultTier;
  final int entranceDelayMs;

  @override
  Widget build(BuildContext context) {
    if (band == HomeCompositionBand.understand) {
      final row = modules.take(3).toList();
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < row.length; i++) ...[
            if (i > 0) SizedBox(width: HomeComposition.tileGap),
            Expanded(
              child: MicroListReveal(
                index: i,
                baseDelay: Duration(milliseconds: entranceDelayMs),
                child: _ModuleTile(module: row[i], focusZone: focusZone),
              ),
            ),
          ],
        ],
      );
    }

    final module = modules.first;
    return MicroListReveal(
      index: 0,
      baseDelay: Duration(milliseconds: entranceDelayMs),
      child: MysticFeatureCard(
        icon: module.icon ?? Icons.auto_awesome,
        iconAsset: module.iconAsset,
        title: module.labeled,
        compact: false,
        tier: defaultTier,
        focusZone: focusZone,
        onTap: () => OraclyFeatureNavigation.open(context, module.id),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.module,
    required this.focusZone,
  });

  final OraclyFeatureModule module;
  final HomeFocusZone focusZone;

  @override
  Widget build(BuildContext context) {
    return MysticFeatureCard(
      icon: module.icon ?? Icons.auto_awesome,
      iconAsset: module.iconAsset,
      title: module.labeled,
      tier: HomeVisualTier.whisper,
      focusZone: focusZone,
      onTap: () => OraclyFeatureNavigation.open(context, module.id),
    );
  }
}
