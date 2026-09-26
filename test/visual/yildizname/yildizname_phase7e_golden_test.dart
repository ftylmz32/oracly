/// Phase 7E — phase-scoped footer/action expected-delta goldens.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_or_context.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_actions_builder.dart';

import '../../support/yildizname_result_fixtures.dart';
import 'yildizname_golden_harness.dart';
import 'yildizname_visual_harness.dart';

const yildiznamePhase7eGoldenNames = <String>[
  'phase7e_footer_all_actions_390',
  'phase7e_footer_no_favorite_390',
  'phase7e_footer_no_or_390',
  'phase7e_footer_all_actions_320x568',
  'phase7e_footer_all_actions_360x800_ts13',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  testWidgets('phase7e_footer_all_actions_390', (tester) async {
    final artifact = yildiznameFixtureNarrativeArtifact(
      createdAtUtc: DateTime.utc(2026, 1, 11),
    );
    final base =
        YildiznameArtifactPresentation.of(artifact, chromeLocale: 'tr');
    final key = await yildiznameGoldenPumpPresentation(
      tester,
      presentation: base.withActions(
        YildiznameResultActionsBuilder.build(
          presentation: base,
          orContext: YildiznameArtifactOrContext.build(artifact),
        ),
      ),
    );
    await yildiznamePhase7eGoldenExpect(
      tester,
      key,
      'phase7e_footer_all_actions_390',
    );
  });

  testWidgets('phase7e_footer_no_favorite_390', (tester) async {
    final key = await yildiznameGoldenPumpPresentation(
      tester,
      presentation: YildiznameResultPresentation.legacyLive(
        title: 'Gökyüzü Mesajı',
        sections: yildiznameVisualLegacySections(),
        planets: yildiznameVisualLegacyPlanets(),
      ),
    );
    await yildiznamePhase7eGoldenExpect(
      tester,
      key,
      'phase7e_footer_no_favorite_390',
    );
  });

  testWidgets('phase7e_footer_no_or_390', (tester) async {
    final artifact = yildiznameFixtureNarrativeArtifact(
      createdAtUtc: DateTime.utc(2026, 1, 11),
    );
    final key = await yildiznameGoldenPumpPresentation(
      tester,
      presentation: YildiznameArtifactPresentation.of(
        artifact,
        chromeLocale: 'tr',
      ),
    );
    await yildiznamePhase7eGoldenExpect(
      tester,
      key,
      'phase7e_footer_no_or_390',
    );
  });

  testWidgets('phase7e_footer_all_actions_320x568', (tester) async {
    final artifact = yildiznameFixtureNarrativeArtifact(
      createdAtUtc: DateTime.utc(2026, 1, 11),
    );
    final base =
        YildiznameArtifactPresentation.of(artifact, chromeLocale: 'tr');
    final key = await yildiznameGoldenPumpPresentation(
      tester,
      viewport: const Size(320, 568),
      presentation: base.withActions(
        YildiznameResultActionsBuilder.build(
          presentation: base,
          orContext: YildiznameArtifactOrContext.build(artifact),
        ),
      ),
    );
    await yildiznamePhase7eGoldenExpect(
      tester,
      key,
      'phase7e_footer_all_actions_320x568',
    );
  });

  testWidgets('phase7e_footer_all_actions_360x800_ts13', (tester) async {
    final artifact = yildiznameFixtureNarrativeArtifact(
      createdAtUtc: DateTime.utc(2026, 1, 11),
    );
    final base =
        YildiznameArtifactPresentation.of(artifact, chromeLocale: 'tr');
    final key = await yildiznameGoldenPumpPresentation(
      tester,
      viewport: const Size(360, 800),
      textScale: 1.3,
      presentation: base.withActions(
        YildiznameResultActionsBuilder.build(
          presentation: base,
          orContext: YildiznameArtifactOrContext.build(artifact),
        ),
      ),
    );
    await yildiznamePhase7eGoldenExpect(
      tester,
      key,
      'phase7e_footer_all_actions_360x800_ts13',
    );
  });

  test('phase7e golden inventory is phase-scoped', () {
    expect(Directory(yildiznamePhase7eGoldenDir).existsSync(), isTrue);
    expect(yildiznamePhase7eGoldenNames, hasLength(5));
  });
}
