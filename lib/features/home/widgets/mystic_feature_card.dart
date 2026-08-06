/// OR-006 / OR-411 / OR-414 — Premium mystical feature card for the home grid.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/oracly_brand_signature.dart';
import '../../../core/widgets/oracly_signature_motifs.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import '../theme/home_architecture.dart';
import '../theme/home_composition.dart';
import '../theme/home_focus.dart';
import '../theme/home_reward.dart';

/// Dark glass feature tile — composition tier controls visual weight.
class MysticFeatureCard extends StatefulWidget {
  const MysticFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    this.iconAsset,
    this.onTap,
    this.compact = true,
    this.tier = HomeVisualTier.primary,
    this.focusZone,
  });

  final IconData icon;
  final String? iconAsset;
  final String title;
  final VoidCallback? onTap;
  final bool compact;
  final HomeVisualTier tier;
  final HomeFocusZone? focusZone;

  @override
  State<MysticFeatureCard> createState() => _MysticFeatureCardState();
}

class _MysticFeatureCardState extends State<MysticFeatureCard> {
  bool _pressed = false;

  static const _sizeScale = 1.75;
  static const _iconOrbBase = AppSpacing.xxl + AppSpacing.sm;

  bool get _isFeatured => widget.tier == HomeVisualTier.featured;

  double get _rewardIntensity => switch (widget.tier) {
        HomeVisualTier.featured => 1.0,
        HomeVisualTier.primary => 0.72,
        HomeVisualTier.whisper => 0.48,
      };

  double get _iconOrbSize {
    final base = _iconOrbBase * _sizeScale;
    return _isFeatured ? base * 1.04 : base;
  }

  void _handleTapDown() {
    if (widget.onTap == null) return;
    setState(() => _pressed = true);
    final zone = widget.focusZone;
    if (zone != null) {
      HomeFocusScope.maybeOf(context)?.onActivate(zone);
    }
  }

  void _handleTapUp() {
    if (!_pressed) return;
    setState(() => _pressed = false);
    HomeFocusScope.maybeOf(context)?.onRelease();
  }

  double get _iconSize => (AppSpacing.lg + AppSpacing.sm) * _sizeScale;

