/// Phase 8B.1 — real primary route: typed failures never become legacy.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_orchestrator_providers.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_error_state.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_narrative_live_screen.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';

import 'phase8a2_json_mutate.dart';
import 'phase8b1_route_support.dart';
import 'phase8b_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(BirthTimezoneDatabase.ensureInitialized);
  setUp(() => yildiznameNarrativeFlagOverride(true));
  tearDown(yildiznameNarrativeFlagReset);

  testWidgets('F owner unavailable → error host, legacy 0, provider 0', (
    tester,
  ) async {
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

    expect(find.byType(StarMapNarrativeLiveScreen), findsOneWidget);
    expect(find.byType(StarMapErrorState), findsOneWidget);
    expect(find.text(ResilienceCopy.temporaryFailure), findsOneWidget);
    expect(phase8b1RetryNode(ResilienceCopy.retryAction), findsOneWidget);
    expect(find.byType(StarMapReferenceResultScreen), findsNothing);
    expect(nav.legacy, 0);
    expect(gen.calls, 0);
    expect(nav.navigating, isTrue);

    Navigator.of(tester.element(find.byType(StarMapNarrativeLiveScreen))).pop();
    await phase8b1Advance(tester, frames: 6);
    expect(nav.navigating, isFalse);
  });

  testWidgets('G invalid evidence after one repair → error, legacy 0', (
    tester,
  ) async {
    final storage = phase8bStorage();
    final gen = Phase8bGen();
    var repairs = 0;
    final orch = phase8bOrchestrator(
      storage: storage,
      chart: phase8aRemoveAscendant(phase8bE4()),
      generate: gen.call,
      onRepair: () => repairs++,
    );
    final ctx = await phase8b1PumpHub(tester, storage: storage, orch: orch);
    final nav = Phase8b1Nav()..tap(ctx);
    await phase8b1Advance(tester);

    expect(find.byType(StarMapErrorState), findsOneWidget);
    expect(find.text(ResilienceCopy.analysisUnavailable), findsOneWidget);
    expect(phase8b1RetryNode(ResilienceCopy.retryAction), findsOneWidget);
    expect(find.text('owner-a'), findsNothing);
    expect(nav.legacy, 0);
    expect(gen.calls, 0);
    expect(repairs, 1);
  });

  testWidgets('B/C flag true + E1/E3 → legacy, no host, provider 0', (
    tester,
  ) async {
    for (final chart in [phase8bE1(), phase8bE3()]) {
      final storage = phase8bStorage();
      final gen = Phase8bGen();
      final orch = phase8bOrchestrator(
        storage: storage,
        chart: chart,
        generate: gen.call,
      );
      final ctx = await phase8b1PumpHub(tester, storage: storage, orch: orch);
      final nav = Phase8b1Nav()..tap(ctx);
      await phase8b1Advance(tester, frames: 3);
      expect(nav.legacy, 1);
      expect(gen.calls, 0);
      expect(nav.navigating, isFalse);
      expect(find.byType(StarMapNarrativeLiveScreen), findsNothing);
    }
  });

  testWidgets('A flag false + E4 → legacy, provider 0', (tester) async {
    yildiznameNarrativeFlagOverride(false);
    final storage = phase8bStorage();
    final gen = Phase8bGen();
    var loads = 0;
    final orch = phase8bOrchestrator(
      storage: storage,
      chart: phase8bE4(),
      generate: gen.call,
      onLoadChart: () => loads++,
    );
    final ctx = await phase8b1PumpHub(tester, storage: storage, orch: orch);
    final nav = Phase8b1Nav()..tap(ctx);
    await phase8b1Advance(tester, frames: 3);
    expect(nav.legacy, 1);
    expect(gen.calls, 0);
    expect(loads, 0);
    expect(find.byType(StarMapNarrativeLiveScreen), findsNothing);
  });

  testWidgets('double tap → one prepare, one route', (tester) async {
    final storage = phase8bStorage(owner: '');
    var loads = 0;
    final orch = phase8bOrchestrator(
      storage: storage,
      chart: phase8bE4(),
      generate: Phase8bGen().call,
      onLoadChart: () => loads++,
    );
    final ctx = await phase8b1PumpHub(tester, storage: storage, orch: orch);
    final nav = Phase8b1Nav()
      ..tap(ctx)
      ..tap(ctx);
    await phase8b1Advance(tester);
    expect(find.byType(StarMapNarrativeLiveScreen), findsOneWidget);
    expect(nav.legacy, 0);
    expect(loads, 0);
  });
}
