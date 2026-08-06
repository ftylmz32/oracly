/// SPRINT-001 — Section header for dream journey phases.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/reading_typography.dart';

class DreamSectionHeader extends StatelessWidget {
  const DreamSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: ReadingTypography.cardTitle()),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: ReadingTypography.opening()),
        ],
      ],
    );
  }
}

class DreamChip extends StatelessWidget {
  const DreamChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onTap != null ? (_) => onTap!() : null,
      showCheckmark: false,
      labelStyle: ReadingTypography.bodySmall(
        color: selected ? AppColors.textPrimary : AppColors.textSecondary,
      ),
      selectedColor: AppColors.purple.withValues(alpha: 0.35),
      backgroundColor: AppColors.surface.withValues(alpha: 0.55),
      side: BorderSide(
        color: selected
            ? AppColors.gold.withValues(alpha: 0.55)
            : AppColors.gold.withValues(alpha: 0.18),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
