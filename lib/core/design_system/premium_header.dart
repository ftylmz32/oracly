/// EPIC-021 — Reusable premium screen header.
library;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'app_colors.dart';
import 'app_icons.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'oracly_header_action.dart';

/// Logo + title + optional trailing action — consistent screen chrome.
class PremiumHeader extends StatelessWidget implements PreferredSizeWidget {
  const PremiumHeader({
    super.key,
    required this.title,
    this.logo,
    this.subtitle,
    this.trailing,
    this.onBack,
    this.centerTitle = false,
    this.padding,
  });

  final String title;
  final Widget? logo;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onBack;
  final bool centerTitle;
  final EdgeInsetsGeometry? padding;

  @override
  Size get preferredSize => Size.fromHeight(
        subtitle != null ? kToolbarHeight + AppSpacing.s8 : kToolbarHeight,
      );

  @override
  Widget build(BuildContext context) {
    final horizontal = padding ??
        EdgeInsets.symmetric(horizontal: AppSpacing.s24);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: horizontal,
        child: SizedBox(
          height: preferredSize.height,
          child: Row(
            children: [
              if (onBack != null) ...[
                OraclyHeaderAction(
                  icon: AppIcons.back,
                  label: OraclyL10n.t(L10nKeys.back),
                  onTap: onBack,
                ),
                SizedBox(width: AppSpacing.s8),
              ],
              if (logo != null) ...[
                logo!,
                SizedBox(width: AppSpacing.s12),
              ],
              Expanded(
                child: centerTitle
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: AppTypography.headingM.copyWith(
                              color: AppColors.goldLight,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              textAlign: TextAlign.center,
                              style: AppTypography.caption,
                            ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: AppTypography.headingM.copyWith(
                              color: AppColors.goldLight,
                            ),
                          ),
                          if (subtitle != null)
                            Text(subtitle!, style: AppTypography.caption),
                        ],
                      ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
