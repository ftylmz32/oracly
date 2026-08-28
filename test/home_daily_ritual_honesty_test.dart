/// P0 — live Home daily ritual is observational, not fake energy.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/notifications/memory_notification_port.dart';
import 'package:oracly_new/core/notifications/oracly_notification_providers.dart';
import 'package:oracly_new/core/universe/oracly_universe_layer.dart';
import 'package:oracly_new/core/universe/oracly_universe_state.dart';
import 'package:oracly_new/features/daily_energy/services/daily_energy_service.dart';
import 'package:oracly_new/features/daily_ritual/services/daily_ritual_reflections.dart';
import 'package:oracly_new/features/daily_ritual/widgets/daily_ritual_card.dart';
import 'package:oracly_new/features/gems/widgets/oracly_live_gem_capsule.dart';
import 'package:oracly_new/features/home/reference/home_reference_greeting.dart';
import 'package:oracly_new/features/home/reference/home_reference_header.dart';
import 'package:oracly_new/features/home/reference/home_reference_scope.dart';
import 'package:oracly_new/features/home/reference/home_reference_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  final morning = OraclyUniverseState.current(DateTime(2026, 8, 9, 8));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
  });

  testWidgets('Home mounts DailyRitualCard without fake energy claims',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MaterialApp(
          home: OraclyUniverseScope(
            state: morning,
            child: HomeReferenceScope(
              layout: HomeReferenceTokens.layoutFor(700),
              child: const Scaffold(body: DailyRitualCard()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(DailyRitualCard), findsOneWidget);
    // Hero title is ritual time (Sabah/…), not the static catalogue key.
    expect(
      find.text(DailyRitualReflections.ritualLabel(morning)),
      findsOneWidget,
    );
    expect(find.text(DailyRitualReflections.welcome(morning)), findsOneWidget);
    expect(find.text('Devamını Keşfet'), findsOneWidget);
    expect(find.text('Kart çek'), findsNothing);

    expect(find.text('Bugünkü Enerjin'), findsNothing);
    expect(find.text('Yüksek'), findsNothing);
    expect(find.text('Orta'), findsNothing);
    expect(find.text('Düşük'), findsNothing);
    expect(
      DailyEnergyService.readingFor().luckyNumber,
      7,
      reason: 'mock service still exists off Home; Home must not show it',
    );
    expect(find.text('7'), findsNothing);
    expect(find.textContaining('Ametist'), findsNothing);
    expect(find.textContaining('yapay zek'), findsNothing);
    expect(find.textContaining('Evren bugün seninle'), findsNothing);
    expect(find.textContaining('evren seninle konuşmak'), findsNothing);
  });

  test('live Home greeting stays off DailyEnergyService claims', () {
    expect(
      HomeReferenceGreeting.referenceSubtitle,
      isNot(contains('evren seninle konuşmak')),
    );
    expect(DailyEnergyService.readingFor().summary, contains('Bugün'));
    expect(
      HomeReferenceGreeting.referenceSubtitle,
      isNot(DailyEnergyService.readingFor().summary),
    );
  });

  test('daily ritual copy stays deterministic for the same moment', () {
    final again = OraclyUniverseState.current(DateTime(2026, 8, 9, 8));
    expect(
      DailyRitualReflections.reflection(morning),
      DailyRitualReflections.reflection(again),
    );
    expect(DailyRitualReflections.ritualLabel(morning), 'Sabah');
  });

  testWidgets('live Home header shows Premium pill, not gems', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          oraclyNotificationPortProvider.overrideWithValue(
            MemoryNotificationPort(),
          ),
          isFirstSessionProvider.overrideWith((ref) async => false),
        ],
        child: const MaterialApp(
          home: Scaffold(body: HomeReferenceHeader()),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(OraclyLiveGemCapsule), findsNothing);
    expect(find.text('Premium'), findsOneWidget);
    expect(find.text('ORACLY'), findsOneWidget);
    expect(find.text('120'), findsNothing);
    expect(find.textContaining('Menü'), findsNothing);
  });

}
