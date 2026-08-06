/// RC-010 — Reflection engine tests.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_ai_conversation_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/domain/models/ritual_journal_metadata.dart';
import 'package:oracly_new/core/intelligence/data/intelligence_index_store.dart';
import 'package:oracly_new/core/intelligence/data/local_intelligence_repository.dart';
import 'package:oracly_new/core/intelligence/data/ritual_history_reader.dart';
import 'package:oracly_new/core/intelligence/services/intelligence_layer_service.dart';
import 'package:oracly_new/core/reflection/domain/models/growth_insight.dart';
import 'package:oracly_new/core/reflection/domain/models/journey_milestone.dart';
import 'package:oracly_new/core/reflection/domain/models/personal_trend.dart';
import 'package:oracly_new/core/reflection/domain/models/reflection_evidence_kind.dart';
import 'package:oracly_new/core/reflection/domain/models/reflection_input.dart';
import 'package:oracly_new/core/reflection/domain/models/reflection_summary.dart';
import 'package:oracly_new/core/reflection/engine/reflection_engine.dart';
import 'package:oracly_new/core/reflection/services/reflection_engine_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ReflectionEngine', () {
    late ReflectionEngine engine;
    final asOf = DateTime(2026, 8, 6);

    setUp(() {
      engine = const ReflectionEngine();
    });

    test('returns empty summary for empty input', () {
      final summary = engine.analyze(
        ReflectionInput(
          readings: const [],
          reflections: const [],
          favoriteCards: const [],
          ritualDays: const [],
          asOf: asOf,
        ),
      );

      expect(summary.schemaVersion, ReflectionSummary.currentSchemaVersion);
      expect(summary.hasObservablePatterns, isFalse);
    });

    test('detects recurring themes only with enough readings', () {
      final sparse = engine.analyze(
        ReflectionInput(
          readings: [
            _reading(
              id: 'r1',
              name: 'The Fool',
              summary: 'Yeni bir aşk başlangıcı.',
              at: DateTime(2026, 7, 1),
            ),
            _reading(
              id: 'r2',
              name: 'The Lovers',
              summary: 'Sevgi ve bağ üzerine.',
              at: DateTime(2026, 7, 10),
            ),
          ],
          reflections: const [],
          favoriteCards: const [],
          ritualDays: const [],
          asOf: asOf,
        ),
      );
      expect(sparse.recurringThemes.where(
        (t) => t.evidence == ReflectionEvidenceKind.themeTag,
      ), isEmpty);

      final rich = engine.analyze(
        ReflectionInput(
          readings: [
            _reading(
              id: 'r1',
              name: 'The Fool',
              summary: 'Yeni bir aşk başlangıcı.',
              at: DateTime(2026, 6, 1),
              tags: ['insight:love'],
            ),
            _reading(
              id: 'r2',
              name: 'The Lovers',
              summary: 'Sevgi ve bağ üzerine.',
              at: DateTime(2026, 6, 15),
              tags: ['insight:love'],
            ),
            _reading(
              id: 'r3',
              name: 'Two of Cups',
              summary: 'Aşk ve birliktelik.',
              at: DateTime(2026, 7, 1),
              tags: ['insight:love'],
            ),
          ],
          reflections: const [],
          favoriteCards: const [],
          ritualDays: const [],
          asOf: asOf,
        ),
      );

      expect(
        rich.recurringThemes.any(
          (theme) =>
              theme.evidence == ReflectionEvidenceKind.themeTag &&
              theme.id == 'love',
        ),
        isTrue,
      );
    });

    test('detects recurring cards and milestones', () {
      final summary = engine.analyze(
        ReflectionInput(
          readings: [
            _reading(
              id: 'r1',
              name: 'The Hermit',
              summary: 'İç ses.',
              at: DateTime(2026, 5, 1),
            ),
            _reading(
              id: 'r2',
              name: 'The Hermit',
              summary: 'Yalnızlık ve bilgelik.',
              at: DateTime(2026, 6, 1),
            ),
          ],
          reflections: const [],
          favoriteCards: const [],
          ritualDays: const [],
          asOf: asOf,
        ),
      );

      expect(
        summary.recurringThemes.any(
          (theme) =>
              theme.evidence == ReflectionEvidenceKind.cardDraw &&
              theme.label == 'The Hermit',
        ),
        isTrue,
      );
      expect(
        summary.milestones.any(
          (m) => m.kind == JourneyMilestoneKind.firstReading,
        ),
        isTrue,
      );
      expect(
        summary.milestones.any(
          (m) => m.kind == JourneyMilestoneKind.recurringCard,
        ),
        isTrue,
      );
    });

    test('growth insights use observational language not predictions', () {
      final summary = engine.analyze(
        ReflectionInput(
          readings: [
            for (var i = 0; i < 4; i++)
              _reading(
                id: 'recent_$i',
                name: 'The Star',
                summary: 'Umut ve aşk yolculuğu.',
                at: DateTime(2026, 8, 1).add(Duration(days: i)),
                tags: ['insight:love'],
              ),
          ],
          reflections: const [],
          favoriteCards: const [],
          ritualDays: const [],
          asOf: asOf,
        ),
      );

      for (final insight in summary.growthInsights) {
        expect(insight.observation.toLowerCase(), isNot(contains('kesin')));
        expect(insight.observation.toLowerCase(), isNot(contains('olacak')));
        expect(insight.kind, isA<GrowthInsightKind>());
      }
    });

    test('personal trends compare recent and prior windows', () {
      final summary = engine.analyze(
        ReflectionInput(
          readings: [
            _reading(
              id: 'old1',
              name: 'The Tower',
              summary: 'Değişim.',
              at: DateTime(2026, 4, 1),
              spread: 'Tek Kart',
            ),
            _reading(
              id: 'old2',
              name: 'Wheel of Fortune',
              summary: 'Döngü.',
              at: DateTime(2026, 4, 15),
              spread: 'Üç Kart',
            ),
            _reading(
              id: 'new1',
              name: 'The Star',
              summary: 'Umut.',
              at: DateTime(2026, 7, 20),
              spread: 'Tek Kart',
            ),
            _reading(
              id: 'new2',
              name: 'The Sun',
              summary: 'Neşe.',
              at: DateTime(2026, 8, 1),
              spread: 'Tek Kart',
            ),
            _reading(
              id: 'new3',
              name: 'The Moon',
              summary: 'Sezgi.',
              at: DateTime(2026, 8, 3),
              spread: 'Tek Kart',
            ),
          ],
          reflections: const [],
          favoriteCards: const [],
          ritualDays: const [],
          asOf: asOf,
        ),
      );

      expect(
        summary.trends.any(
          (trend) =>
              trend.kind == PersonalTrendKind.spreadPreference &&
              trend.subject == 'Tek Kart' &&
              trend.direction == TrendDirection.rising,
        ),
        isTrue,
      );
    });
  });

  group('ReflectionEngineService', () {
    test('builds summary from intelligence layer without AI', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final history = MockHistoryRepository(storage);
      await history.saveReading(
        _reading(
          id: 'r1',
          name: 'The Fool',
          summary: 'Başlangıç.',
          at: DateTime(2026, 8, 1),
        ),
      );

      final intelligence = IntelligenceLayerService(
        LocalIntelligenceRepository(
          history: history,
          conversations: LocalAiConversationRepository(storage),
          ritualHistory: RitualHistoryReader(storage),
          indexStore: IntelligenceIndexStore(storage),
        ),
      );
      final service = ReflectionEngineService(intelligence: intelligence);

      final summary = await service.analyze(asOf: DateTime(2026, 8, 6));
      expect(summary.milestones.any(
        (m) => m.kind == JourneyMilestoneKind.firstReading,
      ), isTrue);
    });
  });
}

ReadingModel _reading({
  required String id,
  required String name,
  required String summary,
  required DateTime at,
  List<String> tags = const [],
  String spread = 'Tek Kart',
}) {
  return ReadingModel(
    id: id,
    cardId: 1,
    cardName: name,
    cardImageAsset: 'assets/card.png',
    spreadType: spread,
    aiSummary: summary,
    createdAt: at,
    journal: RitualJournalMetadata(
      tags: tags,
      emotionalKeywords: const ['Yansıma'],
    ),
  );
}
