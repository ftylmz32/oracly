import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/home_personal_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/universe/oracly_ritual_time.dart';
import 'package:oracly_new/core/universe/oracly_universe_layer.dart';
import 'package:oracly_new/core/universe/oracly_universe_state.dart';
import 'package:oracly_new/features/home/master/home_master_page.dart';
import 'package:oracly_new/features/home/reference/home_reference_hero.dart';
import 'package:oracly_new/features/home/reference/home_reference_hero_atmosphere.dart';
import 'package:oracly_new/features/home/theme/home_ritual_atmosphere.dart';
import 'package:oracly_new/features/home/theme/home_ritual_visuals.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpPeriod(
    WidgetTester tester, {
    required int hour,
    required Size size,
    bool reduceMotion = false,
  }) async {
    final time = OraclyRitualAtmosphere.fromHour(hour);
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            disableAnimations: reduceMotion,
            devicePixelRatio: 3,
          ),
          child: OraclyUniverseScope(
            state: OraclyUniverseState.current(DateTime(2026, 6, 15, hour, 30)),
            child: Scaffold(
              body: Stack(
                children: [
                  const HomeRitualAtmosphere(),
                  Align(
                    alignment: Alignment.topCenter,
                    child: HomeReferenceHero(
                      hello: HomePersonalCopy.greeting(time: time),
                      invite: HomePersonalCopy.ritualWelcome(time),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('hero and Home wash follow the same scoped ritual time', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const hours = <int>[8, 14, 19, 1];
    for (final hour in hours) {
      await pumpPeriod(tester, hour: hour, size: const Size(390, 844));
      final time = OraclyRitualAtmosphere.fromHour(hour);
      final hero = tester.widget<HomeReferenceHeroAtmosphere>(
        find.byType(HomeReferenceHeroAtmosphere),
      );
      final wash = tester.widget<HomeRitualWash>(find.byType(HomeRitualWash));
      expect(hero.visual.time, time);
      expect(wash.visual.time, time);
      expect(hero.visual.heroPlateOpacity, wash.visual.heroPlateOpacity);
      expect(find.text(HomePersonalCopy.greeting(time: time)), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    final morning = HomeRitualVisuals.of(OraclyRitualTime.morning);
    final night = HomeRitualVisuals.of(OraclyRitualTime.night);
    expect(morning.heroPlateOpacity, isNot(night.heroPlateOpacity));
  });

  testWidgets('reduced motion keeps the ritual period while breath is still', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpPeriod(
      tester,
      hour: 9,
      size: const Size(390, 844),
      reduceMotion: true,
    );
    final hero = tester.widget<HomeReferenceHeroAtmosphere>(
      find.byType(HomeReferenceHeroAtmosphere),
    );
    expect(hero.visual.time, OraclyRitualTime.morning);
    expect(hero.t, 0.38);
    expect(tester.takeException(), isNull);
  });

  for (final size in const <Size>[Size(320, 568), Size(390, 844)]) {
    testWidgets('hero has no overflow at ${size.width}x${size.height}', (
      tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpPeriod(tester, hour: 15, size: size);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('live Home wash and hero share the ticker ritual time', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: const MaterialApp(home: HomeMasterPage()),
      ),
    );
    await tester.pump();
    final expected = OraclyRitualAtmosphere.fromHour(DateTime.now().hour);
    final hero = tester.widget<HomeReferenceHeroAtmosphere>(
      find.byType(HomeReferenceHeroAtmosphere),
    );
    final wash = tester.widget<HomeRitualWash>(find.byType(HomeRitualWash));
    expect(hero.visual.time, expected);
    expect(wash.visual.time, expected);
    expect(tester.takeException(), isNull);
  });
}
