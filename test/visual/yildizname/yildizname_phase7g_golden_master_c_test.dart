/// Phase 7G — final masters (locale chrome + responsive controls).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';

import 'yildizname_phase7g_capture.dart';
import 'yildizname_phase7g_fixtures.dart';
import 'yildizname_phase7g_pump.dart';
import 'yildizname_visual_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  testWidgets('final_narrative_full_en_chrome_390', (tester) async {
    await yildiznameVisualBindLocale('en');
    final artifact = phase7gNarrativeArtifact();
    await phase7gCapture(
      tester,
      'final_narrative_full_en_chrome_390',
      () => phase7gPumpPresentation(
        tester,
        presentation: phase7gNarrativeOf(artifact, chromeLocale: 'en'),
        overrides: [phase7gDiscoveryOverride()],
      ),
      assertAfter: () {
        expect(
          YildiznameArtifactPresentation.summaryQuote(artifact),
          contains('Güneş'),
        );
        phase7gAssertNoRawIds(tester);
      },
    );
  });

  testWidgets('final_narrative_full_ru_chrome_390', (tester) async {
    await yildiznameVisualBindLocale('ru');
    final artifact = phase7gNarrativeArtifact();
    await phase7gCapture(
      tester,
      'final_narrative_full_ru_chrome_390',
      () => phase7gPumpPresentation(
        tester,
        presentation: phase7gNarrativeOf(artifact, chromeLocale: 'ru'),
        overrides: [phase7gDiscoveryOverride()],
      ),
      assertAfter: () {
        expect(
          YildiznameArtifactPresentation.summaryQuote(artifact),
          contains('Güneş'),
        );
        phase7gAssertNoRawIds(tester);
      },
    );
  });

  testWidgets('final_full_compact_320x568', (tester) async {
    final artifact = phase7gNarrativeArtifact();
    await phase7gCapture(
      tester,
      'final_full_compact_320x568',
      () => phase7gPumpPresentation(
        tester,
        presentation: phase7gNarrativeOf(artifact),
        viewport: const Size(320, 568),
        overrides: [phase7gDiscoveryOverride()],
      ),
    );
  });

  testWidgets('final_full_textscale20_360x800', (tester) async {
    final artifact = phase7gNarrativeArtifact();
    await phase7gCapture(
      tester,
      'final_full_textscale20_360x800',
      () => phase7gPumpPresentation(
        tester,
        presentation: phase7gNarrativeOf(artifact),
        viewport: const Size(360, 800),
        textScale: 2.0,
        overrides: [phase7gDiscoveryOverride()],
      ),
    );
  });

  testWidgets('final_full_tablet_768x1024', (tester) async {
    final artifact = phase7gNarrativeArtifact();
    await phase7gCapture(
      tester,
      'final_full_tablet_768x1024',
      () => phase7gPumpPresentation(
        tester,
        presentation: phase7gNarrativeOf(artifact),
        viewport: const Size(768, 1024),
        overrides: [phase7gDiscoveryOverride()],
      ),
    );
  });
}
