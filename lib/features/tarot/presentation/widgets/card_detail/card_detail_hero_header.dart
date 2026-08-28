/// OR-1080 — Parallax hero header with card art and actions.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/design_system/app_icons.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../art/tarot_major_card_art.dart';
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
              child: TarotMajorCardArt(
                imageAsset: content.imageAsset,
                preview: false,
                fallback: ColoredBox(
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
                  icon: AppIcons.back,
                  onTap: onBack,
                  semanticsLabel: OraclyL10n.t(L10nKeys.back),
                ),
                const Spacer(),
                _GlassIconButton(
                  icon: isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  onTap: onFavorite,
                  active: isFavorite,
                  semanticsLabel: OraclyL10n.t('tarot.action.favorite'),
                ),
                SizedBox(width: AppSpacing.sm),
                _GlassIconButton(
                  icon: Icons.ios_share_rounded,
                  onTap: onShare,
                  semanticsLabel: OraclyL10n.t('tarot.action.share'),
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
                content.displayName,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                OraclyL10n.t('tarot.arcana.major'),
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
    required this.semanticsLabel,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticsLabel;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: ClipRRect(
        borderRadius: AppRadius.round,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Material(
            color: AppColors.surface.withValues(alpha: 0.55),
            child: InkWell(
              onTap: onTap,
              child: Container(
                width: 44,
                height: 44,
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
      ),
    );
  }
}
