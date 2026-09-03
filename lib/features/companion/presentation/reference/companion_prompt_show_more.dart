/// Quiet reveal for the remaining starters — never a menu affordance.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../copy/companion_copy.dart';

class CompanionPromptShowMore extends StatelessWidget {
  const CompanionPromptShowMore({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: CompanionCopy.plusSemantics,
      child: OraclyPressable(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                CompanionCopy.plusLabel,
                style: ReadingTypography.micro(
                  color: OraclyChrome.goldLight.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: OraclyChrome.goldLight.withValues(alpha: 0.50),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
