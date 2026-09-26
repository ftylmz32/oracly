/// Phase 8B.1 — live host retry: fresh transaction vs persistence-only.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/star_map/artifacts/local_yildizname_artifact_repository.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_error_state.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';

import 'phase8b1_route_support.dart';
import 'phase8b_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(BirthTimezoneDatabase.ensureInitialized);

  testWidgets('K generation failure → Retry → fresh transaction → ready',
      (tester) async {
    final storage = phase8bStorage();
    final gen = Phase8bGen(failFirst: 1);
    var loads = 0;
    final orch = phase8bOrchestrator(
      storage: storage,
      chart: phase8bE2(),
      generate: gen.call,
      onLoadChart: () => loads++,
    );
    final prepared =
        await tester.runAsync(() => orch.prepare(languageCode: 'en'));
    await phase8b1PumpHost(tester,
        storage: storage, orch: orch, prepared: prepared!);
    expect(find.text(ResilienceCopy.interpretationFailed), findsOneWidget);
    expect(gen.calls, 1);
    expect(loads, 1);

    await phase8b1TapRetry(tester);
    expect(gen.calls, 2);
    expect(loads, 2);
    expect(find.byType(StarMapReferenceResultScreen), findsOneWidget);
  });

  testWidgets('L ownerChanged → Retry → fresh current-owner transaction',
      (tester) async {
    final storage = phase8bStorage();
    final gen = Phase8bGen();
    final orch = phase8bOrchestrator(
      storage: storage,
      chart: phase8bE2(),
      generate: gen.call,
      repoOwner: 'owner-b',
    );
    final prepared =
        await tester.runAsync(() => orch.prepare(languageCode: 'en'));
    expect(prepared!.ownerSnapshot.ownerId, 'owner-a');
    await storage.setString(UserLocalDataIsolation.ownerKey, 'owner-b');

    await phase8b1PumpHost(tester,
        storage: storage, orch: orch, prepared: prepared);
    expect(find.byType(StarMapErrorState), findsOneWidget);
    expect(find.text(ResilienceCopy.temporaryFailure), findsOneWidget);
    expect(gen.calls, 0);

    await phase8b1TapRetry(tester);
    expect(gen.calls, 1);
    expect(find.byType(StarMapReferenceResultScreen), findsOneWidget);
    final saved = await tester.runAsync(
      () => LocalYildiznameArtifactRepository(storage, ownerId: 'owner-b')
          .getAll(),
    );
    expect(saved!.single.ownerId, 'owner-b');
  });

  testWidgets('M persistencePending → Retry → same pending, provider 1',
      (tester) async {
    final storage = phase8bStorage();
    final gen = Phase8bGen();
    final repo = LocalYildiznameArtifactRepository(storage, ownerId: 'owner-a');
    var loads = 0;
    final orch = phase8bOrchestrator(
      storage: storage,
      chart: phase8bE2(),
      generate: gen.call,
      completion: Phase8bFailingCompletion(repo),
      onLoadChart: () => loads++,
    );
    final prepared =
        await tester.runAsync(() => orch.prepare(languageCode: 'en'));
    await phase8b1PumpHost(tester,
        storage: storage, orch: orch, prepared: prepared!);
    expect(find.text(ResilienceCopy.readingSaveFailed), findsOneWidget);
    expect(gen.calls, 1);

    await phase8b1TapRetry(tester);
    expect(gen.calls, 1);
    expect(loads, 1);
    expect(find.byType(StarMapReferenceResultScreen), findsOneWidget);
  });
}
