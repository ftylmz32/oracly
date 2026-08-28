/// Compare with prior same-kind discovery — only when a pair exists.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/oracly_chrome.dart';
import '../../../theme/reading_typography.dart';
import '../../../../features/discovery_journal/models/discovery_journal_entry.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../copy/discovery_comparison_copy.dart';
import '../../models/discovery_comparison_kind.dart';
import '../../services/discovery_comparison_opener.dart';
import '../../services/discovery_comparison_pair_finder.dart';

class DiscoveryComparisonLink extends ConsumerWidget {
  const DiscoveryComparisonLink({
    super.key,
    required this.items,
    required this.entry,
  });

  final List<DiscoveryJournalEntry> items;
  final DiscoveryJournalEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (DiscoveryComparisonKind.fromJournalKind(entry.kind) == null) {
      return const SizedBox.shrink();
    }
    final prior = DiscoveryComparisonPairFinder.priorEntry(items, entry);
    if (prior == null) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        label: DiscoveryComparisonCopy.action,
        child: OraclyPressable(
          onTap: () => DiscoveryComparisonOpener.openForEntry(
            context,
            ref,
            items: items,
            current: entry,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Text(
                DiscoveryComparisonCopy.action,
                style: ReadingTypography.footnote(
                  color: OraclyChrome.goldLight.withValues(alpha: 0.82),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
