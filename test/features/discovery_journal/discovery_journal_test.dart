/// Keşif Günlüğü — aggregates real history only, never invents records.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/domain/models/astrology_record.dart';
import 'package:oracly_new/core/domain/models/birth_chart_record.dart';
import 'package:oracly_new/core/domain/models/conversation_record.dart';
import 'package:oracly_new/core/domain/models/dream_record.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/l10n/oracly_format.dart';
import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/core/modules/oracly_feature_registry.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/daily_message/models/daily_message.dart';
import 'package:oracly_new/features/discovery_journal/copy/discovery_journal_copy.dart';
import 'package:oracly_new/features/discovery_journal/models/discovery_journal_kind.dart';
import 'package:oracly_new/features/discovery_journal/models/discovery_journal_range.dart';
import 'package:oracly_new/features/discovery_journal/presentation/screens/discovery_journal_screen.dart';
import 'package:oracly_new/features/discovery_journal/services/discovery_journal_aggregator.dart';
import 'package:oracly_new/features/home/copy/home_discovery_copy.dart';
import 'package:oracly_new/features/home/reference/home_reference_modules.dart';
import 'package:oracly_new/features/personal_discovery/models/cross_discovery_insight.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_theme_strength.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/personal_discovery/providers/personal_discovery_providers.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

ReadingModel _reading() => ReadingModel(
      id: 'r1',
      cardId: 0,
      cardName: 'The Moon',
      cardImageAsset: 'assets/cards/moon.png',
      spreadType: 'Tek Kart',
      aiSummary: 'Sakin bir bakış.',
      createdAt: DateTime(2026, 8, 12, 21),
    );

