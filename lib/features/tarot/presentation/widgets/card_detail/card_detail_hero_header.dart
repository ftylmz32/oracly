/// OR-1080 — Parallax hero header with card art and actions.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'card_detail_models.dart';

class CardDetailHeroHeader extends StatelessWidget {
  const CardDetailHeroHeader({
    super.key,
    required this.content,
    required this.scrollOffset,
    required this.isFavorite,
    required this.onBack,
    required this.onFavorite,
    required this.onShare,
  });

  final CardDetailContent content;
  final double scrollOffset;
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onFavorite;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final parallax = scrollOffset * 0.35;
    final scale = (1 - (scrollOffset / 900).clamp(0.0, 0.12));

    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.translate(
          offset: Offset(0, parallax),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: Hero(
              tag: content.heroTag,
              child: Image.asset(
                content.imageAsset,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: AppColors.purpleDark,
                  child: Icon(
                    Icons.style_rounded,
                    size: 80,
                    color: content.accentColor,
                  ),
                ),
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.15),
                Colors.black.withValues(alpha: 0.35),
                AppColors.background.withValues(alpha: 0.92),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: const SizedBox.expand(),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                _GlassIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: onBack,
                ),
                const Spacer(),
                _GlassIconButton(
                  icon: isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  onTap: onFavorite,
                  active: isFavorite,
                ),
                SizedBox(width: AppSpacing.sm),
                _GlassIconButton(
                  icon: Icons.ios_share_rounded,
                  onTap: onShare,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.lg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content.displayNameTr,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                content.name,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.round,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Material(
          color: AppColors.surface.withValues(alpha: 0.55),
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: active
                      ? AppColors.gold.withValues(alpha: 0.65)
                      : AppColors.gold.withValues(alpha: 0.28),
                  width: AppBorderWidth.hairline,
                ),
              ),
              child: Icon(
                icon,
                size: AppSpacing.lg,
                color: active ? AppColors.gold : AppColors.goldLight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
