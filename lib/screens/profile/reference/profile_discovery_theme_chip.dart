/// One real recurring theme — count, date, sources. No internals.
library;

import 'package:flutter/material.dart';

import '../../../features/discovery_journal/copy/discovery_journal_copy.dart';
import '../../../core/design_system/app_radius.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../features/personal_discovery/models/cross_discovery_insight.dart';
import 'profile_discovery_summary.dart';

class ProfileDiscoveryThemeChip extends StatelessWidget {
  const ProfileDiscoveryThemeChip({super.key, required this.insight});

  final CrossDiscoveryInsight insight;

  static IconData _sourceIcon(String raw) => switch (raw) {
        'tarot' => Icons.auto_stories_rounded,
        'dream' => Icons.nights_stay_rounded,
        'coffee' => Icons.local_cafe_rounded,
        'reflection' => Icons.forum_outlined,
        'palm' => Icons.pan_tool_outlined,
        'astrology' => Icons.auto_awesome_rounded,
        'star' || 'starMap' || 'star_map' => Icons.star_rounded,
        'daily' || 'dailyMessage' => Icons.wb_twilight_outlined,
        _ => Icons.circle_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final sources = insight.sources.take(3).toList(growable: false);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.s16,
        color: OraclyChrome.violet.withValues(alpha: 0.18),
        border: Border.all(color: OraclyChrome.gold.withValues(alpha: 0.32)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ProfileDiscoverySummary.displayTheme(insight.theme),
              style: AppTextStyles.bodySmall.copyWith(
                color: OraclyChrome.goldLight.withValues(alpha: 0.94),
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  DiscoveryJournalCopy.recency(insight.recencyBand),
                  style: ReadingTypography.footnote(
                    color: OraclyChrome.cream.withValues(alpha: 0.68),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final s in sources) ...[
                      Icon(
                        _sourceIcon(s),
                        size: 14,
                        color: OraclyChrome.goldLight.withValues(alpha: 0.76),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${DiscoveryJournalCopy.discoveries(insight.discoveryCount)} · '
              '${DiscoveryJournalCopy.areas(insight.sourceCount)}',
              style: ReadingTypography.footnote(
                color: OraclyChrome.cream.withValues(alpha: 0.60),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
