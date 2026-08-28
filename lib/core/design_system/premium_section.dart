/// EPIC-021 — Reusable section title + content wrapper.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Section block with label, optional action, and consistent vertical rhythm.
class PremiumSection extends StatelessWidget {
  const PremiumSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.padding,
    this.spacing,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final gap = spacing ?? AppSpacing.s16;

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.title.copyWith(
                        color: AppColors.goldLight.withValues(alpha: 0.94),
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: AppSpacing.s4),
                      Text(subtitle!, style: AppTypography.caption),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          SizedBox(height: gap),
          child,
        ],
      ),
    );
  }
}
