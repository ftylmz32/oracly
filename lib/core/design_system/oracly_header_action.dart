/// Circular header action button — menu / back — reference chrome.
library;

import 'package:flutter/material.dart';

import '../../shared/widgets/oracly_pressable.dart';
import '../accessibility/oracly_a11y.dart';
import 'app_borders.dart';
import 'app_colors.dart';
import 'app_layout.dart';
import 'app_radius.dart';
import 'oracly_chrome.dart';

/// Glass circle with fine gold rim — left slot of [OraclyAppBar].
class OraclyHeaderAction extends StatelessWidget {
  const OraclyHeaderAction({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.size = AppLayout.headerActionSize,
    this.iconSize = AppLayout.headerIconSize,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final side = size < OraclyA11y.minTouchTarget
        ? OraclyA11y.minTouchTarget
        : size;
    return OraclyPressable(
      onTap: onTap,
      label: label,
      borderRadius: AppRadius.round,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: OraclyChrome.chromeGlass,
          border: Border.all(
            color: OraclyChrome.goldMuted.withValues(alpha: 0.48),
            width: AppBorders.hairline,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.28),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: AppColors.purpleGlow.withValues(alpha: 0.10),
              blurRadius: 10,
              spreadRadius: -2,
            ),
          ],
        ),
        child: SizedBox(
          width: side,
          height: side,
          child: ExcludeSemantics(
            child: Icon(
              icon,
              size: iconSize,
              color: OraclyA11y.goldReadable(OraclyChrome.goldHighlight),
            ),
          ),
        ),
      ),
    );
  }
}
