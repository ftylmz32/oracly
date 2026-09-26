/// Phase 8B.2 — Back while the durable save runs / after a failed save.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/star_map/artifacts/local_yildizname_artifact_repository.dart';
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

  testWidgets('Back during held save → artifact once, no late READY',
      (tester) async {
    final h = Phase8b2Harness(phase8bStorage());
    final gen = Phase8bGen();
    final completion = Phase8b2HeldCompletion(
      LocalYildiznameArtifactRepository(h.storage, ownerId: 'owner-a'),
    );
    await h.pump(
      tester,
      (onPersisted) => phase8bOrchestrator(
        storage: h.storage,
        chart: phase8bE4(),
        generate: gen.call,
        completion: completion,
        onPersisted: onPersisted,
      ),
    );
    h.tap();
    await phase8b1Advance(tester);
    expect(find.byType(StarMapLoadingCinema), findsOneWidget);
    expect(gen.calls, 1);
    expect(completion.calls, 1);

    await h.back(tester);
    expect(find.byType(StarMapNarrativeLiveScreen), findsNothing);
    expect(h.nav.navigating, isFalse);
    expect(h.invalidations, 0);

    completion.gate.complete();
    await phase8b1Advance(tester);

    expect(tester.takeException(), isNull);
    expect((await h.saved(tester, 'owner-a')).length, 1);
    expect(h.invalidations, 1);
    expect(find.byType(StarMapReferenceResultScreen), findsNothing);
    expect(find.byType(StarMapNarrativeLiveScreen), findsNothing);
    expect(find.byKey(phase8b2HubKey), findsOneWidget);
    expect(h.analytics.completed, 0);
    expect(h.nav.legacy, 0);
    expect(gen.calls, 1);
    expect(completion.calls, 1);
  });

  testWidgets('persistencePending → Back → pending discarded, no retry',
      (tester) async {
    final h = Phase8b2Harness(phase8bStorage());
    final gen = Phase8bGen();
    await h.pump(
      tester,
      (onPersisted) => phase8bOrchestrator(
        storage: h.storage,
        chart: phase8bE4(),
        generate: gen.call,
        completion: Phase8bFailingCompletion(
          LocalYildiznameArtifactRepository(h.storage, ownerId: 'owner-a'),
        ),
        onPersisted: onPersisted,
      ),
    );
    h.tap();
    await phase8b1Advance(tester);
    expect(find.text(ResilienceCopy.readingSaveFailed), findsOneWidget);
    expect(gen.calls, 1);

    await h.back(tester);
    await phase8b1Advance(tester, frames: 20);

    expect(tester.takeException(), isNull);
    expect(find.byType(StarMapNarrativeLiveScreen), findsNothing);
    expect(h.nav.navigating, isFalse);
    expect(h.nav.routeDone, isTrue);
    expect(gen.calls, 1);
    expect(await h.saved(tester, 'owner-a'), isEmpty);
    expect(h.invalidations, 0);
    expect(h.analytics.completed, 0);
  });
}
