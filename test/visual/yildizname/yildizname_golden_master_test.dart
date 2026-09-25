/// Phase 7A — pixel golden masters @ 390×844 (CURRENT baseline).
library;

import 'package:flutter_test/flutter_test.dart';

import 'yildizname_golden_harness.dart';
import 'yildizname_visual_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  testWidgets('hub_empty_390', (tester) async {
    final key = await yildiznameGoldenPumpHub(tester, withBirth: false);
    await yildiznameGoldenExpect(tester, key, 'hub_empty_390');
  });

  testWidgets('hub_with_birth_390', (tester) async {
    final key = await yildiznameGoldenPumpHub(tester, withBirth: true);
    await yildiznameGoldenExpect(tester, key, 'hub_with_birth_390');
  });

  testWidgets('legacy_result_390', (tester) async {
    final key = await yildiznameGoldenPumpResult(
      tester,
      title: 'Gökyüzü Mesajı',
      sections: yildiznameVisualLegacySections(),
      planets: yildiznameVisualLegacyPlanets(),
    );
    await yildiznameGoldenExpect(tester, key, 'legacy_result_390');
  });

  testWidgets('artifact_legacy_reopen_390', (tester) async {
    final key = await yildiznameGoldenPumpLegacyArtifact(tester);
    await yildiznameGoldenExpect(tester, key, 'artifact_legacy_reopen_390');
  });

  testWidgets('artifact_narrative_reduced_current_390', (tester) async {
    final key = await yildiznameGoldenPumpResult(
      tester,
      title: 'Yıldızname',
      sections: yildiznameVisualNarrativeReducedSections(),
      artifactId: 'yid_cccccccccccccccccccccccccccccccc',
      artifactCreatedAt: DateTime.utc(2026, 1, 10),
    );
    await yildiznameGoldenExpect(
        tester, key, 'artifact_narrative_reduced_current_390');
  });

  testWidgets('artifact_narrative_full_current_390', (tester) async {
    final key = await yildiznameGoldenPumpResult(
      tester,
      title: 'Yıldızname',
      sections: yildiznameVisualNarrativeFullSections(),
      artifactId: 'yid_dddddddddddddddddddddddddddddddd',
      artifactCreatedAt: DateTime.utc(2026, 1, 11),
    );
    await yildiznameGoldenExpect(
        tester, key, 'artifact_narrative_full_current_390');
  });

  /// Negative-control twin — same chrome path as legacy_result; hash locked.
  testWidgets('firewall_result_chrome_control_390', (tester) async {
    final key = await yildiznameGoldenPumpResult(
      tester,
      title: 'Gökyüzü Mesajı',
      sections: yildiznameVisualLegacySections(),
      planets: yildiznameVisualLegacyPlanets(),
    );
    await yildiznameGoldenExpect(
        tester, key, 'firewall_result_chrome_control_390');
  });
}
