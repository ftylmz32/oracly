/// OR-1170 — Premium Reading History journal screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/copy/resilience_copy.dart';
import '../../../../core/design_system/loading_cinema/oracly_loading_kind.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../components/tarot_loading.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../presentation/animations/tarot_transition.dart';
import '../screens/reading_history_detail_screen.dart';
import '../utils/reading_history_mapper.dart';
import '../utils/reading_history_timeline.dart';
import '../widgets/reading_history/reading_history_background.dart';
import '../widgets/reading_history/reading_history_data.dart';
import '../widgets/reading_history/reading_history_empty_state.dart';
import '../widgets/reading_history/reading_history_filters.dart';
import '../widgets/reading_history/reading_history_header.dart';
import '../widgets/reading_history/reading_history_list_card.dart';
import '../widgets/reading_history/reading_history_search_bar.dart';
import '../widgets/reading_history/reading_history_summary.dart';
import '../widgets/reading_history/reading_history_timeline_marker.dart';
import '../widgets/reading_history/reading_personal_insight_journal.dart';
import '../../../../shared/widgets/oracly_empty_state.dart';
import '../../../../shared/widgets/oracly_error_state.dart';
import '../../../insights/services/personal_insight_engine.dart';
import '../../../insights/services/personal_journey_service.dart';
import '../../../../core/domain/models/reading.dart';
import '../../../../core/domain/models/ritual_journal_metadata.dart';

/// Personal mystical journal of past tarot readings.
class ReadingHistoryScreen extends ConsumerStatefulWidget {
  const ReadingHistoryScreen({
    super.key,
    this.showSampleData = false,
  });

  final bool showSampleData;

  @override
  ConsumerState<ReadingHistoryScreen> createState() =>
      _ReadingHistoryScreenState();
}