void main() {
  setUpAll(() async {
    await OraclyFormat.ensureInitialized();
  });

  setUp(() => OraclyL10n.bind('tr'));

  test('empty sources produce no invented rows', () {
    expect(DiscoveryJournalAggregator.merge(), isEmpty);
  });

  test('merges real records newest first with honest badges', () {
    final items = DiscoveryJournalAggregator.merge(
      readings: [_reading()],
      dreams: [
        DreamRecord(
          id: 'd1',
          text: 'Denizde yürüdüm',
          analysis: 'Sakinlik',
          createdAt: DateTime(2026, 8, 13, 8),
        ),
      ],
      coffee: [
        CoffeeReading(
          id: 'c1',
          createdAt: DateTime(2026, 8, 11),
          overall: 'Bir fincanda durulmak.',
          love: '',
          career: '',
          money: '',
          nearFuture: '',
          takeaway: '',
        ),
      ],
      conversations: [
        ConversationRecord(
          id: 'or1',
          title: 'OR Companion',
          kind: 'general',
          messagesJson: [
            {'role': 'user', 'text': 'merhaba'},
          ],
          createdAt: DateTime(2026, 8, 10),
          updatedAt: DateTime(2026, 8, 10, 18),
        ),
        ConversationRecord(
          id: 'empty',
          title: 'OR Companion',
          kind: 'general',
          messagesJson: const [],
          createdAt: DateTime(2026, 8, 9),
          updatedAt: DateTime(2026, 8, 9),
        ),
      ],
    );
    expect(items.map((e) => e.kind).toList(), [
      DiscoveryJournalKind.dream,
      DiscoveryJournalKind.tarot,
      DiscoveryJournalKind.coffee,
      DiscoveryJournalKind.companion,
    ]);
    expect(items.map((e) => e.id), isNot(contains('empty')));
    expect(
      DiscoveryJournalAggregator.merge(
        palm: [
          PalmReading(
            id: 'p1',
            createdAt: DateTime(2026, 8, 14),
            hand: PalmHand.left,
            overall: 'Avuç sakin bir ritim taşıyor.',
          ),
        ],
      ).single.kind,
      DiscoveryJournalKind.palm,
    );
    expect(items.first.title, 'Denizde yürüdüm');
    expect(
      items.firstWhere((e) => e.kind == DiscoveryJournalKind.tarot).title,
      '1 Kart Açılımı',
    );
    expect(
      items.firstWhere((e) => e.kind == DiscoveryJournalKind.tarot).dateLabel,
      '12 Ağustos',
    );
    expect(
      items.firstWhere((e) => e.kind == DiscoveryJournalKind.tarot).preview,
      'Sakin bir bakış.',
    );
    expect(
      items.map((e) => DiscoveryJournalCopy.badge(e.kind)),
      containsAll(['Tarot', 'Rüya', 'Kahve', 'OR']),
    );
    expect(DiscoveryJournalCopy.badge(DiscoveryJournalKind.palm), 'El');
    expect(DiscoveryJournalCopy.badge(DiscoveryJournalKind.astrology), 'Astroloji');
    expect(DiscoveryJournalCopy.badge(DiscoveryJournalKind.starMap), 'Yıldızname');
    expect(
      DiscoveryJournalCopy.badge(DiscoveryJournalKind.dailyMessage),
      'Günün Mesajı',
    );
  });

  test('astrology, yıldızname, and saved daily snapshots stay real', () {
    final items = DiscoveryJournalAggregator.merge(
      astrology: [
        AstrologyRecord(
          id: 'a1',
          sign: 'Koç',
          horoscope: 'Acele etme; tek adım yeter.',
          date: DateTime(2026, 8, 15),
        ),
      ],
      starChart: BirthChartRecord(
        id: 's1',
        createdAt: DateTime(2026, 8, 1),
        payload: const {},
      ),
      daily: [
        DailyMessage(
          text: 'Bugün neyi netleştirmek istiyorsun?',
          day: DateTime(2026, 8, 16),
          theme: 'netleşme',
        ),
      ],
    );
    expect(items.map((e) => e.kind).toList(), [
      DiscoveryJournalKind.dailyMessage,
      DiscoveryJournalKind.astrology,
      DiscoveryJournalKind.starMap,
    ]);
    expect(items.map((e) => e.title), containsAll(['Koç', 'Yıldızname', 'netleşme']));
    expect(items.first.preview, contains('netleştirmek'));
  });

  test('story uses real themes and never invents', () {
    expect(
      DiscoveryJournalCopy.story(const ['değişim', 'karar verme']),
      'Son dönemde değişim ve karar verme konusu birkaç farklı keşfinde '
      'yeniden karşına çıkıyor.',
    );
    expect(
      DiscoveryJournalCopy.story(
        const ['değişim', 'karar verme', 'iletişim', 'dinlenme'],
      ),
      'Son dönemde değişim, karar verme, iletişim ve dinlenme '
      'birkaç farklı keşfinde yeniden karşına çıkıyor.',
    );
    expect(DiscoveryJournalCopy.story(const []), DiscoveryJournalCopy.storyNone);
    expect(DiscoveryJournalCopy.heroTheme('değişim'), 'DEĞİŞİM');
    expect(DiscoveryJournalCopy.heroTheme('iletişim'), 'İLETİŞİM');
    expect(
      DiscoveryJournalCopy.emptyMessage.toLowerCase(),
      contains('birik'),
    );
    expect(
      DiscoveryJournalCopy.emptyMessage.toLowerCase(),
      isNot(contains('kaçır')),
    );
    expect(DiscoveryJournalCopy.archiveTitle.toLowerCase(), contains('yol'));
  });

  test('insight names a real theme without promising the future', () {
    final item = CrossDiscoveryInsight(
      theme: 'değişim',
      sources: const ['coffee', 'palm', 'dream', 'tarot'],
      confidence: DiscoveryThemeStrength.recurring,
      lastObserved: DateTime(2026, 8, 10),
      sourceCount: 4,
      discoveryCount: 4,
      recencyWeight: 0.9,
    );
    expect(
      DiscoveryJournalCopy.insight(item, now: DateTime(2026, 8, 16)),
      'Son 30 günde Değişim konusu 4 farklı keşfinde yeniden karşına çıkıyor. '
      'Tek sonuca bağlamazdım; yine de canlı duruyor.',
    );
    expect(
      DiscoveryJournalCopy.insight(item, now: DateTime(2026, 10, 1)),
      'Son dönemde Değişim konusu 4 farklı keşfinde yeniden karşına çıkıyor. '
      'Tek sonuca bağlamazdım; yine de canlı duruyor.',
    );
    expect(DiscoveryJournalCopy.philosophy, contains('anlamına gelmez'));
  });

  test('time range hides older real records without inventing new ones', () {
    final items = DiscoveryJournalAggregator.merge(
      readings: [
        ReadingModel(
          id: 'old',
          cardId: 0,
          cardName: 'The Moon',
          cardImageAsset: 'assets/cards/moon.png',
          spreadType: 'Tek Kart',
          aiSummary: 'Sakin bir bakış.',
          createdAt: DateTime(2026, 8, 1),
        ),
      ],
      dreams: [
        DreamRecord(
          id: 'd1',
          text: 'Denizde yürüdüm',
          analysis: 'Sakinlik',
          createdAt: DateTime(2026, 8, 16),
        ),
      ],
    );
    final week = DiscoveryJournalAggregator.inRange(
      items,
      DiscoveryJournalRange.last7,
      now: DateTime(2026, 8, 16, 12),
    );
    expect(week.map((e) => e.id), ['d1']);
    expect(
      DiscoveryJournalAggregator.inRange(
        items,
        DiscoveryJournalRange.all,
        now: DateTime(2026, 8, 16),
      ),
      hasLength(2),
    );
  });

  test('feature is live, remembered, and not on the Home 3x2 grid', () {
    final module = OraclyFeatureRegistry.byId(OraclyFeatureId.discoveryJournal);
    expect(module?.isLive, isTrue);
    expect(module?.routeName, OraclyRoutes.discoveryJournal);
    expect(module?.homeBand, isNull);
    expect(
      HomeReferenceModules.list().map((m) => HomeDiscoveryCopy.title(m.id).toLowerCase()),
      isNot(contains('keşif günlüğü')),
    );
  });

  testWidgets('empty archive shows a truthful state', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: const MaterialApp(home: DiscoveryJournalScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(DiscoveryJournalCopy.screenTitle), findsOneWidget);
    expect(find.text(DiscoveryJournalCopy.subtitle), findsOneWidget);
    expect(find.text(DiscoveryJournalCopy.emptyTitle), findsOneWidget);
    expect(find.text(DiscoveryJournalCopy.emptyMessage), findsOneWidget);
    expect(find.text('BUGÜN SANA NE İYİ GELİR?'), findsOneWidget);
    expect(find.text('Bugünün mesajı'), findsOneWidget);
    expect(find.text(DiscoveryJournalCopy.nextCoffee), findsNothing);
    expect(find.text(DiscoveryJournalCopy.nextPalm), findsNothing);
    expect(find.text(DiscoveryJournalCopy.nextOr), findsNothing);
    expect(find.text(DiscoveryJournalCopy.openCta), findsNothing);
    expect(find.textContaining('ruh eşi'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('persisted tarot history appears as a real row', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'or_reading_history': [jsonEncode(_reading().toJson())],
    });
    final storage = await LocalStorage.open();
    final profile = PersonalDiscoveryProfile(
      crossInsights: [
        CrossDiscoveryInsight(
          theme: 'değişim',
          sources: const ['coffee', 'dream', 'reflection'],
          confidence: DiscoveryThemeStrength.recurring,
          lastObserved: DateTime.now().subtract(const Duration(days: 18)),
          sourceCount: 3,
          discoveryCount: 4,
          recencyWeight: 0.9,
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          personalDiscoveryProfileProvider.overrideWith((ref) async => profile),
        ],
        child: const MaterialApp(home: DiscoveryJournalScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('1 Kart Açılımı'), findsOneWidget);
    expect(find.text('12 Ağustos'), findsOneWidget);
    expect(find.text('The Moon'), findsNothing);
    expect(find.text('Tarot'), findsOneWidget);
    expect(find.text(DiscoveryJournalCopy.subtitle), findsOneWidget);
    expect(find.text(DiscoveryJournalCopy.crossTitle), findsOneWidget);
    expect(
      find.text(DiscoveryJournalCopy.story(const ['değişim'])),
      findsOneWidget,
    );
    expect(find.text('DEĞİŞİM'), findsOneWidget);
    expect(
      find.text(
        DiscoveryJournalCopy.insight(profile.crossInsights.first),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Kahve'), findsWidgets);
    expect(find.text(DiscoveryJournalCopy.archiveTitle), findsOneWidget);
    expect(find.text(DiscoveryJournalCopy.philosophy), findsOneWidget);
    expect(find.text(DiscoveryJournalCopy.filterAll), findsWidgets);
    expect(find.text(DiscoveryJournalCopy.filter7), findsNothing);
    expect(find.text(DiscoveryJournalCopy.filter30), findsNothing);
    expect(find.text(DiscoveryJournalCopy.emptyTitle), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
