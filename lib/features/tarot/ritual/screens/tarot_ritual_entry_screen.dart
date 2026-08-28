/// Phase 1 — Tarot entry. No question/spread here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/oracly_asset_image.dart';
import '../../../../shared/widgets/oracly_button.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../shared/constants/tarot_routes.dart';
import '../../theme/tarot_tokens.dart';

class TarotRitualEntryScreen extends ConsumerWidget {
  const TarotRitualEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OraclyScaffold(
      child: SafeArea(
        child: Padding(
          padding: TarotTokens.screenPadding,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.gold.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const Spacer(flex: 1),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AspectRatio(
                  aspectRatio: 0.85,
                  child: OraclyAssetImage(
                    assetPath: AppAssets.tarotHero,
                    fit: BoxFit.cover,
                    fallback: ColoredBox(
                      color: const Color(0xFF0A0714),
                      child: Icon(
                        Icons.auto_awesome,
                        color: AppColors.gold.withValues(alpha: 0.5),
                        size: 64,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Tarot',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Kartlar sessizce dinler. Sen niyetini getirirsin.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
              ),
              const Spacer(flex: 2),
              OraclyButton(
                text: "Tarot'a Başla",
                isExpanded: true,
                onPressed: () {
                  OraclyNavigationService.openTarotModuleRoute(
                    context,
                    TarotRoutes.intention,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () {
                  OraclyNavigationService.openTarotModuleRoute(
                    context,
                    TarotRoutes.history,
                  );
                },
                child: Text(
                  'Geçmiş okumalar',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.gold.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
