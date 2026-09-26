/// Phase 7E.1 — real Narrative live vs artifact reopen action parity.
///
/// Crosses [YildiznameArtifactPresentation.narrativeLive] and
/// [YildiznameArtifactPresentation.of] — never the same presentation twice.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_factory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_or_context.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_legacy_section_kind.dart';
import 'package:oracly_new/features/star_map/models/star_map_reading.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_actions_builder.dart';

import '../../../visual/yildizname/yildizname_visual_harness.dart';
import 'phase7e1_parity_assert.dart';
import 'phase7e1_parity_run.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  test('REDUCED: narrativeLive vs of — distinct sources, action parity', () {
    phase7e1RunNarrativeParity(
      scope: YildiznameNarrativeScope.reduced,
      rich: false,
      resultLocale: 'tr',
      chromeLocale: 'tr',
      artifactId: 'yid_parityreducedparityreducedparity0',
    );
  });

  test('FULL rich: narrativeLive vs of — distinct sources, action parity', () {
    phase7e1RunNarrativeParity(
      scope: YildiznameNarrativeScope.full,
      rich: true,
      resultLocale: 'tr',
      chromeLocale: 'tr',
      artifactId: 'yid_parityfullrichparityfullrichpari',
    );
  });

  test('cross-locale: stored TR prose, EN chrome — live/reopen parity', () {
    phase7e1RunNarrativeParity(
      scope: YildiznameNarrativeScope.reduced,
      rich: false,
      resultLocale: 'tr',
      chromeLocale: 'en',
      artifactId: 'yid_paritycrosslocalecrosslocale00',
      assertStoredProseUntranslated: true,
    );
  });

  test('legacy serialization: copy/share/favorite parity; OR may differ', () {
    const title = 'Gökyüzü Mesajı';
    final sections = yildiznameVisualLegacySections();
    final planets = yildiznameVisualLegacyPlanets();
    const id = 'yid_legacyparitylegacyparitylegacy00';
    final at = DateTime.utc(2026, 5, 5);
    final artifact = YildiznameArtifactFactory.createLegacy(
      ownerId: 'parity-legacy-owner',
      title: title,
      sections: sections,
      sectionKind: YildiznameLegacySectionKind.skyMessage,
      locale: 'tr',
      planets: planets,
      sunSignId: 'leo',
      dayKey: '2026-05-05',
      createdAtUtc: at,
      id: id,
    );

    final live = YildiznameResultPresentation.legacyLive(
      title: title,
      sections: sections,
      planets: planets,
      artifactId: id,
      createdAtUtc: at,
      chromeLanguage: 'tr',
    );
    final reopen =
        YildiznameArtifactPresentation.of(artifact, chromeLocale: 'tr');
    expect(live.source, YildiznameResultSource.legacyLive);
    expect(reopen.source, YildiznameResultSource.legacyArtifact);

    const reading = StarMapReading(
      overview: StarMapOverview(
        whatItSays: 'Gökyüzü sakin.',
        dominantEnergy: 'Dinginlik',
        mainMessage: 'Yavaşla.',
      ),
      skyMessage: StarMapSkyMessage(
        today: 'Nefes.',
        interpretation: 'Sakin.',
        advice: 'Bir adım.',
      ),
      karmic: StarMapKarmicReading(
        theme: 'Dinlen',
        learning: 'Yavaşla.',
        interpretation: 'Yorum.',
        takeaway: 'Bir adım.',
        promptQuestion: 'Ne istiyorsun?',
      ),
      planets: [],
      sunLabel: 'Aslan',
    );
    final liveOr = OracleReadingContextSources.starMap(
      sectionLabel: 'Gökyüzü',
      reading: reading,
      sectionLines: [
        for (final s in sections)
          if (s.body.trim().isNotEmpty) '${s.title}: ${s.body}',
      ],
    );
    final reopenOr = YildiznameArtifactOrContext.build(artifact);
    final liveActions = YildiznameResultActionsBuilder.build(
      presentation: live,
      orContext: liveOr,
    );
    final reopenActions = YildiznameResultActionsBuilder.build(
      presentation: reopen,
      orContext: reopenOr,
    );

    expect(identical(liveActions, reopenActions), isFalse);
    phase7e1AssertShareableParity(liveActions, reopenActions);
    phase7e1AssertFavoriteParity(liveActions, reopenActions);
    expect(liveActions.canonicalInsight, reopenActions.canonicalInsight);
    expect(liveActions.copyText, reopenActions.copyText);
    expect(liveActions.continuationThemes, reopenActions.continuationThemes);
    // Intentional: live may carry transient birth context; reopen is prose-only.
    expect(
      liveActions.orContext!.toMetadata(),
      isNot(equals(reopenActions.orContext!.toMetadata())),
    );
  });
}