class _ReadingHistoryScreenState extends ConsumerState<ReadingHistoryScreen>
    with SingleTickerProviderStateMixin {
  static const _journey = PersonalJourneyService();

  late final AnimationController _entrance;
  late final TextEditingController _search;
  HistorySpreadFilter _filter = HistorySpreadFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search = TextEditingController();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _search.dispose();
    _entrance.dispose();
    super.dispose();
  }

  List<ReadingHistoryEntry> _entries(List<ReadingHistoryEntry> source) {
    if (widget.showSampleData) {
      return ReadingHistoryCatalogue.filterBy(_filter, _query);
    }
    return _journey.filterEntries(source, _filter, _query);
  }

  void _openDetail(ReadingHistoryEntry entry) {
    Navigator.of(context).push(
      tarotRitualRoute(
        page: ReadingHistoryDetailScreen(entry: entry),
        settings: RouteSettings(name: '/tarot/history/${entry.id}'),
      ),
    );
  }

  /// Sample readings for insight demo when [showSampleData] is true.
  List<ReadingModel> _sampleReadingsForInsight() {
    return ReadingHistoryCatalogue.entries.map((e) {
      return ReadingModel(
        id: e.id,
        cardId: 0,
        cardName: e.cardName,
        cardImageAsset: e.cardImageAsset,
        spreadType: e.spreadType,
        aiSummary: e.aiSummary,
        createdAt: e.date,
        journal: RitualJournalMetadata(
          emotionalKeywords: e.emotionalKeywords,
          personalNote: e.personalNote,
          summaryExcerpt: e.summaryExcerpt,
          tags: PersonalInsightEngine.tagsForReading(
            aiSummary: e.aiSummary,
            cardName: e.cardName,
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(readingHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ReadingHistoryBackground(),
          SafeArea(
            child: historyAsync.when(
              loading: () => const TarotLoading(),
              error: (_, _) => OraclyErrorState(
                kind: OraclyLoadingKind.tarot,
                title: ResilienceCopy.historyLoadFailedTitle,
                message: ResilienceCopy.historyLoadFailed,
                onRetry: () => ref.invalidate(readingHistoryProvider),
              ),
              data: (readings) {
                final source = readings
                    .map(ReadingHistoryMapper.fromModel)
                    .toList();
                final entries = _entries(source);
                final isEmpty = !widget.showSampleData && source.isEmpty;
                final showEmptyResults = !isEmpty &&
                    entries.isEmpty &&
                    (_query.isNotEmpty || _filter != HistorySpreadFilter.all);

                if (isEmpty) {
                  return Column(
                    children: [
                      const ReadingHistoryHeader(),
                      Expanded(
                        child: ReadingHistoryEmptyState(
                          onStartReading: () =>
                              OraclyNavigationService.startTarotFlow(context),
                        ),
                      ),
                    ],
                  );
                }

                final stats = widget.showSampleData
                    ? ReadingHistoryCatalogue.stats
                    : _journey.statsFrom(source);
                final journey = widget.showSampleData
                    ? _journey.compose(_sampleReadingsForInsight())
                    : _journey.compose(readings);
                final insightReport = journey.insightReport;
                final timeline = _journey.buildTimeline(entries);

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const ReadingHistoryHeader(),
                          AnimatedBuilder(
                            animation: _entrance,
                            builder: (context, _) {
                              final master = Curves.easeOutCubic.transform(
                                _entrance.value.clamp(0.0, 1.0),
                              );
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Opacity(
                                    opacity: master.clamp(0.0, 1.0),
                                    child: ReadingHistorySummary(stats: stats),
                                  ),
                                  if (insightReport.hasThemePattern ||
                                      insightReport.hasMonthlyReflection) ...[
                                    SizedBox(height: AppSpacing.lg),
                                    ReadingPersonalInsightJournal(
                                      report: insightReport,
                                      entrance: master,
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                          SizedBox(height: AppSpacing.md),
                          ReadingHistoryFilters(
                            selected: _filter,
                            onSelected: (f) => setState(() => _filter = f),
                          ),
                          SizedBox(height: AppSpacing.sm),
                          ReadingHistorySearchBar(
                            controller: _search,
                            onChanged: (v) => setState(() => _query = v),
                          ),
                          SizedBox(height: AppSpacing.md),
                        ],
                      ),
                    ),
                    if (showEmptyResults)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: OraclyEmptyState(
                          kind: OraclyLoadingKind.tarot,
                          imageAsset: AppAssets.tarotHero,
                          message: OraclyL10n.t('tarot.history.filter_empty'),
                          ctaLabel: OraclyL10n.t('tarot.history.clear_filter'),
                          onCta: () {
                            setState(() {
                              _filter = HistorySpreadFilter.all;
                              _query = '';
                              _search.clear();
                            });
                          },
                        ),
                      )
                    else
                      AnimatedBuilder(
                        animation: _entrance,
                        builder: (context, _) {
                          final master = Curves.easeOutCubic.transform(
                            _entrance.value.clamp(0.0, 1.0),
                          );
                          var cardIndex = 0;
                          return SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final node = timeline[index];
                                return switch (node) {
                                  ReadingHistoryMonthMarker(:final label) =>
                                    ReadingHistoryTimelineMarker(
                                      label: label,
                                      isFirst: index == 0,
                                      isMonth: true,
                                    ),
                                  ReadingHistoryDayMarker(
                                    :final label,
                                    :final isFirst,
                                  ) =>
                                    ReadingHistoryTimelineMarker(
                                      label: label,
                                      isFirst: isFirst,
                                    ),
                                  ReadingHistoryTimelineEntry(:final entry) =>
                                    Padding(
                                      padding: EdgeInsets.only(
                                        bottom: AppSpacing.md,
                                      ),
                                      child: ReadingHistoryListCard(
                                        entry: entry,
                                        entrance: historyCardEntrance(
                                          cardIndex++,
                                          master,
                                        ),
                                        onTap: () => _openDetail(entry),
                                      ),
                                    ),
                                };
                              },
                              childCount: timeline.length,
                            ),
                          );
                        },
                      ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xxl),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
