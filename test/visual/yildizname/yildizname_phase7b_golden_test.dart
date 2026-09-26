/// Phase 7B — phase-scoped expected-delta goldens @ 390×844.
///
/// These capture the PRODUCTION typed-presentation path (localized chrome +
/// scope note) as it stood at 7B — WITHOUT the Phase 7C fact layer
/// (`withoutFactSnapshot()`), so the 7B fixtures stay honest and unchanged; 7C
/// has its own phase-scoped fixtures. The frozen 7A masters are unchanged; the
/// comprehensive master refresh + hash freeze belongs to Phase 7G.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';

import 'yildizname_golden_harness.dart';
import 'yildizname_visual_harness.dart';

const yildiznamePhase7bGoldenNames = <String>[
  'phase7b_artifact_legacy_reopen_390',
  'phase7b_artifact_narrative_reduced_390',
  'phase7b_artifact_narrative_full_390',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  testWidgets('phase7b_artifact_legacy_reopen_390', (tester) async {
    final key = await yildiznameGoldenPumpLegacyArtifactReopen(tester);
    await yildiznamePhase7bGoldenExpect(
      tester,
      key,
      'phase7b_artifact_legacy_reopen_390',
    );
  });

  testWidgets('phase7b_artifact_narrative_reduced_390', (tester) async {
    final key = await yildiznameGoldenPumpPresentation(
      tester,
      presentation: YildiznameArtifactPresentation.of(
        yildiznameVisualNarrativeArtifact(
          id: 'yid_cccccccccccccccccccccccccccccccc',
          full: false,
        ),
        chromeLocale: 'tr',
      ).withoutFactSnapshot(),
    );
    await yildiznamePhase7bGoldenExpect(
      tester,
      key,
      'phase7b_artifact_narrative_reduced_390',
    );
  });

  testWidgets('phase7b_artifact_narrative_full_390', (tester) async {
    final key = await yildiznameGoldenPumpPresentation(
      tester,
      presentation: YildiznameArtifactPresentation.of(
        yildiznameVisualNarrativeArtifact(
          id: 'yid_dddddddddddddddddddddddddddddddd',
          full: true,
        ),
        chromeLocale: 'tr',
      ).withoutFactSnapshot(),
    );
    await yildiznamePhase7bGoldenExpect(
      tester,
      key,
      'phase7b_artifact_narrative_full_390',
    );
  });

  test('phase-scoped 7B golden inventory exists; 7A masters untouched', () {
    for (final name in yildiznamePhase7bGoldenNames) {
      expect(
        File('$yildiznamePhase7bGoldenDir/$name.png').existsSync(),
        isTrue,
        reason: name,
      );
    }
    // 7A masters stay where 7A put them (hash-locked by the 7A hash test).
    expect(
      File(
        '$yildiznameGoldenMasterDir/artifact_legacy_reopen_390.png',
      ).existsSync(),
      isTrue,
    );
  });
}
