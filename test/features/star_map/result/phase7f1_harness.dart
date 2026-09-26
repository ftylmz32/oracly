/// Phase 7F.1 — shared pump / semantics helpers (test-only).
library;

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/personal_discovery/models/cross_discovery_insight.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_theme_strength.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/personal_discovery/providers/personal_discovery_providers.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_or_context.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';
import 'package:oracly_new/features/star_map/result/yildizname_continuity_presentation.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_actions.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_actions_builder.dart';

import '../../../support/yildizname_result_fixtures.dart';
import '../../../visual/yildizname/yildizname_visual_harness.dart';

export 'phase7f1_actions.dart';

PersonalDiscoveryProfile phase7f1CrossModalProfile() => PersonalDiscoveryProfile(
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
    );

Override phase7f1DiscoveryOverride([PersonalDiscoveryProfile? profile]) =>
    personalDiscoveryProfileProvider.overrideWith(
      (ref) async => profile ?? phase7f1CrossModalProfile(),
    );

Future<YildiznameResultPresentation> phase7f1FullPresentation({
  bool withOr = true,
  bool withFavorite = true,
  bool withContinuity = true,
}) async {
  final artifact = yildiznameFixtureNarrativeArtifact(
    scope: YildiznameNarrativeScope.full,
    rich: true,
    id: 'yid_7f1accept7f1accept7f1accept7f100',
    createdAtUtc: DateTime.utc(2026, 6, 10),
    summary: '${'Özet paragrafı. ' * 42}Son.',
    sectionTexts: [
      '${'Birinci bölüm. ' * 36}Son.',
      '${'İkinci bölüm. ' * 34}Son.',
    ],
    reflection: '${'Yansıma metni. ' * 22}Son.',
    closing: '${'Kapanış cümlesi. ' * 18}Son.',
  );
  var base = YildiznameArtifactPresentation.of(artifact, chromeLocale: 'tr');
  if (withContinuity) {
    base = base.withContinuity(
      const YildiznameContinuityPresentation(
        heading: 'Arşiv yankısı',
        body: 'Bu tema daha önce de geçti.',
        labels: ['Sabırlı odak', 'Sakin netlik'],
      ),
    );
  }
  final built = YildiznameResultActionsBuilder.build(
    presentation: base,
    orContext: withOr ? YildiznameArtifactOrContext.build(artifact) : null,
  );
  return base.withActions(
    YildiznameResultActions(
      canonicalInsight: built.canonicalInsight,
      copyText: built.copyText,
      share: built.share,
      orContext: withOr ? built.orContext : null,
      favorite: withFavorite ? built.favorite : null,
      continuationThemes: built.continuationThemes,
    ),
  );
}

Future<void> phase7f1Pump(
  WidgetTester tester, {
  required YildiznameResultPresentation presentation,
  Size viewport = const Size(390, 844),
  double textScale = 1.0,
  List<Override> overrides = const [],
}) async {
  final storage = await yildiznameVisualOpenStorage();
  await yildiznameVisualPumpSettled(
    tester,
    viewport: viewport,
    textScale: textScale,
    storage: storage,
    overrides: overrides,
    child: StarMapReferenceResultScreen(presentation: presentation),
  );
}

List<SemanticsNode> phase7f1Traverse(SemanticsNode root) {
  final out = <SemanticsNode>[];
  void visit(SemanticsNode n) {
    out.add(n);
    n.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(root);
  return out;
}

List<SemanticsNode> phase7f1ActionButtons(SemanticsNode root) => [
      for (final n in phase7f1Traverse(root))
        if (n.flagsCollection.isButton && n.label.isNotEmpty) n,
    ];

int phase7f1ButtonCount(SemanticsNode root, String label) =>
    phase7f1ActionButtons(root).where((n) => n.label == label).length;
