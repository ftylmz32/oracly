/// Filtered timeline of real persisted discoveries — story, then path.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/discovery_comparison/presentation/widgets/discovery_comparison_link.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../copy/discovery_journal_copy.dart';
import '../../models/discovery_journal_entry.dart';
import '../../models/discovery_journal_query.dart';
import '../../services/discovery_journal_filter_engine.dart';
import '../../services/discovery_journal_opener.dart';
import '../../services/discovery_journal_query_sanitize.dart';
import 'discovery_archive_heading.dart';
import 'discovery_journal_chronology.dart';
import 'discovery_journal_over_time.dart';
import 'discovery_journal_spine.dart';
import 'discovery_journal_story.dart';
import 'discovery_journal_tile.dart';
import 'discovery_journal_timeline_chrome.dart';

class DiscoveryJournalTimeline extends ConsumerStatefulWidget {
  const DiscoveryJournalTimeline({
    super.key,
    required this.items,
    this.focusTheme,
  });

  final List<DiscoveryJournalEntry> items;
  final String? focusTheme;

  @override
  ConsumerState<DiscoveryJournalTimeline> createState() =>
      _DiscoveryJournalTimelineState();
}

class _DiscoveryJournalTimelineState
    extends ConsumerState<DiscoveryJournalTimeline> {
  late DiscoveryJournalQuery _query = DiscoveryJournalQuery(
    theme: _themeIfPresent(widget.focusTheme, widget.items),
  );

  static String? _themeIfPresent(
    String? focus,
    List<DiscoveryJournalEntry> items,
  ) {
    final raw = focus?.trim();
    if (raw == null || raw.isEmpty) return null;
    for (final theme in DiscoveryJournalFilterEngine.options(items).themes) {
      if (theme.toLowerCase() == raw.toLowerCase()) return theme;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final options = DiscoveryJournalFilterEngine.options(widget.items);
    final query = DiscoveryJournalQuerySanitize.of(_query, options);
    final visible = DiscoveryJournalFilterEngine.apply(widget.items, query);
    final chapters = DiscoveryJournalChronology.chapters(visible);
    final heading = query.savedOnly
        ? DiscoveryJournalCopy.filterSaved
        : DiscoveryJournalCopy.archiveTitle;

    final rows = <Widget>[
      DiscoveryJournalStory(focusTheme: widget.focusTheme),
      const DiscoveryJournalOverTime(),
      DiscoveryJournalTimelineChrome.recommendation,
      DiscoveryJournalTimelineChrome.filters(
        query: query,
        options: options,
        onChanged: (next) => setState(() => _query = next),
      ),
      DiscoveryArchiveHeading(label: heading, top: AppSpacing.s12),
    ];
    if (visible.isEmpty) {
      rows.add(DiscoveryJournalTimelineChrome.empty);
    } else {
      for (var c = 0; c < chapters.length; c++) {
        final chapter = chapters[c];
        if (chapter.label.isNotEmpty) {
          rows.add(
            DiscoveryArchiveHeading(label: chapter.label, top: AppSpacing.s8),
          );
        }
        for (var i = 0; i < chapter.entries.length; i++) {
          rows.add(
            _row(
              context,
              chapter.entries[i],
              isFirst: c == 0 && i == 0,
              isLast: c == chapters.length - 1 &&
                  i == chapter.entries.length - 1,
            ),
          );
        }
      }
    }
    rows.add(DiscoveryJournalTimelineChrome.footer);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        OraclyChrome.screenSide,
        AppSpacing.lg,
        OraclyChrome.screenSide,
        AppLayout.scrollBottomInset(context),
      ),
      itemCount: rows.length,
      itemBuilder: (context, index) => rows[index],
    );
  }

  Widget _row(
    BuildContext context,
    DiscoveryJournalEntry entry, {
    required bool isFirst,
    required bool isLast,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: DiscoveryJournalSpine(
        isFirst: isFirst,
        isLast: isLast,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DiscoveryJournalTile(
              entry: entry,
              onTap: () => DiscoveryJournalOpener.open(context, ref, entry),
            ),
            DiscoveryComparisonLink(items: widget.items, entry: entry),
          ],
        ),
      ),
    );
  }
}
