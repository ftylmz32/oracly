/// Earlier dreams — journal rows, tap opens the stored reading.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_empty_atmosphere.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../copy/dream_copy.dart';
import '../../models/dream.dart';
import '../utils/dream_history_labels.dart';
import 'dream_reference_tokens.dart';

class DreamReferenceRecentList extends StatelessWidget {
  const DreamReferenceRecentList({
    super.key,
    this.dreams = const [],
    this.onDreamTap,
  });

  final List<Dream> dreams;
  final ValueChanged<Dream>? onDreamTap;

  static String get sectionTitle => DreamCopy.previousDreams;

  @override
  Widget build(BuildContext context) {
    final recent = dreams.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          sectionTitle,
          style: ReadingTypography.sectionLabel(
            color: OraclyChrome.goldPrimary.withValues(alpha: 0.90),
          ),
        ),
        SizedBox(height: DreamReferenceTokens.sectionLabelToList),
        if (recent.isEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const OraclyEmptyAtmosphere(
                assetPath: AppAssets.homeDream,
                size: 72,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  DreamCopy.noPreviousDreams,
                  style: ReadingTypography.opening(
                    color: OraclyChrome.cream.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ],
          )
        else
          for (var i = 0; i < recent.length; i++) ...[
            if (i > 0) SizedBox(height: DreamReferenceTokens.recentItemGap),
            _RecentRow(
              dream: recent[i],
              onTap: onDreamTap == null ? null : () => onDreamTap!(recent[i]),
            ),
          ],
      ],
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.dream, this.onTap});

  final Dream dream;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DreamHistoryLabels.title(dream),
                      style: ReadingTypography.body(
                        color: OraclyChrome.cream.withValues(alpha: 0.92),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      DreamHistoryLabels.dateLabel(dream.recordedAt),
                      style: ReadingTypography.footnote(
                        color: OraclyChrome.cream.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
