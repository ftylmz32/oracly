/// Phase 8B.2 — artifact history observes a post-Back save without restart.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_providers.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_orchestrator_providers.dart';

import 'phase8b1_route_support.dart';
import 'phase8b2_back_support.dart';
import 'phase8b_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(BirthTimezoneDatabase.ensureInitialized);
  setUp(() => yildiznameNarrativeFlagOverride(true));
  tearDown(yildiznameNarrativeFlagReset);

  Future<List<YildiznameArtifact>> history(
    WidgetTester tester,
    Phase8b2Harness h,
  ) async =>
      (await tester.runAsync(
        () => h.container.read(yildiznameArtifactHistoryProvider.future),
      ))!;

  Future<Phase8b2Harness> saveAfterBack(
    WidgetTester tester, {
    required bool wireHook,
  }) async {
    final h = Phase8b2Harness(phase8bStorage());
    final gen = Phase8b2HeldGen();
    await h.pump(
      tester,
      (onPersisted) => phase8bOrchestrator(
        storage: h.storage,
        chart: phase8bE4(),
        generate: gen.call,
        onPersisted: wireHook ? onPersisted : null,
      ),
    );
    h.container.listen(yildiznameArtifactHistoryProvider, (_, _) {});
    expect(await history(tester, h), isEmpty);

    h.tap();
    await phase8b1Advance(tester);
    expect(gen.calls, 1);
    await h.back(tester);
    gen.release();
    await phase8b1Advance(tester);
    expect((await h.saved(tester, 'owner-a')).length, 1);
    return h;
  }

  testWidgets('popped before provider → saved → history provider sees it',
      (tester) async {
    final h = await saveAfterBack(tester, wireHook: true);

    final seen = await history(tester, h);
    expect(seen.length, 1);
    expect(seen.single.ownerId, 'owner-a');
    expect(h.invalidations, 1);
    expect(h.analytics.completed, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('control: without the persist hook the cache stays stale',
      (tester) async {
    final h = await saveAfterBack(tester, wireHook: false);

    expect(await history(tester, h), isEmpty);
    expect(h.invalidations, 0);
  });
}
