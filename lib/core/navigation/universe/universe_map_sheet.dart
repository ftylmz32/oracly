/// SPRINT-005 — Universe map — where every experience lives.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../modules/oracly_feature_l10n.dart';
import '../../modules/oracly_feature_navigation.dart';
import '../../modules/oracly_feature_registry.dart';
import '../../navigation/universe/oracly_universe_realm.dart';
import '../../navigation/universe/universe_navigation_copy.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/reading_typography.dart';
import '../../../core/l10n/l10n.dart';
import '../../../shared/navigation/oracly_navigation.dart';
import 'oracly_tab_labels.dart';

/// Opens the universe map — structural guide, not a new module.
abstract final class UniverseMapSheet {
  UniverseMapSheet._();

  static Future<void> open(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _UniverseMapBody(),
    );
  }
}

class _UniverseMapBody extends ConsumerWidget {
  const _UniverseMapBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = AppLocale.normalize(
      ref.watch(appLocaleProvider).languageCode,
    );
    final bottom = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg + bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              UniverseNavigationCopy.mapTitle,
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.goldLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              UniverseNavigationCopy.mapIntro,
              style: ReadingTypography.bodySmall(),
            ),
            SizedBox(height: AppSpacing.lg),
            _TabSpacesSection(
              languageCode: lang,
              onNavigate: () => Navigator.pop(context),
            ),
            SizedBox(height: AppSpacing.lg),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final realm in _mapRealms)
                      _RealmSection(
                        realm: realm,
                        onNavigate: () => Navigator.pop(context),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _mapRealms = [
  OraclyUniverseRealm.explore,
  OraclyUniverseRealm.reflect,
  OraclyUniverseRealm.understand,
  OraclyUniverseRealm.remember,
  OraclyUniverseRealm.grow,
];

class _TabSpacesSection extends StatelessWidget {
  const _TabSpacesSection({
    required this.onNavigate,
    required this.languageCode,
  });

  final VoidCallback onNavigate;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ana mekânlar',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textHint,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final tab in OraclyTab.values)
              ActionChip(
                label: Text(tab.labeled(languageCode)),
                avatar: Icon(
                  _tabIcon(tab),
                  size: 16,
                  color: AppColors.goldLight,
                ),
                onPressed: () {
                  onNavigate();
                  OraclyNavigation.switchToTab(context, tab);
                },
              ),
          ],
        ),
      ],
    );
  }

  IconData _tabIcon(OraclyTab tab) => switch (tab) {
        OraclyTab.home => Icons.home_rounded,
        OraclyTab.coffee => Icons.auto_awesome_rounded,
        OraclyTab.astrology => Icons.explore_rounded,
        OraclyTab.starMap => Icons.menu_book_rounded,
        OraclyTab.profile => Icons.person_rounded,
      };
}

class _RealmSection extends StatelessWidget {
  const _RealmSection({
    required this.realm,
    required this.onNavigate,
  });

  final OraclyUniverseRealm realm;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final modules = OraclyFeatureRegistry.forRealm(realm);
    if (modules.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _realmTitle(realm),
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.goldLight.withValues(alpha: 0.85),
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            _realmHint(realm),
            style: ReadingTypography.footnote(),
          ),
          SizedBox(height: AppSpacing.sm),
          for (final module in modules)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                module.icon ?? Icons.auto_awesome_outlined,
                color: AppColors.textSecondary,
              ),
              title: Text(module.labeled),
              subtitle: module.labeledSubtitle != null
                  ? Text(module.labeledSubtitle!)
                  : null,
              onTap: () {
                onNavigate();
                OraclyFeatureNavigation.open(context, module.id);
              },
            ),
        ],
      ),
    );
  }

  String _realmTitle(OraclyUniverseRealm realm) => switch (realm) {
        OraclyUniverseRealm.portal => UniverseNavigationCopy.realmPortal,
        OraclyUniverseRealm.explore => UniverseNavigationCopy.realmExplore,
        OraclyUniverseRealm.reflect => UniverseNavigationCopy.realmReflect,
        OraclyUniverseRealm.understand => UniverseNavigationCopy.realmUnderstand,
        OraclyUniverseRealm.remember => UniverseNavigationCopy.realmRemember,
        OraclyUniverseRealm.grow => UniverseNavigationCopy.realmGrow,
        OraclyUniverseRealm.account => UniverseNavigationCopy.sectionAccount,
      };

  String _realmHint(OraclyUniverseRealm realm) => switch (realm) {
        OraclyUniverseRealm.portal => UniverseNavigationCopy.realmPortalHint,
        OraclyUniverseRealm.explore => UniverseNavigationCopy.realmExploreHint,
        OraclyUniverseRealm.reflect => UniverseNavigationCopy.realmReflectHint,
        OraclyUniverseRealm.understand =>
          UniverseNavigationCopy.realmUnderstandHint,
        OraclyUniverseRealm.remember => UniverseNavigationCopy.realmRememberHint,
        OraclyUniverseRealm.grow => UniverseNavigationCopy.realmGrowHint,
        OraclyUniverseRealm.account => UniverseNavigationCopy.sectionAccountHint,
      };
}
