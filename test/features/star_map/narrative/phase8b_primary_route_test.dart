/// Phase 8B — primary archive leaf flag-aware routing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/star_map/models/star_map_reading.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_orchestrator_providers.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_error_state.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_narrative_live_screen.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_primary_leaf_open.dart';

import 'phase8b1_route_support.dart';
import 'phase8b_test_support.dart';

const _reading = StarMapReading(
  overview: StarMapOverview(
    whatItSays: 'Calm sky.',
    dominantEnergy: 'Stillness',
    mainMessage: 'Pause.',
  ),
  skyMessage: StarMapSkyMessage(
    today: 'Breathe.',
    interpretation: 'Quiet.',
    advice: 'One step.',
  ),
  karmic: StarMapKarmicReading(
    theme: 'Rest',
    learning: 'Slow.',
    interpretation: 'Note.',
    takeaway: 'Step.',
    promptQuestion: 'What do you need?',
  ),
  planets: [],
  sunLabel: 'Leo',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(BirthTimezoneDatabase.ensureInitialized);
  tearDown(yildiznameNarrativeFlagReset);

  testWidgets('A flag false → legacy opener, no Narrative screen', (
    tester,
  ) async {
    yildiznameNarrativeFlagOverride(false);
    var legacy = 0;
    var navigating = false;
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await StarMapPrimaryLeafOpen.open(
      context: ctx,
      reading: _reading,
      isNavigating: () => navigating,
      setNavigating: (v) => navigating = v,
      openLegacySky: (_, _, {profile}) => legacy++,
    );
    expect(legacy, 1);
    expect(navigating, isFalse);
    expect(find.byType(StarMapNarrativeLiveScreen), findsNothing);
  });

  testWidgets('B/C flag true + E1 → legacy, provider 0, no Narrative screen', (
    tester,
  ) async {
    yildiznameNarrativeFlagOverride(true);
    final storage = LocalStorage.ephemeral({
      UserLocalDataIsolation.ownerKey: 'owner-a',
    });
    final orch = phase8bOrchestrator(storage: storage, chart: phase8bE1());
    var legacy = 0;
    var navigating = false;
    late BuildContext ctx;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [yildiznameLiveOrchestratorProvider.overrideWithValue(orch)],
        child: MaterialApp(
          home: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await StarMapPrimaryLeafOpen.open(
      context: ctx,
      reading: _reading,
      isNavigating: () => navigating,
      setNavigating: (v) => navigating = v,
      openLegacySky: (_, _, {profile}) => legacy++,
    );
    expect(legacy, 1);
    expect(navigating, isFalse);
    expect(find.byType(StarMapNarrativeLiveScreen), findsNothing);
  });

  testWidgets('8B.1 flag true + owner unavailable → host, never legacy', (
    tester,
  ) async {
    yildiznameNarrativeFlagOverride(true);
    final storage = phase8bStorage(owner: '');
    final gen = Phase8bGen();
    final orch = phase8bOrchestrator(
      storage: storage,
      chart: phase8bE4(),
      generate: gen.call,
    );
    final ctx = await phase8b1PumpHub(tester, storage: storage, orch: orch);
    final nav = Phase8b1Nav()..tap(ctx);
    await phase8b1Advance(tester);
    expect(nav.legacy, 0);
    expect(gen.calls, 0);
    expect(find.byType(StarMapNarrativeLiveScreen), findsOneWidget);
    expect(find.byType(StarMapErrorState), findsOneWidget);
  });

  testWidgets('double tap while navigating → single open', (tester) async {
    yildiznameNarrativeFlagOverride(false);
    var legacy = 0;
    var navigating = false;
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    Future<void> tap() => StarMapPrimaryLeafOpen.open(
      context: ctx,
      reading: _reading,
      isNavigating: () => navigating,
      setNavigating: (v) => navigating = v,
      openLegacySky: (_, _, {profile}) {
        legacy++;
        navigating = true;
      },
    );
    await Future.wait([tap(), tap()]);
    expect(legacy, 1);
  });
}
