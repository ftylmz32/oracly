/// OR menu sheet row — glass chamber polish.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';

class CompanionOrMenuRow extends StatelessWidget {
  const CompanionOrMenuRow({
    super.key,
    required this.label,
    required this.onTap,
    required this.icon,
    this.premium = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData icon;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: OraclyChrome.violet.withValues(alpha: premium ? 0.14 : 0.08),
                border: Border.all(
                  color: OraclyChrome.gold.withValues(alpha: premium ? 0.22 : 0.12),
                  width: 0.5,
                ),
              ),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  icon,
                  size: 18,
                  color: OraclyChrome.goldLight.withValues(alpha: 0.88),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: ReadingTypography.body(
                  color: OraclyChrome.cream.withValues(alpha: 0.92),
                ).copyWith(fontSize: 15),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: OraclyChrome.cream.withValues(alpha: 0.28),
            ),
          ],
        ),
      ),
    );
  }
}
