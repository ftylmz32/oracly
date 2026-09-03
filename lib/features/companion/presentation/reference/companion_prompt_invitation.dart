/// Starter invitations -- violet glass cards with gold line-art icons.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import 'companion_gold_line_icon.dart';
import 'companion_reference_tokens.dart';

class CompanionPromptInvitation extends StatelessWidget {
  const CompanionPromptInvitation({
    super.key,
    required this.label,
    required this.onTap,
    this.recessed = false,
    this.light = false,
    this.horizontalChip = false,
    this.icon,
    this.iconIndex = 0,
    this.lineIcon,
  });

  final String label;
  final VoidCallback onTap;
  final bool recessed;
  final bool light;
  final bool horizontalChip;
  final IconData? icon;
  final int iconIndex;
  final CompanionLineIconKind? lineIcon;

  static bool spansFullWidth(String label) => label.trim().length > 44;

  static const lineIcons = <CompanionLineIconKind>[
    CompanionLineIconKind.crystal,
    CompanionLineIconKind.heart,
    CompanionLineIconKind.cards,
    CompanionLineIconKind.dream,
    CompanionLineIconKind.astrology,
  ];

  @override
  Widget build(BuildContext context) {
    final radius = horizontalChip ? 14.0 : 12.0;
    final kind = lineIcon ?? lineIcons[iconIndex % lineIcons.length];
    return OraclyPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      glowShift: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: const Color(0xFF1A1224).withValues(
            alpha: light ? 0.42 : 0.68,
          ),
          border: Border.all(
            color: OraclyChrome.violet.withValues(
              alpha: light ? 0.42 : 0.62,
            ),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: OraclyChrome.violet.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalChip ? 12 : (light ? 10 : 12),
            vertical: horizontalChip ? 10 : (light ? 7 : 9),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: horizontalChip ? 168 : double.infinity,
              minHeight: horizontalChip
                  ? CompanionReferenceTokens.quickPromptCardHeight - 20
                  : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CompanionGoldLineIcon(kind: kind, size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ReadingTypography.bodySmall(
                      color: OraclyChrome.cream.withValues(
                        alpha: light ? 0.72 : 0.90,
                      ),
                    ).copyWith(
                      height: 1.28,
                      fontSize: light ? 12.0 : 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

typedef CompanionPromptChip = CompanionPromptInvitation;
