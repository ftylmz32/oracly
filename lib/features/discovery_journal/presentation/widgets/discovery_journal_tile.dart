/// One saved discovery fragment — archive plate on the timeline.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_glass_card.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/discovery_journal_copy.dart';
import '../../models/discovery_journal_entry.dart';
import 'discovery_journal_badge.dart';
import 'discovery_journal_entry_icon.dart';

class DiscoveryJournalTile extends StatelessWidget {
  const DiscoveryJournalTile({
    super.key,
    required this.entry,
    required this.onTap,
  });

  final DiscoveryJournalEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final source = DiscoveryJournalCopy.badge(entry.kind);
    return Semantics(
      button: true,
      label: '$source, ${entry.title}, ${entry.dateLabel}',
      child: OraclyGlassCard(
        onTap: onTap,
        elevated: true,
        glowStrength: 0.62,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s12,
          AppSpacing.s12,
          AppSpacing.s12,
          AppSpacing.s12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: OraclyChrome.goldLight.withValues(alpha: 0.36),
                  width: 0.8,
                ),
                gradient: LinearGradient(
                  colors: [
                    OraclyChrome.gold.withValues(alpha: 0.12),
                    OraclyChrome.midnight.withValues(alpha: 0.45),
                  ],
                ),
              ),
              child: SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  DiscoveryJournalEntryIcon.of(entry.kind),
                  size: 15,
                  color: OraclyChrome.goldLight.withValues(alpha: 0.88),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DiscoveryJournalBadge(kind: entry.kind),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.dateLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ReadingTypography.footnote(
                            color: OraclyChrome.goldLight.withValues(
                              alpha: 0.70,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    entry.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ReadingTypography.bodyCore(
                      color: OraclyChrome.cream.withValues(alpha: 0.92),
                    ),
                  ),
                  if (entry.preview.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      entry.preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ReadingTypography.footnote(
                        color: OraclyChrome.cream.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
