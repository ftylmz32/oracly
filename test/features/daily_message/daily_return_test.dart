/// Daily return — cache, anti-repeat, honest empty history, free action.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/features/daily_message/copy/daily_message_copy.dart';
import 'package:oracly_new/features/daily_message/data/daily_return_store.dart';
import 'package:oracly_new/features/daily_message/presentation/screens/daily_message_screen.dart';
import 'package:oracly_new/features/daily_message/presentation/widgets/daily_return_cta.dart';
import 'package:oracly_new/features/daily_message/services/daily_message_service.dart';
import 'package:oracly_new/features/daily_message/services/daily_message_session.dart';
import 'package:oracly_new/features/personal_discovery/data/discovery_surface_memory.dart';
import 'package:oracly_new/features/personal_discovery/models/cross_discovery_insight.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_theme_strength.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_insight.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:oracly_new/shared/widgets/oracly_gold_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('same user on different days gets different content', () {
    const themes = ['sınırlar'];
    final a = DailyMessageService.forDay(
      day: DateTime(2026, 8, 16),
      profileName: 'Fatih',
      themes: themes,
    );
    final b = DailyMessageService.forDay(
      day: DateTime(2026, 8, 17),
      profileName: 'Fatih',
      themes: themes,
      previousTheme: a.theme,
      previousText: a.text,
      previousAction: a.action,
    );
    expect(a.text, isNot(equals(b.text)));
    expect(b.text, isNot(contains(a.text)));
  });

  test('same day snapshot is not regenerated', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final store = DailyReturnStore(storage);
    final memory = DiscoverySurfaceMemory(storage);
    final day = DateTime(2026, 8, 16, 9);
    final first = DailyMessageSession.resolve(
      store: store,
      day: day,
      profileName: 'Fatih',
    );
    await DailyMessageSession.persist(
      store: store,
      memory: memory,
      message: first,
    );
    final second = DailyMessageSession.resolve(
      store: store,
      day: DateTime(2026, 8, 16, 21),
      profileName: 'Fatih',
      discovery: const PersonalDiscoveryProfile(
        tarotCount: 4,
        coffeeCount: 2,
      ),
    );
    expect(second.text, first.text);
    expect(second.action, first.action);
    expect(second.theme, first.theme);
  });

  test('empty history stays general and invents no personal fact', () {
    final note = DailyMessageService.forDay(day: DateTime(2026, 8, 16));
    expect(note.theme, isNull);
    expect(note.sunSign, isNull);
    expect(note.text, isNotEmpty);
    expect(note.text.toLowerCase(), isNot(contains('fatih')));
    expect(note.text, isNot(contains('son keşiflerinde')));
    expect(note.text, isNot(contains('son yorumlarında')));
    expect(note.text, isNot(contains('güzel gelişmeler')));
    expect(note.text.toLowerCase(), isNot(contains('kendinize güven')));
    expect(note.text.toLowerCase(), isNot(contains('%')));
    expect(note.action, DailyReturnAction.talkToOr);
    expect(DailyMessageCopy.action(note.action), DailyMessageCopy.talkToOr);
  });

  test('rich history uses a real theme and never yesterday\'s wording', () {
    final first = DailyMessageService.forDay(
      day: DateTime(2026, 8, 16),
      insight: const PersonalInsight(
        theme: 'aşk',
        sourceCount: 2,
        confidence: DiscoveryThemeStrength.recurring,
        recency: 'recent',
        explanation: 'İki alanda tekrar etti.',
      ),
      themes: const ['aşk', 'iletişim'],
      hasDiscoveries: true,
      sunSign: 'Koç',
      personality: AiPersonality.gentle,
    );
    final next = DailyMessageService.forDay(
      day: DateTime(2026, 8, 17),
      insight: const PersonalInsight(
        theme: 'iletişim',
        sourceCount: 2,
        confidence: DiscoveryThemeStrength.recurring,
        recency: 'recent',
        explanation: 'İki alanda tekrar etti.',
      ),
      themes: const ['aşk', 'iletişim'],
      previousTheme: first.theme,
      previousText: first.text,
      previousAction: first.action,
      recentTexts: [first.text],
      hasDiscoveries: true,
      sunSign: 'Koç',
      personality: AiPersonality.direct,
    );
    expect(first.theme, 'aşk');
    expect(next.theme, 'iletişim');
    expect(next.text.toLowerCase(), anyOf(contains('iletişim'), contains('konuş')));
    expect(next.text, isNot(equals(first.text)));
    // Theme already rotated; structure tags are optional variety, not required.
    expect(next.sunSign, 'Koç');
    expect(next.dateStamp, contains('Koç'));
    expect(next.text.toLowerCase(), isNot(contains('koç')));
    expect(next.action.isFree, isTrue);
    expect(
      {DailyReturnAction.talkToOr, DailyReturnAction.exploreTheme},
      contains(next.action),
    );
  });

  test('real recurring evidence is surfaced when insight exists', () {
    final note = DailyMessageService.forDay(
      day: DateTime(2026, 8, 20),
      insight: const PersonalInsight(
        theme: 'değişim',
        sourceCount: 3,
        confidence: DiscoveryThemeStrength.recurring,
        recency: 'recent',
        explanation: 'Son 30 günde 4 keşfinde ve 3 farklı alanda tekrar etmiş.',
      ),
      themes: const ['değişim', 'iletişim'],
      hasDiscoveries: true,
    );
    expect(note.theme, 'değişim');
    expect(note.text, contains('Son 30 günde 4 keşfinde ve 3 farklı alanda tekrar etmiş.'));
    expect(note.text.toLowerCase(), contains('değişim'));
    expect(note.text.toLowerCase(), isNot(contains('kendinize güven')));
  });

  test('evidence day modes vary structure without inventing memory', () {
    const insight = PersonalInsight(
      theme: 'karar verme',
      sourceCount: 2,
      confidence: DiscoveryThemeStrength.recurring,
      recency: 'recent',
      explanation: 'Son 14 günde 3 keşfinde tekrar etmiş.',
    );
    final texts = [
      for (var d = 1; d <= 9; d++)
        DailyMessageService.forDay(
          day: DateTime(2026, 8, d),
          insight: insight,
          themes: const ['karar verme'],
          hasDiscoveries: true,
        ).text,
    ];
    expect(texts.toSet().length, greaterThanOrEqualTo(2));
    for (final text in texts) {
      expect(text, contains('Son 14 günde 3 keşfinde tekrar etmiş.'));
      expect(text.toLowerCase(), contains('karar'));
      expect(text.toLowerCase(), isNot(contains('kehanet')));
    }
  });

  test('decision and communication stay connected to their own theme', () {
    final decision = DailyMessageService.forDay(
      day: DateTime(2026, 8, 18),
      themes: const ['karar verme'],
      hasDiscoveries: true,
    );
    final talk = DailyMessageService.forDay(
      day: DateTime(2026, 8, 18),
      themes: const ['iletişim'],
      hasDiscoveries: true,
    );
    expect(decision.text, contains('karar'));
    expect(talk.text.toLowerCase(), anyOf(contains('iletişim'), contains('konuş')));
    expect(decision.text, isNot(equals(talk.text)));
  });

  test('legacy actions stay free and copy never sells premium', () {
    for (final action in DailyReturnAction.values) {
      expect(action.isFree, isTrue);
      expect(DailyMessageCopy.action(action).toLowerCase(), isNot(contains('ücret')));
      expect(DailyMessageCopy.action(action).toLowerCase(), isNot(contains('premium')));
    }
  });

  testWidgets('ritual card shows prompt, moon path, and a free action',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: const MaterialApp(home: DailyMessageScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text(DailyMessageCopy.prompt), findsOneWidget);
    expect(find.byType(DailyReturnCta), findsOneWidget);
    expect(find.byType(OraclyGoldButton), findsOneWidget);
    expect(find.text(DailyMessageCopy.honesty), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('session with a rich profile uses sun sign only as a stamp', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final store = DailyReturnStore(storage);
    final note = DailyMessageSession.resolve(
      store: store,
      day: DateTime(2026, 8, 19),
      profileName: 'Fatih',
      discovery: PersonalDiscoveryProfile(
        zodiacSign: ZodiacSignId.aries,
        preferredOrStyle: AiPersonality.poetic,
        tarotCount: 3,
        coffeeCount: 2,
        crossInsights: [
          CrossDiscoveryInsight(
            theme: 'iletişim',
            sources: const ['tarot', 'coffee'],
            confidence: DiscoveryThemeStrength.recurring,
            lastObserved: DateTime(2026, 8, 18),
            sourceCount: 2,
            discoveryCount: 4,
            recencyWeight: 0.9,
          ),
        ],
      ),
    );
    expect(note.sunSign, 'Koç');
    expect(note.theme, 'iletişim');
    expect(note.text.toLowerCase(), anyOf(contains('iletişim'), contains('konuş')));
    expect(note.text.toLowerCase(), isNot(contains('fatih')));
  });
}
