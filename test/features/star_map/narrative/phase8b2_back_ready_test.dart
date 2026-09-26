/// Phase 8B.2 — Back from READY returns to the hub, analytics stays once.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_orchestrator_providers.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_error_state.dart';
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

  testWidgets('READY → Back → hub, lock released, one completion log',
      (tester) async {
    final h = Phase8b2Harness(phase8bStorage());
    final gen = Phase8bGen();
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
    expect(find.byType(StarMapReferenceResultScreen), findsOneWidget);
    expect(h.analytics.completed, 1);
    expect(h.invalidations, 1);
    expect(h.nav.navigating, isTrue);

    await h.back(tester);
    await phase8b1Advance(tester, frames: 10);

    expect(tester.takeException(), isNull);
    expect(find.byKey(phase8b2HubKey), findsOneWidget);
    expect(find.byType(StarMapNarrativeLiveScreen), findsNothing);
    expect(find.byType(StarMapReferenceResultScreen), findsNothing);
    expect(find.byType(StarMapLoadingCinema), findsNothing);
    expect(find.byType(StarMapErrorState), findsNothing);
    expect(h.nav.navigating, isFalse);
    expect(h.nav.routeDone, isTrue);
    expect(h.analytics.completed, 1);
    expect(h.invalidations, 1);
    expect(gen.calls, 1);
  });
}