  EdgeInsets get _padding {
    if (_isFeatured) {
      return EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      );
    }
    return widget.compact
        ? EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + AppSpacing.xs,
            vertical: AppSpacing.md + AppSpacing.sm,
          )
        : EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg + AppSpacing.sm,
          );
  }

  double get _iconDisplaySize => _iconOrbSize * 0.84;

  bool get _showCosmicSpecks => widget.tier != HomeVisualTier.whisper;

  Widget _buildFeatureIcon() {
    if (widget.iconAsset != null) {
      return OraclyAssetImage(
        assetPath: widget.iconAsset!,
        width: _iconDisplaySize,
        height: _iconDisplaySize,
        fit: BoxFit.contain,
        fallback: Icon(
          widget.icon,
          size: _iconSize,
          color: AppColors.gold,
        ),
      );
    }

    return Icon(
      widget.icon,
      size: _iconSize,
      color: AppColors.gold,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = HomeFocusScope.maybeOf(context);
    final zone = widget.focusZone;
    final glowMult = zone != null && scope != null
        ? scope.glowFor(zone)
        : 1.0;

    final borderAlpha =
        (HomeComposition.tierBorderAlpha(widget.tier) * glowMult).clamp(0.0, 0.72);
    final goldGlowAlpha =
        (HomeComposition.tierGoldGlowAlpha(widget.tier) * glowMult).clamp(0.0, 0.42);
    final tierScale = HomeComposition.tierScale(widget.tier);
    final pressedGlow = _pressed ? 1.03 : 1.0;
    final proximity = HomeArchitecture.proximityFor(widget.focusZone);
    final surfaceDetail = switch (widget.tier) {
      HomeVisualTier.featured => HomeSurfaceDetail.rich,
      HomeVisualTier.primary => HomeSurfaceDetail.standard,
      HomeVisualTier.whisper => HomeSurfaceDetail.whisper,
    };
    final goldBorder = (borderAlpha * pressedGlow).clamp(0.12, 0.58);
    final depth = HomeReward.depthCompress(_pressed);
    final scale = HomeReward.pressScale(_pressed, featured: _isFeatured) * tierScale;

    return GestureDetector(
      onTapDown: (_) => _handleTapDown(),
      onTapUp: (_) => _handleTapUp(),
      onTapCancel: _handleTapUp,
      onTap: () {
        if (widget.onTap != null) {
          OraclyTouchFeedback.acknowledge();
          widget.onTap!();
        }
      },
      child: ColorFiltered(
        colorFilter: ColorFilter.matrix(
          HomeFocus.visualMatrix(
            contrast: 1,
            opacity: _pressed ? OraclySignatureMotion.pressOpacity : 1,
          ),
        ),
        child: Transform.translate(
          offset: Offset(0, depth),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: AnimatedContainer(
          duration: _pressed ? HomeReward.press : HomeReward.release,
          curve: _pressed ? HomeReward.curve : HomeReward.releaseCurve,
          decoration: HomeArchitecture.embeddedPanel(
            radius: AppRadius.md,
            proximity: proximity,
            goldBorderAlpha: goldBorder,
            glowMult: glowMult * (_pressed ? 1.03 : 1.0),
          ).copyWith(
            boxShadow: _pressed
                ? [
                    ...HomeArchitecture.embeddedShadows(
                      proximity: proximity,
                      glowMult: glowMult,
                    ),
                    BoxShadow(
                      color: AppColors.goldGlow.withValues(
                        alpha: 0.05 * _rewardIntensity,
                      ),
                      blurRadius: 18,
                      spreadRadius: -3,
                      offset: const Offset(0, -1),
                    ),
                  ]
                : HomeArchitecture.embeddedShadows(
                    proximity: proximity,
                    glowMult: glowMult,
                  ),
          ),
          child: ClipRRect(
            borderRadius: AppRadius.md,
            child: Stack(
              children: [
                Positioned.fill(
                  child: HomeArchitectureOverlay(
                    borderRadius: AppRadius.md,
                    proximity: proximity,
                    detail: surfaceDetail,
                  ),
                ),
                if (_pressed)
                  Positioned.fill(
                    child: HomeCrystalShimmerOverlay(
                      phase: 0.5,
                      borderRadius: AppRadius.md,
                      intensity: _rewardIntensity * 0.72,
                    ),
                  ),
                const OraclySignatureCornerOrnaments(
                  inset: 6,
                  size: 10,
                ),
                Padding(
                  padding: _padding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: _iconOrbSize,
                        height: _iconOrbSize,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            if (_showCosmicSpecks) ...[
                              const _CosmicSpeck(
                                top: AppSpacing.xs,
                                left: AppSpacing.sm,
                              ),
                              const _CosmicSpeck(
                                bottom: AppSpacing.sm,
                                right: AppSpacing.xs,
                                dim: true,
                              ),
                              const _CosmicSpeck(
                                top: AppSpacing.md,
                                right: AppSpacing.sm,
                              ),
                            ],
                            DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppGradients.matteSurface,
                                border: Border.all(
                                  color: AppColors.gold.withValues(
                                    alpha: borderAlpha + 0.12,
                                  ),
                                  width: AppBorderWidth.thin,
                                ),
                                boxShadow: widget.tier == HomeVisualTier.whisper
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: AppColors.goldGlow.withValues(
                                            alpha: goldGlowAlpha + 0.28,
                                          ),
                                          blurRadius: AppShadowMetrics.goldBlur,
                                          spreadRadius:
                                              AppShadowMetrics.goldSpread / 2,
                                        ),
                                      ],
                              ),
                              child: SizedBox(
                                width: _iconOrbSize,
                                height: _iconOrbSize,
                                child: Center(child: _buildFeatureIcon()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: _isFeatured ? AppSpacing.sm : AppSpacing.xs,
                      ),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: (widget.compact
                                ? AppTextStyles.labelMedium
                                : AppTextStyles.titleSmall)
                            .copyWith(
                          color: AppColors.goldLight.withValues(
                            alpha: widget.tier == HomeVisualTier.whisper
                                ? 0.82
                                : 0.94,
                          ),
                          fontWeight: FontWeight.w600,
                          height: 1.32,
                          letterSpacing: 0.2,
                        ),
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
      ),
    );
  }
}

class _CosmicSpeck extends StatelessWidget {
  const _CosmicSpeck({
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.dim = false,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dim ? AppColors.goldGlow : AppColors.goldLight,
        ),
        child: SizedBox(
          width: AppSpacing.xs / 2,
          height: AppSpacing.xs / 2,
        ),
      ),
    );
  }
}
