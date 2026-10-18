/// Outlined Premium step — looks like a choice, never like a purchase.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';

class PremiumQuietAction extends StatelessWidget {
  const PremiumQuietAction({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: OraclyPressable(
        onTap: onTap,
        borderRadius: OraclyChrome.pillRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppLayout.minTouchTarget,
            minWidth: 168,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: OraclyChrome.pillRadius,
              border: Border.all(
                color: OraclyChrome.goldLight.withValues(alpha: 0.72),
              ),
              color: const Color(0xFF1A140C).withValues(alpha: 0.55),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: ReadingTypography.body(
                    color: OraclyChrome.goldLight.withValues(alpha: 0.96),
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
