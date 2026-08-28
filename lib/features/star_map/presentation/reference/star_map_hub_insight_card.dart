/// Chapter card — icon, gold title, divider, short narrative.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_soft_reveal.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import 'star_map_reference_card_shell.dart';
import 'star_map_reference_tokens.dart';

class StarMapHubInsightCard extends StatelessWidget {
  const StarMapHubInsightCard({
    super.key,
    required this.title,
    required this.body,
    this.icon,
    this.onOpen,
    this.delay = Duration.zero,
    this.footer,
    this.maxLines,
    this.glowStrength = 1.12,
  });

  final String title;
  final String body;
  final IconData? icon;
  final VoidCallback? onOpen;
  final Duration delay;
  final Widget? footer;
  final int? maxLines;
  final double glowStrength;

  @override
  Widget build(BuildContext context) {
    return OraclySoftReveal(
      delay: delay,
      child: OraclyPressable(
        onTap: onOpen,
        borderRadius: StarMapReferenceTokens.menuCardRadius,
        child: StarMapReferenceCardShell(
          borderRadius: StarMapReferenceTokens.menuCardRadius,
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          premium: true,
          glowStrength: glowStrength,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: OraclyChrome.goldLight),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ReadingTypography.sectionLabel(
                        color: OraclyChrome.goldPrimary.withValues(alpha: 0.94),
                      ),
                    ),
                  ),
                  if (onOpen != null)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: OraclyChrome.goldLight.withValues(alpha: 0.72),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 1,
                color: OraclyChrome.gold.withValues(alpha: 0.28),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                maxLines: maxLines,
                overflow: maxLines == null
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: ReadingTypography.body(
                  color: StarMapReferenceTokens.cream.withValues(alpha: 0.90),
                ),
              ),
              if (footer != null) ...[
                const SizedBox(height: 10),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
