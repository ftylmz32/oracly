/// OR-007 — Premium upgrade promotional banner for the home screen.
library;

import 'package:flutter/material.dart';

import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import '../../../shared/widgets/oracly_button.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import '../theme/home_architecture.dart';
import '../theme/home_focus.dart';
import '../theme/home_reward.dart';

/// Large premium upsell card — gold crown, cosmic particles, press animation.
class PremiumBanner extends StatefulWidget {
  const PremiumBanner({
    super.key,
    this.onExploreTap,
  });

  final VoidCallback? onExploreTap;

  static const String _title = "Premium'u keşfet";
  static const String _description = 'Daha sakin bir yansıma odası.';
  static const String _ctaLabel = "Premium'u keşfet";

  @override
  State<PremiumBanner> createState() => _PremiumBannerState();
}

class _PremiumBannerState extends State<PremiumBanner> {
  bool _pressed = false;

  void _handleExploreTap(BuildContext context) {
    if (widget.onExploreTap != null) {
      widget.onExploreTap!();
      return;
    }
    OraclyNavigationService.openPremium(context);
  }

  @override
  Widget build(BuildContext context) {
    final scope = HomeFocusScope.maybeOf(context);
    final glowMult = scope?.glowFor(HomeFocusZone.premium) ?? 1.0;
    final ambient = scope?.ambientCalm ?? 1.0;

    return OraclyPressable(
      onTap: () => _handleExploreTap(context),
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      scale: false,
      depth: false,
      opacity: false,
      child: Transform.translate(
        offset: Offset(0, HomeReward.depthCompress(_pressed)),
        child: AnimatedScale(
          scale: HomeReward.pressScale(_pressed),
          duration: _pressed ? HomeReward.press : HomeReward.release,
          curve: _pressed ? HomeReward.curve : HomeReward.releaseCurve,
          child: DecoratedBox(
          decoration: HomeArchitecture.embeddedPanel(
            radius: AppRadius.lg,
            proximity: HomeOrbProximity.medium,
            goldBorderAlpha: (0.26 * glowMult).clamp(0.16, 0.34),
            glowMult: glowMult,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.lg,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned.fill(
                  child: HomeArchitectureOverlay(
                    borderRadius: AppRadius.lg,
                    proximity: HomeOrbProximity.medium,
                    detail: HomeSurfaceDetail.rich,
                  ),
                ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.xxl + AppSpacing.lg,
                child: Opacity(
                  opacity: (0.55 * ambient).clamp(0.0, 1.0),
                  child: const _BannerSpeck(dim: true),
                ),
              ),
              Positioned(
                top: AppSpacing.lg,
                left: AppSpacing.md,
                child: Opacity(
                  opacity: (0.70 * ambient).clamp(0.0, 1.0),
                  child: const _BannerSpeck(),
                ),
              ),
              Positioned(
                bottom: AppSpacing.md,
                right: AppSpacing.xxl,
                child: Opacity(
                  opacity: (0.50 * ambient).clamp(0.0, 1.0),
                  child: const _BannerSpeck(dim: true),
                ),
              ),
              Positioned(
                right: AppSpacing.md,
                bottom: AppSpacing.xs,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gold.withValues(alpha: 0.14),
                        AppColors.goldGlow.withValues(alpha: 0.05),
                        AppColors.transparent,
                      ],
                    ),
                  ),
                  child: SizedBox(
                    width: AppSpacing.xxl + AppSpacing.xl,
                    height: AppSpacing.xxl + AppSpacing.xl,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          PremiumBanner._title,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.goldLight,
                            fontWeight: FontWeight.w700,
                            letterSpacing: AppFontSizes.letterWide / 2,
                          ),
                        ),
                        SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: EdgeInsets.only(
                            right: AppSpacing.xxl + AppSpacing.lg,
                          ),
                          child: Text(
                            PremiumBanner._description,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary.withValues(alpha: 0.82),
                              height: 1.55,
                              letterSpacing: 0.15,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: AppSpacing.lg),
                        OraclyButton(
                          text: PremiumBanner._ctaLabel,
                          size: OraclyButtonSize.small,
                          type: OraclyButtonType.secondary,
                          onPressed: () => _handleExploreTap(context),
                        ),
                      ],
                    ),
                    const Positioned(
                      right: -AppSpacing.xs,
                      bottom: -AppSpacing.md,
                      child: _PremiumCrownIllustration(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    ),
    );
  }
}

class _PremiumCrownIllustration extends StatelessWidget {
  const _PremiumCrownIllustration();

