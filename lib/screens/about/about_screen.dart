/// OR-1120 — Application about screen.
library;

import 'package:flutter/material.dart';

import '../../core/copy/transparency_copy.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/premium/presentation/widgets/premium_background.dart';
import '../../features/premium/presentation/widgets/settings_tiles.dart';

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
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.black.withValues(alpha: 0.45),
                leading: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                title: const Text('Hakkında'),
                centerTitle: true,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.45),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.goldGlow.withValues(alpha: 0.25),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          size: 40,
                          color: AppColors.goldLight,
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        'ORACLY',
                        style: AppTextStyles.logo,
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'Sürüm $_version · $_build',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg),
                      const SettingsSectionHeader(title: 'Misyon'),
                      Text(
                        'ORACLY, tarot, rüya, astroloji ve günlük enerji '
                        'rehberliğini tek bir sakin deneyimde birleştirir. '
                        'OR AI ile kişisel yolculuğuna eşlik eder.',
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
                      const SettingsSectionHeader(title: 'İletişim'),
                      Text(
                        'destek@oracly.app',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.gold,
                        ),
                      ),
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
