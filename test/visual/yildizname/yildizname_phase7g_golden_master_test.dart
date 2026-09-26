/// Phase 7G — final production golden masters (hub / legacy / reduced).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/oracle_conversation/widgets/or_ask_button.dart';
import 'package:oracly_new/features/favorite_moments/copy/favorite_moments_copy.dart';
import 'package:oracly_new/features/favorite_moments/presentation/widgets/save_favorite_moment_link.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_continuity_echo.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_fact_snapshot_plate.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_historical_status.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';

import 'yildizname_phase7g_capture.dart';
import 'yildizname_phase7g_fixtures.dart';
import 'yildizname_phase7g_pump.dart';
import 'yildizname_visual_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  testWidgets('final_hub_empty_390', (tester) async {
    await phase7gCapture(
      tester,
      'final_hub_empty_390',
      () => phase7gPumpHub(tester, withBirth: false),
    );
  });

  testWidgets('final_hub_with_birth_390', (tester) async {
    await phase7gCapture(
      tester,
      'final_hub_with_birth_390',
      () => phase7gPumpHub(tester, withBirth: true),
    );
  });

  testWidgets('final_legacy_live_all_actions_390', (tester) async {
    await phase7gCapture(
      tester,
      'final_legacy_live_all_actions_390',
      () => phase7gPumpPresentation(
        tester,
        presentation: phase7gLegacyLive(durable: true, withOr: true),
        overrides: [phase7gDiscoveryOverride()],
      ),
      assertAfter: () {
        expect(find.byType(OrAskButton), findsOneWidget);
        expect(find.byType(SaveFavoriteMomentLink), findsOneWidget);
        expect(find.byType(StarMapHistoricalStatus), findsNothing);
        expect(find.byType(StarMapFactSnapshotPlate), findsNothing);
        expect(find.text(FavoriteMomentsCopy.sourceUnavailable), findsNothing);
        phase7gAssertNoRawIds(tester);
      },
    );
  });

  testWidgets('final_legacy_live_capture_failure_390', (tester) async {
    await phase7gCapture(
      tester,
      'final_legacy_live_capture_failure_390',
      () => phase7gPumpPresentation(
        tester,
        presentation: phase7gLegacyLive(durable: false, withOr: true),
      ),
      assertAfter: () {
        expect(find.byType(OrAskButton), findsOneWidget);
        expect(find.byType(SaveFavoriteMomentLink), findsNothing);
        expect(find.byType(StarMapHistoricalStatus), findsNothing);
        expect(find.text(FavoriteMomentsCopy.sourceUnavailable), findsNothing);
      },
    );
  });

  testWidgets('final_legacy_artifact_reopen_390', (tester) async {
    await phase7gCapture(
      tester,
      'final_legacy_artifact_reopen_390',
      () => phase7gPumpPresentation(
        tester,
        presentation: phase7gLegacyArtifactReopen(),
        overrides: [phase7gDiscoveryOverride()],
      ),
      assertAfter: () {
        expect(find.byType(StarMapReferenceResultScreen), findsOneWidget);
        expect(find.byType(SaveFavoriteMomentLink), findsOneWidget);
        expect(find.byType(StarMapHistoricalStatus), findsOneWidget);
        phase7gAssertNoRawIds(tester);
      },
    );
  });

  testWidgets('final_narrative_reduced_artifact_390', (tester) async {
    final artifact = phase7gNarrativeArtifact(
      scope: YildiznameNarrativeScope.reduced,
      rich: false,
      id: 'yid_7greducd7greducd7greducd7gred00',
    );
    await phase7gCapture(
      tester,
      'final_narrative_reduced_artifact_390',
      () => phase7gPumpPresentation(
        tester,
        presentation: phase7gNarrativeOf(artifact),
        overrides: [phase7gDiscoveryOverride()],
      ),
      assertAfter: () {
        phase7gAssertNarrativeSurface(
          tester,
          expectFacts: true,
          expectFavorite: true,
          expectHistorical: true,
        );
      },
    );
  });

  testWidgets('final_narrative_reduced_continuity_390', (tester) async {
    final artifact = phase7gNarrativeArtifact(
      scope: YildiznameNarrativeScope.reduced,
      rich: false,
      id: 'yid_7gredcon7gredcon7gredcon7grec00',
    );
    await phase7gCapture(
      tester,
      'final_narrative_reduced_continuity_390',
      () => phase7gPumpPresentation(
        tester,
        presentation: phase7gNarrativeOf(artifact, withContinuity: true),
        overrides: [phase7gDiscoveryOverride()],
      ),
      assertAfter: () {
        expect(find.byType(StarMapContinuityEcho), findsOneWidget);
        phase7gAssertNoRawIds(tester);
      },
    );
  });
}