  static const double _size =
      AppSpacing.xxl + AppSpacing.xxl + AppSpacing.xl + AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.purpleGlow.withValues(alpha: 0.55),
                  AppColors.goldGlow.withValues(alpha: 0.12),
                  AppColors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.glowPurple.withValues(alpha: 0.45),
                  blurRadius: 28,
                ),
                BoxShadow(
                  color: AppColors.goldGlow.withValues(alpha: 0.35),
                  blurRadius: 16,
                ),
              ],
            ),
            child: SizedBox(
              width: _size - AppSpacing.xs,
              height: _size - AppSpacing.xs,
            ),
          ),
          const Positioned(
            top: AppSpacing.md,
            right: AppSpacing.sm,
            child: _CrownSparkle(size: 3),
          ),
          const Positioned(
            top: AppSpacing.xl,
            left: AppSpacing.md,
            child: _CrownSparkle(size: 2, dim: true),
          ),
          const Positioned(
            bottom: AppSpacing.xl,
            right: AppSpacing.md,
            child: _CrownSparkle(size: 2),
          ),
          const Positioned(
            bottom: AppSpacing.lg,
            left: AppSpacing.lg,
            child: _CrownSparkle(size: 2, dim: true),
          ),
          const Positioned(
            top: AppSpacing.lg,
            right: AppSpacing.xl,
            child: _CrownSparkle(size: 2, dim: true),
          ),
          const Positioned(
            top: AppSpacing.xs,
            left: AppSpacing.sm,
            child: _CrystalGem(size: 14),
          ),
          const Positioned(
            top: AppSpacing.md,
            right: AppSpacing.xs,
            child: _CrystalGem(size: 11, dim: true),
          ),
          const Positioned(
            bottom: AppSpacing.sm,
            left: AppSpacing.xs,
            child: _CrystalGem(size: 10, dim: true),
          ),
          const Positioned(
            bottom: AppSpacing.md,
            right: AppSpacing.sm,
            child: _CrystalGem(size: 13),
          ),
          const Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.lg,
            child: _BannerStar(size: 5),
          ),
          const Positioned(
            top: AppSpacing.lg + AppSpacing.xs,
            left: AppSpacing.xs,
            child: _BannerStar(size: 4, dim: true),
          ),
          const Positioned(
            bottom: AppSpacing.xs,
            right: AppSpacing.md,
            child: _BannerStar(size: 4),
          ),
          OraclyAssetImage(
            assetPath: AppAssets.premiumBannerCrown,
            width: _size - AppSpacing.xs,
            height: _size - AppSpacing.xs,
            fit: BoxFit.contain,
            fallback: DecoratedBox(
              decoration: BoxDecoration(boxShadow: AppShadows.goldGlow),
              child: Icon(
                Icons.workspace_premium_rounded,
                size: AppSpacing.xxl,
                color: AppColors.goldLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CrownSparkle extends StatelessWidget {
  const _CrownSparkle({required this.size, this.dim = false});

  final double size;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dim ? AppColors.goldGlow : AppColors.goldLight,
        boxShadow: dim
            ? null
            : [
                BoxShadow(
                  color: AppColors.goldLight.withValues(alpha: 0.55),
                  blurRadius: 6,
                ),
              ],
      ),
      child: SizedBox(width: size, height: size),
    );
  }
}

class _CrystalGem extends StatelessWidget {
  const _CrystalGem({
    required this.size,
    this.dim = false,
  });

  final double size;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.785398,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xsValue / 3),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dim
                ? [
                    AppColors.purpleLight.withValues(alpha: 0.75),
                    AppColors.purpleDark.withValues(alpha: 0.9),
                  ]
                : [
                    AppColors.purpleLight,
                    AppColors.purple,
                    AppColors.purpleDark,
                  ],
          ),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: dim ? 0.35 : 0.55),
            width: AppBorderWidth.hairline,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.glowPurple,
              blurRadius: 12,
            ),
          ],
        ),
        child: SizedBox(width: size, height: size),
      ),
    );
  }
}

class _BannerStar extends StatelessWidget {
  const _BannerStar({required this.size, this.dim = false});

  final double size;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: dim ? null : AppShadows.iconGlow,
      ),
      child: Icon(
        Icons.star_rounded,
        size: size,
        color: dim ? AppColors.goldGlow : AppColors.goldLight,
      ),
    );
  }
}

class _BannerSpeck extends StatelessWidget {
  const _BannerSpeck({this.dim = false});

  final bool dim;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dim ? AppColors.goldGlow : AppColors.goldLight,
        boxShadow: AppShadows.iconGlow,
      ),
      child: SizedBox(
        width: AppSpacing.xs / 2,
        height: AppSpacing.xs / 2,
      ),
    );
  }
}
