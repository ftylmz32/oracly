/// Phase 7G — final masters (full / continuity / live-artifact parity).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/favorite_moments/presentation/widgets/save_favorite_moment_link.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_continuity_echo.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_fact_snapshot_plate.dart';

import 'yildizname_phase7g_capture.dart';
import 'yildizname_phase7g_fixtures.dart';
import 'yildizname_phase7g_pump.dart';
import 'yildizname_visual_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  testWidgets('final_narrative_full_rich_390', (tester) async {
    final artifact = phase7gNarrativeArtifact();
    await phase7gCapture(
      tester,
      'final_narrative_full_rich_390',
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
        );
      },
    );
  });

  testWidgets('final_narrative_full_rich_deeper_open_390', (tester) async {
    final artifact = phase7gNarrativeArtifact();
    await phase7gCapture(
      tester,
      'final_narrative_full_rich_deeper_open_390',
      () => phase7gPumpPresentation(
        tester,
        presentation: phase7gNarrativeOf(artifact),
        overrides: [phase7gDiscoveryOverride()],
        openDeeper: true,
      ),
      assertAfter: () {
        expect(find.byType(StarMapFactSnapshotPlate), findsOneWidget);
        phase7gAssertNoRawIds(tester);
      },
    );
  });

  testWidgets('final_narrative_full_continuity_390', (tester) async {
    final artifact = phase7gNarrativeArtifact(
      id: 'yid_7gfullcn7gfullcn7gfullcn7gful00',
    );
    await phase7gCapture(
      tester,
      'final_narrative_full_continuity_390',
      () => phase7gPumpPresentation(
        tester,
        presentation: phase7gNarrativeOf(artifact, withContinuity: true),
        overrides: [phase7gDiscoveryOverride()],
        revealContinuity: true,
      ),
      assertAfter: () {
        expect(find.byType(StarMapContinuityEcho), findsOneWidget);
        phase7gAssertNoRawIds(tester);
      },
    );
  });

  testWidgets('final_narrative_live_ready_390', (tester) async {
    final pair = phase7gLiveAndArtifact();
    await phase7gCapture(
      tester,
      'final_narrative_live_ready_390',
      () => phase7gPumpPresentation(
        tester,
        presentation: pair.live,
        overrides: [phase7gDiscoveryOverride()],
      ),
      assertAfter: () {
        phase7gAssertNarrativeSurface(
          tester,
          expectFacts: true,
          expectFavorite: true,
        );
      },
    );
  });

  testWidgets('final_narrative_artifact_same_evidence_390', (tester) async {
    final pair = phase7gLiveAndArtifact();
    await phase7gCapture(
      tester,
      'final_narrative_artifact_same_evidence_390',
      () => phase7gPumpPresentation(
        tester,
        presentation: phase7gNarrativeOf(pair.artifact),
        overrides: [phase7gDiscoveryOverride()],
      ),
      assertAfter: () {
        expect(find.byType(SaveFavoriteMomentLink), findsOneWidget);
        phase7gAssertNoRawIds(tester);
      },
    );
  });
}
