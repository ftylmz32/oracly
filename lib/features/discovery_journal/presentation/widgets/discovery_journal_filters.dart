/// Quiet archival filters — only chips backed by real rows.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../copy/discovery_journal_filter_copy.dart';
import '../../models/discovery_journal_filter_options.dart';
import '../../models/discovery_journal_kind.dart';
import '../../models/discovery_journal_query.dart';
import 'discovery_journal_filter_tab.dart';

class DiscoveryJournalFilters extends StatelessWidget {
  const DiscoveryJournalFilters({
    super.key,
    required this.query,
    required this.options,
    required this.onChanged,
  });

  final DiscoveryJournalQuery query;
  final DiscoveryJournalFilterOptions options;
  final ValueChanged<DiscoveryJournalQuery> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!options.hasAdvanced && options.ranges.length <= 1) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row([
            for (final range in options.ranges)
              DiscoveryJournalFilterTab(
                label: DiscoveryJournalFilterCopy.range(range),
                selected: query.range == range,
                onTap: () => onChanged(query.copyWith(range: range)),
              ),
          ]),
          if (options.kinds.length > 1)
            _row([
              DiscoveryJournalFilterTab(
                label: DiscoveryJournalFilterCopy.featureAll,
                selected: query.kind == null,
                onTap: () => onChanged(query.copyWith(clearKind: true)),
              ),
              for (final kind in options.kinds)
                DiscoveryJournalFilterTab(
                  label: DiscoveryJournalFilterCopy.kind(kind),
                  selected: query.kind == kind,
                  onTap: () => _toggleKind(kind),
                ),
            ]),
          if (options.hasSaved)
            _row([
              DiscoveryJournalFilterTab(
                label: DiscoveryJournalFilterCopy.saved,
                selected: query.savedOnly,
                onTap: () => onChanged(
                  query.copyWith(savedOnly: !query.savedOnly),
                ),
              ),
            ]),
          if (options.themes.isNotEmpty)
            _row([
              DiscoveryJournalFilterTab(
                label: DiscoveryJournalFilterCopy.themeAll,
                selected: query.theme == null,
                onTap: () => onChanged(query.copyWith(clearTheme: true)),
              ),
              for (final theme in options.themes)
                DiscoveryJournalFilterTab(
                  label: DiscoveryJournalFilterCopy.theme(theme),
                  selected:
                      query.theme?.toLowerCase() == theme.toLowerCase(),
                  onTap: () => _toggleTheme(theme),
                ),
            ]),
        ],
      ),
    );
  }

  Widget _row(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Wrap(spacing: 16, runSpacing: 8, children: children),
    );
  }

  void _toggleKind(DiscoveryJournalKind kind) {
    if (query.kind == kind) {
      onChanged(query.copyWith(clearKind: true));
    } else {
      onChanged(query.copyWith(kind: kind));
    }
  }

  void _toggleTheme(String theme) {
    if (query.theme?.toLowerCase() == theme.toLowerCase()) {
      onChanged(query.copyWith(clearTheme: true));
    } else {
      onChanged(query.copyWith(theme: theme));
    }
  }
}
