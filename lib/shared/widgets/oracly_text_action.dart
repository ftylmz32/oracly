/// Quiet text / ghost action — never a Material TextButton.
library;

import 'package:flutter/material.dart';

import '../../core/accessibility/oracly_a11y.dart';
import '../../core/design_system/oracly_chrome.dart';
import '../../core/theme/reading_typography.dart';
import 'oracly_pressable.dart';

class OraclyTextAction extends StatelessWidget {
  const OraclyTextAction({
    super.key,
    required this.label,
    this.onPressed,
    this.emphasized = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool emphasized;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFC9A46C).withValues(alpha: 0.92)
        : emphasized
            ? OraclyChrome.goldLight.withValues(alpha: 0.92)
            : OraclyChrome.cream.withValues(alpha: OraclyA11y.secondaryCream);

    return Semantics(
      button: true,
      label: label,
      child: OraclyPressable(
        onTap: onPressed,
        enabled: onPressed != null,
        borderRadius: BorderRadius.circular(10),
        child: OraclyA11y.ensureMinTouch(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              label,
              style: ReadingTypography.bodyCore(color: color).copyWith(
                fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
