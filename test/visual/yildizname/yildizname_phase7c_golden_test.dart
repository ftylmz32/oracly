/// Phase 7C — phase-scoped expected-delta goldens.
///
/// These capture the PRODUCTION fact snapshot with Phase 7C section chrome
/// frozen via `withoutRoleHierarchy()` (pre-7D reflection/closing lanes).
/// The frozen 7A masters and the 7B fixtures are untouched; Phase 7D owns
/// hierarchy + continuity fixtures. Master refresh = Phase 7G.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_section_kind.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_presentation.dart';

import '../../support/yildizname_result_fixtures.dart';
import 'yildizname_golden_harness.dart';
import 'yildizname_visual_harness.dart';

const yildiznamePhase7cGoldenNames = <String>[
  'phase7c_narrative_reduced_facts_390',
  'phase7c_narrative_full_complete_390',
  'phase7c_narrative_full_complete_expanded_390',
  'phase7c_narrative_full_partial_390',
  'phase7c_legacy_reopen_fact_layer_absent_390',
  'phase7c_narrative_full_complete_320x568',
  'phase7c_narrative_full_complete_412x915',
  'phase7c_narrative_full_complete_360x800_ts13',
];

const _summary =
    'Güneş, Ay ve Yükselen birlikte sabırlı bir kimlik ekseni kurar.';

YildiznameResultPresentation _full({
  bool rich = true,
  bool ascendant = true,
  bool houses = true,
  bool aspects = true,
  String summary = _summary,
  String id = 'yid_dddddddddddddddddddddddddddddddd',
}) =>
    YildiznameArtifactPresentation.of(
      yildiznameFixtureNarrativeArtifact(
        id: id,
        scope: YildiznameNarrativeScope.full,
        rich: rich,
        ascendant: ascendant,
        houses: houses,
        aspects: aspects,
        kinds: const [
          YildiznameSectionKind.coreIdentity,
          YildiznameSectionKind.emotionalWorld,
          YildiznameSectionKind.anglesAndHouses,
        ],
        summary: summary,
        sectionTexts: const [
          'Doğum göğünde kimlik net ve sakin duruyor.',
          'Duygusal dünya yumuşak bir ritme çağırıyor.',
          'Açılar ve evler derinleşmeyi destekliyor.',
        ],
        reflection: 'Hangi katman sana en dürüst geliyor?',
        closing: 'Arşiv kapanır; sen kendi ritmine dönersin.',
        createdAtUtc: DateTime.utc(2026, 1, 11),
      ),
      chromeLocale: 'tr',
    ).withoutRoleHierarchy();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  testWidgets('phase7c_narrative_reduced_facts_390', (tester) async {
    final key = await yildiznameGoldenPumpPresentation(
      tester,
      presentation: YildiznameArtifactPresentation.of(
        yildiznameVisualNarrativeArtifact(
          id: 'yid_cccccccccccccccccccccccccccccccc',
          full: false,
        ),
        chromeLocale: 'tr',
      ).withoutRoleHierarchy(),
    );
    await yildiznamePhase7cGoldenExpect(
      tester,
      key,
      'phase7c_narrative_reduced_facts_390',
    );
  });

  testWidgets('phase7c_narrative_full_complete_390', (tester) async {
    final key = await yildiznameGoldenPumpPresentation(
      tester,
      presentation: _full(),
    );
    await yildiznamePhase7cGoldenExpect(
      tester,
      key,
      'phase7c_narrative_full_complete_390',
    );
  });

  testWidgets('phase7c_narrative_full_complete_expanded_390', (tester) async {
    final key = await yildiznameGoldenPumpPresentation(
      tester,
      presentation: _full(),
    );
    await tester.tap(find.byKey(const ValueKey('starFactMoreToggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await yildiznamePhase7cGoldenExpect(
      tester,
      key,
      'phase7c_narrative_full_complete_expanded_390',
    );
  });

  testWidgets('phase7c_narrative_full_partial_390', (tester) async {
    final key = await yildiznameGoldenPumpPresentation(
      tester,
      presentation: _full(
        rich: false,
        ascendant: false,
        houses: false,
        aspects: false,
        // Stored prose that does not lean on the omitted Ascendant.
        summary: 'Güneş ve Ay birlikte sabırlı bir kimlik ekseni kurar.',
      ),
    );
    await yildiznamePhase7cGoldenExpect(
      tester,
      key,
      'phase7c_narrative_full_partial_390',
    );
  });

  testWidgets('phase7c_legacy_reopen_fact_layer_absent_390', (tester) async {
    final key = await yildiznameGoldenPumpLegacyArtifactReopen(tester);
    await yildiznamePhase7cGoldenExpect(
      tester,
      key,
      'phase7c_legacy_reopen_fact_layer_absent_390',
    );
  });

  testWidgets('phase7c_narrative_full_complete_320x568', (tester) async {
    final key = await yildiznameGoldenPumpPresentation(
      tester,
      presentation: _full(),
      viewport: const Size(320, 568),
    );
    await yildiznamePhase7cGoldenExpect(
      tester,
      key,
      'phase7c_narrative_full_complete_320x568',
    );
  });

  testWidgets('phase7c_narrative_full_complete_412x915', (tester) async {
    final key = await yildiznameGoldenPumpPresentation(
      tester,
      presentation: _full(),
      viewport: const Size(412, 915),
    );
    await yildiznamePhase7cGoldenExpect(
      tester,
      key,
      'phase7c_narrative_full_complete_412x915',
    );
  });

  testWidgets('phase7c_narrative_full_complete_360x800_ts13', (tester) async {
    final key = await yildiznameGoldenPumpPresentation(
      tester,
      presentation: _full(),
      viewport: const Size(360, 800),
      textScale: 1.3,
    );
    await yildiznamePhase7cGoldenExpect(
      tester,
      key,
      'phase7c_narrative_full_complete_360x800_ts13',
    );
  });

  test('phase-scoped 7C golden inventory exists; 7A / 7B untouched', () {
    for (final name in yildiznamePhase7cGoldenNames) {
      expect(
        File('$yildiznamePhase7cGoldenDir/$name.png').existsSync(),
        isTrue,
        reason: name,
      );
    }
    expect(
      File(
        '$yildiznamePhase7bGoldenDir/phase7b_artifact_narrative_full_390.png',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        '$yildiznameGoldenMasterDir/artifact_narrative_full_current_390.png',
      ).existsSync(),
      isTrue,
    );
  });
}
