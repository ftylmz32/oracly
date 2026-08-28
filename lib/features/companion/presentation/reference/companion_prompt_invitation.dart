/// Starter invitations — compact midnight glass surfaces.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';

class CompanionPromptInvitation extends StatelessWidget {
  const CompanionPromptInvitation({
    super.key,
    required this.label,
    required this.onTap,
    this.recessed = false,
    this.light = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool recessed;
  final bool light;

  static bool spansFullWidth(String label) => label.trim().length > 44;

  @override
  Widget build(BuildContext context) {
    final fill = light ? 0.04 : (recessed ? 0.06 : 0.08);
    final edge = light ? 0.09 : (recessed ? 0.11 : 0.14);
    final textAlpha = light ? 0.66 : (recessed ? 0.72 : 0.84);
    const radius = 12.0;
    return OraclyPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      glowShift: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: const Color(0xFF0A080C).withValues(alpha: fill + 0.04),
          border: Border.all(
            color: OraclyChrome.gold.withValues(alpha: edge),
            width: 0.45,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: light ? 10 : 12,
            vertical: light ? 7 : 9,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ReadingTypography.bodySmall(
                    color: OraclyChrome.cream.withValues(alpha: textAlpha),
                  ).copyWith(
                    height: 1.30,
                    fontSize: light ? 12.0 : 13.0,
                    letterSpacing: 0.04,
                  ),
                ),
              ),
              if (!light) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 9,
                  color: OraclyChrome.goldLight.withValues(alpha: 0.38),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

typedef CompanionPromptChip = CompanionPromptInvitation;
