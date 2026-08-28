/// Long-term user data scale — journal / profile / memory / AI bounds.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/history/history_scale_policy.dart';
import 'package:oracly_new/core/intelligence/services/personal_memory_builder.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/discovery_journal/models/discovery_journal_query.dart';
import 'package:oracly_new/features/discovery_journal/services/discovery_journal_aggregator.dart';
import 'package:oracly_new/features/discovery_journal/services/discovery_journal_filter_engine.dart';
import 'package:oracly_new/features/insights/services/journey_personalization_builder.dart';
import 'package:oracly_new/features/insights/services/personal_journey_service.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/services/discovery_or_context.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/reading_history/reading_history_data.dart';

List<ReadingModel> _seed(int n) {
  final base = DateTime(2024, 1, 1);
  return [
    for (var i = 0; i < n; i++)
      ReadingModel(
        id: 'r_$i',
        cardId: i % 22,
        cardName: 'Card ${i % 22}',
        cardImageAsset: 'a',
        spreadType: i.isEven ? 'Tek Kart' : 'Üç Kart',
        aiSummary: 'MARKER_$i calm reflection on choice and pace.',
        createdAt: base.add(Duration(hours: i)),
        intention: i % 5 == 0 ? 'karar' : null,
      ),
  ];
}

void _assertScale(int n, {required int budgetMs}) {
  final readings = _seed(n);
  final sw = Stopwatch()..start();

  final journal = DiscoveryJournalAggregator.merge(readings: readings);
  expect(journal, hasLength(n));
  final filtered = DiscoveryJournalFilterEngine.apply(
    journal,
    const DiscoveryJournalQuery(),
  );
  expect(filtered.length, n);

  final profile = PersonalDiscoveryProfileBuilder.from(
    PersonalDiscoverySources(readings: readings),
  );
  expect(profile.tarotCount, n);

  final journey = const PersonalJourneyService().compose(readings);
  expect(journey.totalReadings, n);

  final mapped = [
    for (final r in readings)
      ReadingHistoryEntry(
        id: r.id,
        cardName: r.cardName,
        cardImageAsset: r.cardImageAsset,
        spreadType: r.spreadType,
        date: r.createdAt,
        aiSummary: r.aiSummary,
        filter: HistorySpreadFilter.all,
        moodIcon: Icons.auto_awesome,
        cardIndex: 0,
        heroTag: r.id,
      ),
  ];
  final hits = const PersonalJourneyService().filterEntries(
    mapped,
    HistorySpreadFilter.all,
    'MARKER_0',
  );
  expect(hits, isNotEmpty);

  final memory = PersonalMemoryBuilder.fromProfile(profile);
  expect(memory.themes.length, lessThanOrEqualTo(PersonalMemoryBuilder.maxThemes));
  expect(memory.recentDiscoveries.length, lessThanOrEqualTo(8));
  expect(memory.toJson().toString().length, lessThan(4000));

  sw.stop();
  expect(
    sw.elapsedMilliseconds,
    lessThan(budgetMs),
    reason: 'n=$n took ${sw.elapsedMilliseconds}ms',
  );
}

void main() {
  test('100 discoveries — journal / search / profile stay fast', () {
    _assertScale(100, budgetMs: 800);
  });

  test('500 discoveries — journal / search / profile stay fast', () {
    _assertScale(500, budgetMs: 2500);
  });

  test('1000 lightweight journal records — open + search + memory', () {
    _assertScale(1000, budgetMs: 4000);
    expect(HistoryScalePolicy.retentionCap, 1000);
  });

  test('AI context stays bounded — never dumps 1000 records', () {
    final readings = _seed(1000);
    final hints = JourneyPersonalizationBuilder.fromHistory(readings);
    expect(hints.priorReadingCount, 1000);
    expect(hints.recentCardNames.length, lessThanOrEqualTo(3));
    expect(hints.priorOpenings.length, lessThanOrEqualTo(4));
    for (final o in hints.priorOpenings) {
      expect(o.length, lessThanOrEqualTo(48));
    }

    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(readings: readings),
    );
    final orLine = DiscoveryOrContext.compact(profile) ?? '';
    expect(DiscoveryOrContext.themeLabels(profile).length, lessThanOrEqualTo(3));
    // Unique markers from bulk history must not appear in OR compact context.
    var markerHits = 0;
    for (var i = 0; i < 1000; i++) {
      if (orLine.contains('MARKER_$i')) markerHits++;
    }
    expect(markerHits, 0);

    final turns = [
      for (var i = 0; i < 1000; i++)
        ConversationTurn(
          role: i.isEven
              ? ConversationTurn.userRole
              : ConversationTurn.assistantRole,
          text: 'turn MARKER_$i reflection',
        ),
    ];
    final window = ConversationTurn.takeRecent(turns);
    expect(window, hasLength(ConversationTurn.maxWindow));
    final payload = window.map((t) => t.toPayload()['text']!).join('|');
    expect(payload.contains('MARKER_0'), isFalse);
    expect(payload.contains('MARKER_999'), isTrue);
  });
}
