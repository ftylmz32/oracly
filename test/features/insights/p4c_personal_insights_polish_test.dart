/// P4C — regenerate and privacy writes tell the truth.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/intelligence/domain/models/favorite_card_ref.dart';
import 'package:oracly_new/core/intelligence/domain/models/intelligence_snapshot.dart';
import 'package:oracly_new/core/intelligence/domain/models/reflection_entry.dart';
import 'package:oracly_new/core/intelligence/domain/models/ritual_history_entry.dart';
import 'package:oracly_new/core/intelligence/domain/repositories/intelligence_repository.dart';
import 'package:oracly_new/core/intelligence/services/intelligence_layer_service.dart';
import 'package:oracly_new/core/domain/models/conversation_record.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/reflection/services/reflection_engine_service.dart';
import 'package:oracly_new/features/insights/controllers/personal_insights_controller.dart';
import 'package:oracly_new/features/insights/copy/personal_insights_copy.dart';
import 'package:oracly_new/features/insights/data/personal_insights_preferences_repository.dart';
import 'package:oracly_new/features/insights/models/growth_snapshot.dart';
import 'package:oracly_new/features/insights/models/insight.dart';
import 'package:oracly_new/features/insights/models/insight_category.dart';
import 'package:oracly_new/features/insights/models/personal_pattern.dart';
import 'package:oracly_new/features/insights/models/reflection_summary.dart';
import 'package:oracly_new/features/insights/presentation/screens/personal_insights_screen.dart';
import 'package:oracly_new/features/insights/providers/insights_providers.dart';
import 'package:oracly_new/features/insights/services/personal_insights_experience_service.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('a failed hide does not record the insight as hidden', () async {
    final storage = _SelectiveStorage()..failHidden = true;
    final repo = PersonalInsightsPreferencesRepository(storage);
    expect(await repo.hide('insight-a'), isFalse);
    expect((await repo.load()).hiddenIds, isEmpty);
  });

  test('a failed delete leaves hidden and deleted sets unchanged', () async {
    final storage = _SelectiveStorage();
    final repo = PersonalInsightsPreferencesRepository(storage);
    expect(await repo.hide('keep'), isTrue);
    storage.failHidden = true;
    expect(await repo.delete('keep'), isFalse);
    final prefs = await repo.load();
    expect(prefs.hiddenIds, {'keep'});
    expect(prefs.deletedIds, isEmpty);
  });

  test('export chrome follows the locale and omits raw ids', () {
    final service = _scripted();
    final summary = InsightReflectionSummary(
      salutation: 'Hello',
      generatedAt: DateTime(2026, 9, 1),
      growthSnapshot: GrowthSnapshot(
        narrative: 'Observed pace',
        asOf: DateTime(2026, 9, 1),
      ),
      insights: [
        Insight(
          id: 'raw-id-sentinel',
          category: InsightCategory.recurringTheme,
          title: 'A theme',
          body: 'Only the observation',
          generatedAt: DateTime(2026, 9, 1),
        ),
      ],
      patterns: const [
        PersonalPattern(
          id: 'pattern-id-sentinel',
          label: 'Theme',
          observation: 'It recurred',
          occurrenceCount: 2,
        ),
      ],
    );
    OraclyL10n.bind('en');
    final english = service.exportAsText(summary);
    expect(english, contains('Growth'));
    expect(english, contains('Recurring patterns'));
    expect(english, isNot(contains('Desenler')));
    expect(english, isNot(contains('raw-id-sentinel')));
    expect(english, isNot(contains('pattern-id-sentinel')));
    OraclyL10n.bind('ru');
    expect(service.exportAsText(summary), contains('Рост'));
    OraclyL10n.bind('tr');
    expect(InsightCategory.recurringTheme.sectionLabel, 'Yankılanan temalar');
  });

  testWidgets('failed regenerate does not show a success confirmation', (
    tester,
  ) async {
    final service = _scripted();
    final storage = LocalStorage.ephemeral();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          personalInsightsControllerProvider.overrideWith((ref) {
            final controller = PersonalInsightsController(service);
            controller.load();
            return controller;
          }),
        ],
        child: const MaterialApp(home: PersonalInsightsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Hello sentinel'), findsOneWidget);

    service.fail = true;
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text(PersonalInsightsCopy.regenerateAction));
    await tester.pump();
    await tester.pump();

    expect(
      find.text(PersonalInsightsCopy.regeneratedConfirmation),
      findsNothing,
    );
    expect(find.text(OraclyL10n.t('insights.retry')), findsOneWidget);
  });

  testWidgets('a successful regenerate confirms only after ready', (
    tester,
  ) async {
    final service = _scripted();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: LocalStorage.ephemeral(),
        overrides: [
          personalInsightsControllerProvider.overrideWith((ref) {
            final controller = PersonalInsightsController(service);
            controller.load();
            return controller;
          }),
        ],
        child: const MaterialApp(home: PersonalInsightsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text(PersonalInsightsCopy.regenerateAction));
    await tester.pump();
    await tester.pump();
    expect(
      find.text(PersonalInsightsCopy.regeneratedConfirmation),
      findsOneWidget,
    );
    expect(find.text('Hello sentinel'), findsOneWidget);
  });

  testWidgets('a failed hide does not confirm success', (tester) async {
    final service = _scripted()..hideResult = false;
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: LocalStorage.ephemeral(),
        overrides: [
          personalInsightsControllerProvider.overrideWith((ref) {
            final controller = PersonalInsightsController(service);
            controller.load();
            return controller;
          }),
        ],
        child: const MaterialApp(home: PersonalInsightsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text(PersonalInsightsCopy.hideAction));
    await tester.pump();
    await tester.pump();
    expect(find.text(PersonalInsightsCopy.hiddenConfirmation), findsNothing);
    expect(find.text('A theme'), findsOneWidget);
  });

  testWidgets('insights error retry stays reachable on a short phone', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 568));
    final service = _scripted()..fail = true;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 568),
          textScaler: TextScaler.linear(1.4),
        ),
        child: buildProviderScopeHarness(
          storage: LocalStorage.ephemeral(),
          overrides: [
            personalInsightsControllerProvider.overrideWith((ref) {
              final controller = PersonalInsightsController(service);
              controller.load();
              return controller;
            }),
          ],
          child: const MaterialApp(home: PersonalInsightsScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text(OraclyL10n.t('insights.retry')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _SelectiveStorage extends LocalStorage {
  _SelectiveStorage() : super.ephemeral();

  bool failHidden = false;

  @override
  Future<bool> setStringList(String key, List<String> values) async {
    if (failHidden && key == 'personal_insights_hidden') return false;
    return super.setStringList(key, values);
  }
}

class _ScriptedInsights extends PersonalInsightsExperienceService {
  _ScriptedInsights()
    : super(
        reflectionEngine: ReflectionEngineService(
          intelligence: const IntelligenceLayerService(_UnusedIntelligence()),
        ),
        preferences: PersonalInsightsPreferencesRepository(
          LocalStorage.ephemeral(),
        ),
      );

  bool fail = false;
  bool hideResult = true;

  @override
  Future<InsightReflectionSummary> generate({DateTime? asOf}) async {
    if (fail) throw StateError('regen-failed');
    return InsightReflectionSummary(
      salutation: 'Hello sentinel',
      generatedAt: DateTime(2026, 9, 1),
      insights: [
        Insight(
          id: 'raw-id-sentinel',
          category: InsightCategory.recurringTheme,
          title: 'A theme',
          body: 'Only the observation',
          generatedAt: DateTime(2026, 9, 1),
        ),
      ],
    );
  }

  @override
  Future<InsightReflectionSummary> applyPrivacyFilters(
    InsightReflectionSummary summary,
  ) async {
    return summary;
  }

  @override
  Future<bool> hideInsight(String id) async => hideResult;
}

_ScriptedInsights _scripted() => _ScriptedInsights();

class _UnusedIntelligence implements IntelligenceRepository {
  const _UnusedIntelligence();

  @override
  Future<IntelligenceSnapshot> loadSnapshot() => throw UnimplementedError();

  @override
  Future<List<ReadingModel>> getReadings() => throw UnimplementedError();

  @override
  Future<List<FavoriteCardRef>> getFavoriteCards() =>
      throw UnimplementedError();

  @override
  Future<List<ReflectionEntry>> getReflections() => throw UnimplementedError();

  @override
  Future<List<ConversationRecord>> getConversations() =>
      throw UnimplementedError();

  @override
  Future<List<RitualHistoryEntry>> getRitualHistory() =>
      throw UnimplementedError();
}
