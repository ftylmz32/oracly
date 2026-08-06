/// OR-1090 — Reusable settings section tiles.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../core/widgets/oracly_signature_motifs.dart';
import '../../../../shared/widgets/oracly_pressable.dart';

class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: ReadingTypography.sectionLabel(),
          ),
          const OraclySignatureDivider(compact: true),
        ],
      ),
    );
  }
}

class SettingsToggleTile extends StatelessWidget {
  const SettingsToggleTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsGlassTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.gold.withValues(alpha: 0.55),
        activeThumbColor: AppColors.goldLight,
      ),
    );
  }
}

class SettingsChoiceTile extends StatelessWidget {
  const SettingsChoiceTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SettingsGlassTile(
      icon: icon,
      title: title,
      subtitle: value,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.gold.withValues(alpha: 0.65),
      ),
      onTap: onTap,
    );
  }
}

class SettingsNavTile extends StatelessWidget {
  const SettingsNavTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SettingsGlassTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: AppColors.gold.withValues(alpha: 0.55),
      ),
      onTap: onTap,
    );
  }
}

class _SettingsGlassTile extends StatelessWidget {
  const _SettingsGlassTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.lg,
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: OraclyPressable(
                onTap: onTap,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.lg,
                    color: AppColors.surface.withValues(alpha: 0.72),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      width: AppBorderWidth.hairline,
                    ),
                  ),
                  child: Padding(
                    padding: AppSpacing.card,
                    child: Row(
                      children: [
                        Icon(icon, color: AppColors.gold, size: AppSpacing.lg),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.goldLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: AppSpacing.xs),
                              Text(
                                subtitle,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ?trailing,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const OraclySignatureCornerOrnaments(
              inset: 8,
              size: 11,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for enum/string choices.
Future<T?> showSettingsChoiceSheet<T>({
  required BuildContext context,
  required String title,
  required List<(T value, String label)> options,
  required T current,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.transparent,
    builder: (context) {
      return ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xlValue),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.95),
              border: Border(
                top: BorderSide(
                  color: AppColors.gold.withValues(alpha: 0.28),
                  width: AppBorderWidth.hairline,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      title,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.goldLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...options.map((opt) {
                    final selected = opt.$1 == current;
                    return ListTile(
                      title: Text(
                        opt.$2,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: selected
                              ? AppColors.goldLight
                              : AppColors.textSecondary,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                      trailing: selected
                          ? Icon(Icons.check_rounded, color: AppColors.gold)
                          : null,
                      onTap: () => Navigator.pop(context, opt.$1),
                    );
                  }),
                  SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
