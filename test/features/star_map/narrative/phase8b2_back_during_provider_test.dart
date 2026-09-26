/// Phase 8B.2 — Back while the provider call is in flight (real route).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_orchestrator_providers.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_loading_cinema.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_narrative_live_screen.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';

import 'phase8b1_route_support.dart';
import 'phase8b2_back_support.dart';
import 'phase8b_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(BirthTimezoneDatabase.ensureInitialized);
  setUp(() => yildiznameNarrativeFlagOverride(true));
  tearDown(yildiznameNarrativeFlagReset);

  Future<(Phase8b2Harness, Phase8b2HeldGen)> openHeld(
    WidgetTester tester,
  ) async {
    final h = Phase8b2Harness(phase8bStorage());
    final gen = Phase8b2HeldGen();
    await h.pump(
      tester,
      (onPersisted) => phase8bOrchestrator(
        storage: h.storage,
        chart: phase8bE4(),
        generate: gen.call,
        onPersisted: onPersisted,
      ),
    );
    h.tap();
    await phase8b1Advance(tester);
    expect(find.byType(StarMapLoadingCinema), findsOneWidget);
    expect(gen.calls, 1);
    return (h, gen);
  }

  testWidgets('Back → late approved result persists, never shown',
      (tester) async {
    final (h, gen) = await openHeld(tester);

    await h.back(tester);
    expect(find.byType(StarMapNarrativeLiveScreen), findsNothing);
    expect(find.byKey(phase8b2HubKey), findsOneWidget);
    expect(h.nav.navigating, isFalse);
    expect(h.nav.routeDone, isTrue);

    gen.release();
    await phase8b1Advance(tester);

    expect(tester.takeException(), isNull);
    expect(gen.calls, 1);
    expect((await h.saved(tester, 'owner-a')).length, 1);
    expect(h.invalidations, 1);
    expect(find.byType(StarMapNarrativeLiveScreen), findsNothing);
    expect(find.byType(StarMapReferenceResultScreen), findsNothing);
    expect(find.byKey(phase8b2HubKey), findsOneWidget);
    expect(h.analytics.completed, 0);
    expect(h.nav.legacy, 0);
    expect(h.nav.navigating, isFalse);
  });

  testWidgets('Back → release inside exit transition → no late UI/analytics',
      (tester) async {
    final (h, gen) = await openHeld(tester);

    Navigator.of(tester.element(find.byType(StarMapNarrativeLiveScreen)))
        .pop();
    gen.release();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.byType(StarMapReferenceResultScreen), findsNothing);
    expect(h.analytics.completed, 0);
    await phase8b1Advance(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(StarMapNarrativeLiveScreen), findsNothing);
    expect((await h.saved(tester, 'owner-a')).length, 1);
    expect(h.invalidations, 1);
    expect(h.analytics.completed, 0);
  });

  testWidgets('re-entry after Back starts a new transaction normally',
      (tester) async {
    final (h, gen) = await openHeld(tester);
    await h.back(tester);
    gen.release();
    await phase8b1Advance(tester);
    expect(h.nav.navigating, isFalse);

    h.tap();
    await phase8b1Advance(tester);
    expect(find.byType(StarMapNarrativeLiveScreen), findsOneWidget);
    expect(gen.calls, 2);
    gen.release();
    await phase8b1Advance(tester);

    expect(find.byType(StarMapReferenceResultScreen), findsOneWidget);
    expect(h.analytics.completed, 1);
    expect((await h.saved(tester, 'owner-a')).length, 1);
    expect(h.invalidations, 2);
    expect(tester.takeException(), isNull);
  });
}
