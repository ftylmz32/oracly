/// Premium OR gateway CTA - compact gold pill.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/oracly_pressable.dart';

class HomeReferenceOrFlagshipCta extends StatelessWidget {
  const HomeReferenceOrFlagshipCta({
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 92, minHeight: 36),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  OraclyChrome.goldLight.withValues(alpha: 0.98),
                  OraclyChrome.gold.withValues(alpha: 0.90),
                  OraclyChrome.gold.withValues(alpha: 0.82),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: OraclyChrome.gold.withValues(alpha: 0.32),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: OraclyChrome.midnight.withValues(alpha: 0.94),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.25,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
