/// Live Home Today — Daily Message teaser beside untouched DailyRitualCard.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/universe/oracly_universe_layer.dart';
import 'package:oracly_new/core/universe/oracly_universe_state.dart';
import 'package:oracly_new/features/daily_message/copy/daily_message_copy.dart';
import 'package:oracly_new/features/daily_message/data/daily_return_store.dart';
import 'package:oracly_new/features/daily_message/presentation/screens/daily_message_screen.dart';
import 'package:oracly_new/features/daily_message/services/daily_message_session.dart';
import 'package:oracly_new/features/daily_ritual/services/card_of_the_day_store.dart';
import 'package:oracly_new/features/daily_ritual/widgets/daily_ritual_card.dart';
import 'package:oracly_new/features/home/reference/home_reference_scope.dart';
import 'package:oracly_new/features/home/reference/home_reference_tokens.dart';
import 'package:oracly_new/features/home/reference/home_today_trace.dart';
import 'package:oracly_new/features/home/widgets/home_daily_message_teaser.dart';
import 'package:oracly_new/features/personal_discovery/data/discovery_surface_memory.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/personal_discovery/providers/personal_discovery_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('tr'));

  Future<LocalStorage> openStorage() async {
    SharedPreferences.setMockInitialValues({});
    return LocalStorage.open();
  }

  Widget todayHarness(
    LocalStorage storage, {
    List<Override> overrides = const [],
  }) {
    final morning = OraclyUniverseState.current(DateTime(2026, 8, 29, 8));
    return buildProviderScopeHarness(
      storage: storage,
      overrides: overrides,
      child: MaterialApp(
        home: OraclyUniverseScope(
          state: morning,
          child: HomeReferenceScope(
            layout: HomeReferenceTokens.layoutFor(852),
            child: const Scaffold(
              body: SingleChildScrollView(child: HomeTodayTrace()),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> settleProviders(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('Today keeps DailyRitualCard and shows message teaser', (
    tester,
  ) async {
    final storage = await openStorage();
    await tester.pumpWidget(
      todayHarness(
        storage,
        overrides: [
          personalDiscoveryProfileProvider.overrideWith(
            (ref) async => PersonalDiscoveryProfile.empty,
          ),
        ],
      ),
    );
    await settleProviders(tester);

    expect(find.byType(DailyRitualCard), findsOneWidget);
    expect(find.text('Bugünün İzi'), findsOneWidget);
    expect(find.byType(HomeDailyMessageTeaser), findsOneWidget);
    expect(find.text(DailyMessageCopy.prompt), findsOneWidget);

    final message = DailyMessageSession.resolve(
      store: DailyReturnStore(storage),
      day: DateTime.now(),
      discovery: PersonalDiscoveryProfile.empty,
    );
    expect(find.text(message.text), findsOneWidget);

    final body = tester.widget<Text>(find.text(message.text));
    expect(body.maxLines, 2);
  });

  testWidgets('teaser tap opens existing Daily Message screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = await openStorage();
    await tester.pumpWidget(
      todayHarness(
        storage,
        overrides: [
          personalDiscoveryProfileProvider.overrideWith(
            (ref) async => PersonalDiscoveryProfile.empty,
          ),
        ],
      ),
    );
    await settleProviders(tester);

    final message = DailyMessageSession.resolve(
      store: DailyReturnStore(storage),
      day: DateTime.now(),
      discovery: PersonalDiscoveryProfile.empty,
    );
    await tester.tap(find.text(message.text));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.byType(DailyMessageScreen), findsOneWidget);
    expect(find.text(DailyMessageCopy.screenTitle), findsOneWidget);
  });

  testWidgets('Home persist uses daily_return store only', (tester) async {
    final storage = await openStorage();
    expect(CardOfTheDayStore(storage).readToday(), isNull);
    expect(DailyReturnStore(storage).readToday(DateTime.now()), isNull);

    await tester.pumpWidget(
      todayHarness(
        storage,
        overrides: [
          personalDiscoveryProfileProvider.overrideWith(
            (ref) async => PersonalDiscoveryProfile.empty,
          ),
        ],
      ),
    );
    await settleProviders(tester);

    final stored = DailyReturnStore(storage).readToday(DateTime.now());
    expect(stored, isNotNull);
    expect(stored!.text, isNotEmpty);
    expect(CardOfTheDayStore(storage).readToday(), isNull);
    expect(find.byType(DailyRitualCard), findsOneWidget);

    final firstText = stored.text;
    await DailyMessageSession.persist(
      store: DailyReturnStore(storage),
      memory: DiscoverySurfaceMemory(storage),
      message: stored,
    );
    expect(
      DailyReturnStore(storage).readToday(DateTime.now())!.text,
      firstText,
    );
  });

  testWidgets('loading personalization does not persist generic snapshot', (
    tester,
  ) async {
    final storage = await openStorage();
    final pending = Completer<PersonalDiscoveryProfile>();

    await tester.pumpWidget(
      todayHarness(
        storage,
        overrides: [
          personalDiscoveryProfileProvider.overrideWith(
            (ref) => pending.future,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.byType(HomeTodayTrace), findsOneWidget);
    expect(find.byType(DailyRitualCard), findsOneWidget);
    expect(find.text(DailyMessageCopy.prompt), findsNothing);
    expect(DailyReturnStore(storage).readToday(DateTime.now()), isNull);

    pending.complete(PersonalDiscoveryProfile.empty);
    await settleProviders(tester);

    expect(find.text(DailyMessageCopy.prompt), findsOneWidget);
    final stored = DailyReturnStore(storage).readToday(DateTime.now());
    expect(stored, isNotNull);
    expect(stored!.text, isNotEmpty);
    expect(find.byType(DailyRitualCard), findsOneWidget);
  });

  testWidgets('teaser failure path keeps DailyRitualCard', (tester) async {
    final storage = await openStorage();
    await tester.pumpWidget(
      todayHarness(
        storage,
        overrides: [
          personalDiscoveryProfileProvider.overrideWith((ref) async {
            throw StateError('discovery failed');
          }),
        ],
      ),
    );
    await settleProviders(tester);

    expect(find.byType(HomeTodayTrace), findsOneWidget);
    expect(find.byType(DailyRitualCard), findsOneWidget);
    expect(find.text(DailyMessageCopy.prompt), findsNothing);
    expect(find.textContaining('discovery failed'), findsNothing);
    expect(find.textContaining('StateError'), findsNothing);
    expect(tester.takeException(), isNull);
    expect(DailyReturnStore(storage).readToday(DateTime.now()), isNull);
  });
}
