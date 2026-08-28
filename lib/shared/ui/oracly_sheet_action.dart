/// Sheet action row — Oracly pressable, never Material ListTile.
library;

import 'package:flutter/material.dart';

import '../../core/design_system/oracly_chrome.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/reading_typography.dart';
import '../widgets/oracly_pressable.dart';

class OraclySheetAction extends StatelessWidget {
  const OraclySheetAction({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFC9A46C).withValues(alpha: 0.92)
        : OraclyChrome.cream.withValues(alpha: 0.88);

    return OraclyPressable(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: color),
              SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Text(
                label,
                style: ReadingTypography.body(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
