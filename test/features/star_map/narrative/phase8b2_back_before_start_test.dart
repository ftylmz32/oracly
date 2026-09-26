/// Phase 8B.2 — Back before the first scheduled live execution runs.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_orchestrator_providers.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_narrative_live_screen.dart';

import 'phase8b1_route_support.dart';
import 'phase8b2_back_support.dart';
import 'phase8b_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(BirthTimezoneDatabase.ensureInitialized);
  setUp(() => yildiznameNarrativeFlagOverride(true));
  tearDown(yildiznameNarrativeFlagReset);

  testWidgets('pop in the host first frame → no provider, no artifact',
      (tester) async {
    final h = Phase8b2Harness(phase8bStorage());
    final gen = Phase8b2HeldGen();
    var hostBuiltBeforePop = false;
    await h.pump(
      tester,
      (onPersisted) => phase8bOrchestrator(
        storage: h.storage,
        chart: phase8bE4(),
        generate: gen.call,
        onPersisted: onPersisted,
      ),
    );
    h.observer.afterFirstFrame = (navigator) {
      hostBuiltBeforePop = find
          .byType(StarMapNarrativeLiveScreen, skipOffstage: false)
          .evaluate()
          .isNotEmpty;
      navigator.pop();
    };
    h.tap();
    await phase8b1Advance(tester);

    expect(hostBuiltBeforePop, isTrue);
    expect(tester.takeException(), isNull);
    expect(find.byType(StarMapNarrativeLiveScreen), findsNothing);
    expect(find.byKey(phase8b2HubKey), findsOneWidget);
    expect(gen.calls, 0);
    expect(await h.saved(tester, 'owner-a'), isEmpty);
    expect(h.invalidations, 0);
    expect(h.analytics.completed, 0);
    expect(h.nav.legacy, 0);
    expect(h.nav.navigating, isFalse);
    expect(h.nav.routeDone, isTrue);
  });

  testWidgets('after an abandoned first frame the next tap starts fresh',
      (tester) async {
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
    h.observer.afterFirstFrame = (navigator) => navigator.pop();
    h.tap();
    await phase8b1Advance(tester);
    expect(gen.calls, 0);
    expect(h.nav.navigating, isFalse);

    h.tap();
    await phase8b1Advance(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(StarMapNarrativeLiveScreen), findsOneWidget);
    expect(gen.calls, 1);
    expect(h.nav.navigating, isTrue);
  });
}
