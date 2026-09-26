/// Phase 7D — phase-scoped expected-delta goldens (hierarchy + continuity).
///
/// Frozen 7A / 7B / 7C fixtures are untouched. Master refresh = Phase 7G.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_section_kind.dart';
import 'package:oracly_new/features/star_map/result/yildizname_continuity_presentation.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_presentation.dart';

import '../../support/yildizname_result_fixtures.dart';
import 'yildizname_golden_harness.dart';
import 'yildizname_visual_harness.dart';

const yildiznamePhase7dGoldenNames = <String>[
  'phase7d_narrative_full_hierarchy_390',
  'phase7d_narrative_with_continuity_390',
  'phase7d_narrative_long_form_390',
  'phase7d_narrative_reduced_no_continuity_390',
  'phase7d_narrative_full_320x568',
  'phase7d_narrative_full_360x800_ts13',
];

YildiznameResultPresentation _full({
  String summary =
      'Güneş, Ay ve Yükselen birlikte sabırlı bir kimlik ekseni kurar.',
  List<String>? sectionTexts,
  String reflection = 'Hangi katman sana en dürüst geliyor?',
  String closing = 'Arşiv kapanır; sen kendi ritmine dönersin.',
}) =>
    YildiznameArtifactPresentation.of(
      yildiznameFixtureNarrativeArtifact(
        scope: YildiznameNarrativeScope.full,
        rich: true,
        kinds: const [
          YildiznameSectionKind.coreIdentity,
          YildiznameSectionKind.emotionalWorld,
          YildiznameSectionKind.anglesAndHouses,
        ],
        summary: summary,
        sectionTexts: sectionTexts ??
            const [
              'Doğum göğünde kimlik net ve sakin duruyor.',
              'Duygusal dünya yumuşak bir ritme çağırıyor.',
              'Açılar ve evler derinleşmeyi destekliyor.',
            ],
        reflection: reflection,
        closing: closing,
        createdAtUtc: DateTime.utc(2026, 1, 11),
      ),
      chromeLocale: 'tr',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  testWidgets('phase7d_narrative_full_hierarchy_390', (tester) async {
    final key = await yildiznameGoldenPumpPresentation(
      tester,
      presentation: _full(),
    );
    await yildiznamePhase7dGoldenExpect(
      tester,
      key,
      'phase7d_narrative_full_hierarchy_390',
    );
  });

  testWidgets('phase7d_narrative_with_continuity_390', (tester) async {
    final key = await yildiznameGoldenPumpPresentation(
      tester,
      presentation: _full().withContinuity(
        const YildiznameContinuityPresentation(
          heading: 'Arşiv yankısı',
          body:
              'Bu temalar önceki Yıldızname okumalarında da tekrar etmişti.',
          labels: ['Sabır', 'Kariyer'],
        ),
      ),
    );
    await yildiznamePhase7dGoldenExpect(
      tester,
      key,
      'phase7d_narrative_with_continuity_390',
    );
  });

  testWidgets('phase7d_narrative_long_form_390', (tester) async {
    final long = 'Uzun arşiv cümlesi. ' * 24;
    final key = await yildiznameGoldenPumpPresentation(
      tester,
      presentation: _full(
        summary: long,
        sectionTexts: [long, long],
        reflection: long,
        closing: long,
      ),
    );
    await yildiznamePhase7dGoldenExpect(
      tester,
      key,
      'phase7d_narrative_long_form_390',
    );
  });

  testWidgets('phase7d_narrative_reduced_no_continuity_390', (tester) async {
    final key = await yildiznameGoldenPumpPresentation(
      tester,
      presentation: YildiznameArtifactPresentation.of(
        yildiznameFixtureNarrativeArtifact(
          scope: YildiznameNarrativeScope.reduced,
          rich: false,
          ascendant: false,
          houses: false,
          aspects: false,
        ),
        chromeLocale: 'tr',
      ),
    );
    await yildiznamePhase7dGoldenExpect(
      tester,
      key,
      'phase7d_narrative_reduced_no_continuity_390',
    );
  });

  testWidgets('phase7d_narrative_full_320x568', (tester) async {
    final key = await yildiznameGoldenPumpPresentation(
      tester,
      presentation: _full(),
      viewport: const Size(320, 568),
    );
    await yildiznamePhase7dGoldenExpect(
      tester,
      key,
      'phase7d_narrative_full_320x568',
    );
  });

  testWidgets('phase7d_narrative_full_360x800_ts13', (tester) async {
    final key = await yildiznameGoldenPumpPresentation(
      tester,
      presentation: _full().withContinuity(
        const YildiznameContinuityPresentation(
          heading: 'Arşiv yankısı',
          body:
              'Bu temalar önceki Yıldızname okumalarında da tekrar etmişti.',
          labels: [
            'Çok uzun bir tema etiketi sabır ve kariyer arasında',
          ],
        ),
      ),
      viewport: const Size(360, 800),
      textScale: 1.3,
    );
    await yildiznamePhase7dGoldenExpect(
      tester,
      key,
      'phase7d_narrative_full_360x800_ts13',
    );
  });

  test('phase7d golden directory + names are phase-scoped', () {
    expect(Directory(yildiznamePhase7dGoldenDir).existsSync(), isTrue);
    expect(yildiznamePhase7dGoldenNames, hasLength(6));
    for (final n in yildiznamePhase7dGoldenNames) {
      expect(n.startsWith('phase7d_'), isTrue);
    }
  });
}
