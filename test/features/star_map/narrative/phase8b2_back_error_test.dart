/// Phase 8B.2 — Back from typed error hosts (generation / owner / flag).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_orchestrator_providers.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_error_state.dart';
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

  testWidgets('generation error → Back → no auto retry, no new transaction',
      (tester) async {
    final h = Phase8b2Harness(phase8bStorage());
    final gen = Phase8bGen(failFirst: 1);
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
    expect(find.byType(StarMapErrorState), findsOneWidget);
    expect(gen.calls, 1);

    await h.back(tester);
    await phase8b1Advance(tester, frames: 20);
    expect(tester.takeException(), isNull);
    expect(find.byType(StarMapNarrativeLiveScreen), findsNothing);
    expect(h.nav.navigating, isFalse);
    expect(h.nav.routeDone, isTrue);
    expect(gen.calls, 1);
    expect(await h.saved(tester, 'owner-a'), isEmpty);
    expect(h.analytics.completed, 0);
  });

  testWidgets('A→B before execute → ownerChanged → Back → fresh B tap',
      (tester) async {
    final h = Phase8b2Harness(phase8bStorage());
    final gen = Phase8bGen();
    await h.pump(
      tester,
      (onPersisted) => phase8bOrchestrator(
        storage: h.storage,
        chart: phase8bE4(),
        generate: gen.call,
        repoOwner: 'owner-b',
        onPersisted: onPersisted,
      ),
    );
    h.observer.onPush = () => h.storage
        .setString(UserLocalDataIsolation.ownerKey, 'owner-b');
    h.tap();
    await phase8b1Advance(tester);
    expect(find.byType(StarMapErrorState), findsOneWidget);

    await h.back(tester);
    expect(h.nav.navigating, isFalse);
    expect(gen.calls, 0);
    expect(await h.saved(tester, 'owner-a'), isEmpty);
    expect(await h.saved(tester, 'owner-b'), isEmpty);
    expect(h.invalidations, 0);

    h.tap();
    await phase8b1Advance(tester);
    expect(find.byType(StarMapReferenceResultScreen), findsOneWidget);
    expect(gen.calls, 1);
    expect((await h.saved(tester, 'owner-b')).single.ownerId, 'owner-b');
    expect(tester.takeException(), isNull);
  });

  testWidgets('true→false before execute → flagDisabled → Back → legacy',
      (tester) async {
    final h = Phase8b2Harness(phase8bStorage());
    final gen = Phase8bGen();
    var flag = true;
    await h.pump(
      tester,
      (onPersisted) => phase8bOrchestrator(
        storage: h.storage,
        chart: phase8bE4(),
        generate: gen.call,
        flagReader: () => flag,
        onPersisted: onPersisted,
      ),
    );
    h.observer.onPush = () => flag = false;
    h.tap();
    await phase8b1Advance(tester);
    expect(find.byType(StarMapErrorState), findsOneWidget);

    await h.back(tester);
    expect(h.nav.navigating, isFalse);
    expect(gen.calls, 0);

    yildiznameNarrativeFlagReset();
    h.tap();
    await phase8b1Advance(tester, frames: 3);
    expect(h.nav.legacy, 1);
    expect(gen.calls, 0);
    expect(find.byType(StarMapNarrativeLiveScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
