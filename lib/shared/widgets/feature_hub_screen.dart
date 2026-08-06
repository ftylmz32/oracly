/// OR-1120 — Reusable feature hub layout.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/home/widgets/home_cinematic_background.dart';
import '../../shared/widgets/oracly_button.dart';
import '../../shared/widgets/oracly_scaffold.dart';

class FeatureHubScreen extends StatelessWidget {
  const FeatureHubScreen({
    super.key,
    required this.title,
    required this.headline,
    required this.description,
    required this.icon,
    this.iconAsset,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.body,
  });

  final String title;
  final String headline;
  final String description;
  final IconData icon;
  final String? iconAsset;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    return OraclyScaffold(
      backgroundOverlay: const HomeCosmicBackground(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(title),
        centerTitle: true,
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: AppSpacing.screenHorizontal.copyWith(
          top: AppSpacing.md,
          bottom: AppSpacing.xxl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.xl,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.surfaceElevated.withValues(alpha: 0.92),
                        AppColors.surface.withValues(alpha: 0.86),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, size: 40, color: AppColors.goldLight),
                        SizedBox(height: AppSpacing.md),
                        Text(
                          headline,
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: AppColors.goldLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (body != null) ...[
                  SizedBox(height: AppSpacing.lg),
                  body!,
                ],
                if (primaryLabel != null && onPrimary != null) ...[
                  SizedBox(height: AppSpacing.lg),
                  OraclyButton(
                    text: primaryLabel!,
                    isExpanded: true,
                    onPressed: onPrimary,
                  ),
                ],
                if (secondaryLabel != null && onSecondary != null) ...[
                  SizedBox(height: AppSpacing.sm),
                  OraclyButton(
                    text: secondaryLabel!,
                    type: OraclyButtonType.secondary,
                    isExpanded: true,
                    onPressed: onSecondary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
