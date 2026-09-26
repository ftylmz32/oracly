/// Phase 8B.1 — preparation-failure retry starts a clean preparation.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/birth_chart/models/birth_chart.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';

import 'phase8a2_json_mutate.dart';
import 'phase8b1_route_support.dart';
import 'phase8b_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(BirthTimezoneDatabase.ensureInitialized);

  testWidgets('invalidEvidence → Retry → fresh prepare, one repair each',
      (tester) async {
    final storage = phase8bStorage();
    final gen = Phase8bGen();
    var repairs = 0;
    BirthChart chart = phase8aRemoveAscendant(phase8bE4());
    final orch = phase8bOrchestrator(
      storage: storage,
      chart: null,
      chartReader: () => chart,
      generate: gen.call,
      onRepair: () => repairs++,
    );
    final prepared =
        await tester.runAsync(() => orch.prepare(languageCode: 'en'));
    await phase8b1PumpHost(tester,
        storage: storage, orch: orch, prepared: prepared!);
    expect(find.text(ResilienceCopy.analysisUnavailable), findsOneWidget);
    expect(repairs, 1);
    expect(gen.calls, 0);

    await phase8b1TapRetry(tester);
    expect(find.text(ResilienceCopy.analysisUnavailable), findsOneWidget);
    expect(repairs, 2);
    expect(gen.calls, 0);

    chart = phase8bE4();
    await phase8b1TapRetry(tester);
    expect(gen.calls, 1);
    expect(find.byType(StarMapReferenceResultScreen), findsOneWidget);
  });

  testWidgets('ownerUnavailable → Retry → fresh prepare under valid owner',
      (tester) async {
    final storage = phase8bStorage(owner: '');
    final gen = Phase8bGen();
    final orch = phase8bOrchestrator(
      storage: storage,
      chart: phase8bE2(),
      generate: gen.call,
      repoOwner: 'owner-a',
    );
    final prepared =
        await tester.runAsync(() => orch.prepare(languageCode: 'en'));
    await phase8b1PumpHost(tester,
        storage: storage, orch: orch, prepared: prepared!);
    expect(find.text(ResilienceCopy.temporaryFailure), findsOneWidget);
    expect(gen.calls, 0);

    await storage.setString(UserLocalDataIsolation.ownerKey, 'owner-a');
    await phase8b1TapRetry(tester);
    expect(gen.calls, 1);
    expect(find.byType(StarMapReferenceResultScreen), findsOneWidget);
  });
}
