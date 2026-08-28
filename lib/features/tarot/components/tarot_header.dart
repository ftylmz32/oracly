/// OR-1000 — Tarot screen header component.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/oracly_header_action.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Premium header bar for tarot ritual screens.
class TarotHeader extends StatelessWidget {
  const TarotHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          leading ??
              TarotHeaderBackButton(
                onPressed: onBack ?? () => Navigator.maybePop(context),
              ),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          trailing ?? SizedBox(width: AppSpacing.xxl + AppSpacing.sm),
        ],
      ),
    );
  }
}

class TarotHeaderBackButton extends StatelessWidget {
  const TarotHeaderBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OraclyHeaderAction(
      icon: AppIcons.back,
      label: OraclyL10n.t(L10nKeys.back),
      onTap: onPressed ?? () => Navigator.maybePop(context),
    );
  }
}
