/// Reference settings group — section title + glass card with rows.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_radius.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/oracly_signature_motifs.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import 'settings_reference_card_shell.dart';
import 'settings_reference_switch.dart';
import 'settings_reference_tokens.dart';

class SettingsReferenceRow {
  const SettingsReferenceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingValue,
    this.switchValue,
    this.onSwitchChanged,
    this.onTap,
    this.showChevron = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingValue;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final VoidCallback? onTap;
  final bool showChevron;

  bool get isToggle => switchValue != null && onSwitchChanged != null;
}

class SettingsReferenceGroup extends StatelessWidget {
  const SettingsReferenceGroup({
    super.key,
    required this.title,
    required this.rows,
  });

  final String title;
  final List<SettingsReferenceRow> rows;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: AppTextStyles.labelMedium.copyWith(
            color: palette.gold.withValues(alpha: 0.78),
            letterSpacing: 2.8,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        const OraclySignatureDivider(compact: true),
        SizedBox(height: SettingsReferenceTokens.sectionLabelToCard),
        SettingsReferenceCardShell(
          borderRadius: SettingsReferenceTokens.groupRadius,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const _GroupDivider(),
                _SettingsRow(row: rows[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupDivider extends StatelessWidget {
  const _GroupDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.14),
              width: AppBorderWidth.hairline,
            ),
          ),
        ),
        child: const SizedBox(height: 0),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.row});

  final SettingsReferenceRow row;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: SettingsReferenceTokens.rowHeight),
      child: Padding(
        padding: SettingsReferenceTokens.rowPadding,
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: SettingsReferenceTokens.rowIconRadius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    palette.surface.withValues(alpha: 0.92),
                    palette.purple.withValues(alpha: 0.28),
                  ],
                ),
                border: Border.all(color: palette.gold.withValues(alpha: 0.28)),
              ),
              child: SizedBox(
                width: SettingsReferenceTokens.rowIconWell,
                height: SettingsReferenceTokens.rowIconWell,
                child: Icon(
                  row.icon,
                  size: 22,
                  color: palette.goldLight.withValues(alpha: 0.92),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    row.title,
                    style: AppTextStyles.title.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: palette.textPrimary.withValues(alpha: 0.94),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: palette.textSecondary.withValues(alpha: 0.78),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (row.isToggle)
              SettingsReferenceSwitch(
                key: ValueKey('settings-switch-${row.title}'),
                value: row.switchValue!,
                onChanged: row.onSwitchChanged!,
              )
            else if (row.trailingValue != null) ...[
              Flexible(
                child: Text(
                  row.trailingValue!,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.caption.copyWith(
                    color: palette.gold.withValues(alpha: 0.86),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: palette.gold.withValues(alpha: 0.72),
              ),
            ] else if (row.showChevron)
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: palette.gold.withValues(alpha: 0.72),
              ),
          ],
        ),
      ),
    );

    if (row.onTap == null || row.isToggle) return content;

    return OraclyPressable(
      onTap: row.onTap,
      behavior: HitTestBehavior.opaque,
      borderRadius: SettingsReferenceTokens.groupRadius,
      child: content,
    );
  }
}
