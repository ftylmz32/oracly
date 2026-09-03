/// OR-1190 — Oracle conversation header with animated OR orb.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_icons.dart';
import '../../../../core/design_system/oracly_header_action.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../oracle_conversation/models/oracle_reading_context.dart';
import 'oracle_avatar.dart';

class OracleConversationHeader extends StatelessWidget {
  const OracleConversationHeader({
    super.key,
    required this.context,
    this.onBack,
  });

  final OracleReadingContext context;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final reading = this.context;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.78),
            border: Border(
              bottom: BorderSide(
                color: AppColors.gold.withValues(alpha: 0.18),
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  OraclyHeaderAction(
                    icon: AppIcons.back,
                    label: OraclyL10n.t(L10nKeys.back),
                    onTap: onBack ?? () => Navigator.of(context).maybePop(),
                  ),
                  const OracleAvatar(size: 44, showGlow: true),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reading.sourceLabel.isEmpty
                              ? OraclyL10n.t('oracle.header.current')
                              : reading.sourceLabel,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textMuted,
                            letterSpacing: 0.6,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          reading.readingTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            _MetaChip(
                              icon: Icons.style_rounded,
                              label: reading.deckName,
                            ),
                            SizedBox(width: AppSpacing.sm),
                            _MetaChip(
                              icon: Icons.grid_view_rounded,
                              label: reading.spreadLabel,
                            ),
                          ],
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.round,
        color: AppColors.surface.withValues(alpha: 0.55),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.22),
          width: AppBorderWidth.hairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.gold.withValues(alpha: 0.85)),
          SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              fontSize: 11,
              color: AppColors.goldLight.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
