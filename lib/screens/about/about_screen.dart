/// OR-1120 — Application about screen.
library;

import 'package:flutter/material.dart';

import '../../core/brand/oracly_brand_mark.dart';
import '../../core/copy/transparency_copy.dart';
import '../../core/design_system/app_icons.dart';
import '../../core/design_system/oracly_header_action.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/premium/presentation/widgets/premium_background.dart';
import '../../features/premium/presentation/widgets/settings_tiles.dart';
import '../../core/theme/craftsmanship_rhythm.dart';
import '../../shared/widgets/oracly_entrance.dart';
import 'about_contact_email.dart';
import 'about_legal_section.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _version = '1.0.0';
  static const _build = 'OR-1120';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PremiumBackground(),
          CustomScrollView(
            physics: CraftsmanshipRhythm.scrollPhysics,
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.black.withValues(alpha: 0.45),
                leading: Align(
                  child: OraclyHeaderAction(
                    icon: AppIcons.back,
                    label: OraclyL10n.t(L10nKeys.back),
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
                title: Text(OraclyL10n.t(L10nKeys.about)),
                centerTitle: true,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      OraclyEntrance(
                        mode: OraclyEntranceMode.softScale,
                        child: const OraclyBrandMark(size: 88, forLauncher: true),
                      ),
                      OraclyEntrance.staggered(
                        index: 1,
                        child: Column(
                          children: [
                            SizedBox(height: AppSpacing.md),
                            Text(
                              'ORACLY',
                              style: AppTextStyles.logo,
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              OraclyL10n.t('about.version')
                                  .replaceAll('{version}', _version)
                                  .replaceAll('{build}', _build),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg),
                      OraclyEntrance(
                        child: SettingsSectionHeader(
                          title: OraclyL10n.t('about.mission'),
                        ),
                      ),
                      Text(
                        OraclyL10n.t('about.body'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.55,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        TransparencyCopy.aboutBoundary,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg),
                      SettingsSectionHeader(
                        title: OraclyL10n.t('about.contact'),
                      ),
                      const AboutContactEmail(),
                      SizedBox(height: AppSpacing.lg),
                      const AboutLegalSection(),
                      SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
