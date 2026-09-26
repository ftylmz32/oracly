/// Phase 7G — deterministic production presentation fixtures (test-only).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/personal_discovery/models/cross_discovery_insight.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_theme_strength.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/personal_discovery/providers/personal_discovery_providers.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_factory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_or_context.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_legacy_section_kind.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_section_kind.dart';
import 'package:oracly_new/features/star_map/result/yildizname_continuity_presentation.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_actions_builder.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_presentation.dart';

import '../../support/yildizname_result_fixtures.dart';
import 'yildizname_visual_harness.dart';

const phase7gFullKinds = [
  YildiznameSectionKind.coreIdentity,
  YildiznameSectionKind.emotionalWorld,
  YildiznameSectionKind.anglesAndHouses,
];

const phase7gContinuity = YildiznameContinuityPresentation(
  heading: 'Arşiv yankısı',
  body: 'Bu temalar önceki Yıldızname okumalarında da tekrar etmişti.',
  labels: ['Sabır', 'Kariyer', 'İç ses'],
);

Override phase7gDiscoveryOverride() =>
    personalDiscoveryProfileProvider.overrideWith(
      (ref) async => PersonalDiscoveryProfile(
        crossInsights: [
          CrossDiscoveryInsight(
            theme: 'ilişki',
            sources: const ['coffee', 'star'],
            confidence: DiscoveryThemeStrength.recurring,
            lastObserved: DateTime(2026, 8, 18),
            sourceCount: 2,
            discoveryCount: 2,
            recencyWeight: 0.9,
          ),
        ],
      ),
    );

OracleReadingContext phase7gLegacyOr(String id) => OracleReadingContext(
      sessionId: id,
      kind: OracleReadingKind.starMap,
      sourceLabel: 'Yıldızname',
      spreadLabel: 'Gökyüzü',
      deckId: 'star_map',
      deckName: 'Yıldızname',
      readingTitle: 'Gökyüzü Mesajı',
      cardsSummary: 'Güneş · odak',
      interpretationSummary: 'Bugün sakin bir nefes al.',
      fullInterpretation: 'Bugün sakin bir nefes al. Arşiv sessizce yanında.',
    );

YildiznameResultPresentation phase7gLegacyLive({
  required bool durable,
  required bool withOr,
}) {
  const id = 'yid_7glegacy7glegacy7glegacy7gleg00';
  final base = YildiznameResultPresentation.legacyLive(
    title: 'Gökyüzü Mesajı',
    sections: yildiznameVisualLegacySections(),
    planets: yildiznameVisualLegacyPlanets(),
    artifactId: durable ? id : null,
    createdAtUtc: durable ? DateTime.utc(2026, 7, 1) : null,
  );
  return base.withActions(
    YildiznameResultActionsBuilder.build(
      presentation: base,
      orContext: withOr ? phase7gLegacyOr(id) : null,
    ),
  );
}

YildiznameArtifact phase7gLegacyArtifact() =>
    YildiznameArtifactFactory.createLegacy(
      ownerId: 'visual-7g',
      id: 'yid_7glegart7glegart7glegart7glea00',
      title: 'Gökyüzü Mesajı',
      sections: yildiznameVisualLegacySections(),
      sectionKind: YildiznameLegacySectionKind.skyMessage,
      locale: 'tr',
      planets: yildiznameVisualLegacyPlanets(),
      sunSignId: 'leo',
      dayKey: '2026-07-01',
      createdAtUtc: DateTime.utc(2026, 7, 1),
    );

YildiznameResultPresentation phase7gLegacyArtifactReopen() {
  final artifact = phase7gLegacyArtifact();
  final base =
      YildiznameArtifactPresentation.of(artifact, chromeLocale: 'tr');
  return base.withActions(
    YildiznameResultActionsBuilder.build(
      presentation: base,
      orContext: YildiznameArtifactOrContext.build(artifact),
    ),
  );
}

YildiznameArtifact phase7gNarrativeArtifact({
  YildiznameNarrativeScope scope = YildiznameNarrativeScope.full,
  bool rich = true,
  String id = 'yid_7gnarrat7gnarrat7gnarrat7gnar00',
}) =>
    yildiznameFixtureNarrativeArtifact(
      scope: scope,
      rich: rich,
      kinds: scope == YildiznameNarrativeScope.full
          ? phase7gFullKinds
          : const [YildiznameSectionKind.coreIdentity],
      languageCode: 'tr',
      id: id,
      createdAtUtc: DateTime.utc(2026, 7, 2),
      summary: scope == YildiznameNarrativeScope.full
          ? 'Güneş, Ay ve Yükselen birlikte sabırlı bir kimlik ekseni kurar.'
          : 'Güneş Leo konumunda sabırlı bir odak taşır.',
      sectionTexts: scope == YildiznameNarrativeScope.full
          ? const [
              'Doğum göğünde kimlik net ve sakin duruyor.',
              'Duygusal dünya yumuşak bir ritme çağırıyor.',
              'Açılar ve evler derinleşmeyi destekliyor.',
            ]
          : const ['Kimlik alanında sakin bir netlik aranıyor.'],
      reflection: 'Hangi katman sana en dürüst geliyor?',
      closing: 'Arşiv kapanır; sen kendi ritmine dönersin.',
    );
