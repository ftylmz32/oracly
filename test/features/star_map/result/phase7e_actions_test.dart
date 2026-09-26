/// Phase 7E — result actions builder, order, durability, parity.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/insight_copy/widgets/insight_copy_link.dart';
import 'package:oracly_new/features/ai/oracle_conversation/widgets/or_ask_button.dart';
import 'package:oracly_new/features/discovery_share/widgets/discovery_share_action.dart';
import 'package:oracly_new/features/favorite_moments/copy/favorite_moments_copy.dart';
import 'package:oracly_new/features/favorite_moments/presentation/widgets/save_favorite_moment_link.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_or_context.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_insight_copy.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';
import 'package:oracly_new/features/star_map/result/yildizname_canonical_insight.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_actions_builder.dart';

import '../../../support/yildizname_result_fixtures.dart';
import '../../../visual/yildizname/yildizname_visual_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  test('canonical insight prefers summary body over first section', () {
    final p = YildiznameArtifactPresentation.of(
      yildiznameFixtureNarrativeArtifact(
        summary: 'Özet öncelikli.',
        sectionTexts: const ['Bölüm gövdesi.'],
      ),
      chromeLocale: 'tr',
    );
    expect(YildiznameCanonicalInsight.of(p), 'Özet öncelikli.');
  });

  test('favorite requires durable id AND createdAt — no DateTime.now', () {
    final base = YildiznameResultPresentation.legacyLive(
      title: 'T',
      sections: const [],
      artifactId: 'yid_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    );
    expect(base.createdAtUtc, isNull);
    expect(base.actions.hasFavorite, isFalse);
    final withTime = YildiznameResultPresentation.legacyLive(
      title: 'T',
      sections: const [],
      artifactId: 'yid_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      createdAtUtc: DateTime.utc(2026, 1, 10),
    );
    expect(withTime.actions.hasFavorite, isTrue);
    expect(withTime.actions.favorite!.occurredAt, DateTime.utc(2026, 1, 10));
  });

  test('I same artifact presentation + OR → live/reopen action parity', () {
    final artifact = yildiznameFixtureNarrativeArtifact(
      id: 'yid_parityparityparityparityparity00',
      createdAtUtc: DateTime.utc(2026, 2, 2),
    );
    final presentation = YildiznameArtifactPresentation.of(
      artifact,
      chromeLocale: 'tr',
    );
    final or = YildiznameArtifactOrContext.build(artifact);
    final reopen = YildiznameResultActionsBuilder.build(
      presentation: presentation,
      orContext: or,
    );
    final liveReady = YildiznameResultActionsBuilder.build(
      presentation: presentation,
      orContext: or,
    );
    expect(reopen, liveReady);
    expect(reopen.favorite!.artifactId, artifact.id);
    expect(reopen.favorite!.occurredAt, artifact.createdAtUtc);
  });

  test('J reopen twice → identical favorite id / occurredAt', () {
    final artifact = yildiznameFixtureNarrativeArtifact(
      id: 'yid_jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj',
      createdAtUtc: DateTime.utc(2026, 3, 3),
    );
    final first =
        YildiznameArtifactPresentation.of(artifact, chromeLocale: 'tr');
    final second =
        YildiznameArtifactPresentation.of(artifact, chromeLocale: 'tr');
    expect(
      first.actions.favorite!.favoriteId,
      second.actions.favorite!.favoriteId,
    );
    expect(
      first.actions.favorite!.occurredAt,
      second.actions.favorite!.occurredAt,
    );
  });

  test('copy / share contain no internal ids', () {
    final p = YildiznameArtifactPresentation.of(
      yildiznameFixtureNarrativeArtifact(
        id: 'yid_cccccccccccccccdddddddddddddddd',
      ),
      chromeLocale: 'tr',
    );
    final blob =
        '${p.actions.copyText}|${p.actions.share.highlight}|${p.actions.share.caption}';
    for (final bad in const [
      'yid_',
      'theme.',
      'yth_',
      'factRef',
      'semanticFingerprint',
      'evidenceFingerprint',
      'ownerId',
    ]) {
      expect(blob.contains(bad), isFalse, reason: bad);
    }
  });

  testWidgets('A all actions present when durable + OR', (tester) async {
    final artifact = yildiznameFixtureNarrativeArtifact(
      createdAtUtc: DateTime.utc(2026, 1, 11),
    );
    final base =
        YildiznameArtifactPresentation.of(artifact, chromeLocale: 'tr');
    final presentation = base.withActions(
      YildiznameResultActionsBuilder.build(
        presentation: base,
        orContext: YildiznameArtifactOrContext.build(artifact),
      ),
    );
    final storage = await yildiznameVisualOpenStorage();
    await yildiznameVisualPumpSettled(
      tester,
      viewport: yildiznameVisualCanonicalViewport,
      storage: storage,
      child: StarMapReferenceResultScreen(presentation: presentation),
    );
    expect(find.byType(OrAskButton), findsOneWidget);
    expect(find.byType(DiscoveryShareAction), findsOneWidget);
    expect(find.byType(SaveFavoriteMomentLink), findsOneWidget);
    expect(find.byType(InsightCopyLink), findsOneWidget);
    expect(find.text(FavoriteMomentsCopy.sourceUnavailable), findsNothing);
  });

  testWidgets('D no favorite, no sourceUnavailable', (tester) async {
    final presentation = YildiznameResultPresentation.legacyLive(
      title: 'Gökyüzü',
      sections: yildiznameVisualLegacySections(),
    );
    expect(presentation.actions.hasFavorite, isFalse);
    final storage = await yildiznameVisualOpenStorage();
    await yildiznameVisualPumpSettled(
      tester,
      viewport: yildiznameVisualCanonicalViewport,
      storage: storage,
      child: StarMapReferenceResultScreen(presentation: presentation),
    );
    expect(find.byType(SaveFavoriteMomentLink), findsNothing);
    expect(find.text(FavoriteMomentsCopy.sourceUnavailable), findsNothing);
  });

  testWidgets('N core order OR then Share then Favorite then Copy',
      (tester) async {
    final artifact = yildiznameFixtureNarrativeArtifact(
      createdAtUtc: DateTime.utc(2026, 1, 11),
    );
    final base =
        YildiznameArtifactPresentation.of(artifact, chromeLocale: 'tr');
    final presentation = base.withActions(
      YildiznameResultActionsBuilder.build(
        presentation: base,
        orContext: YildiznameArtifactOrContext.build(artifact),
      ),
    );
    final storage = await yildiznameVisualOpenStorage();
    await yildiznameVisualPumpSettled(
      tester,
      viewport: yildiznameVisualCanonicalViewport,
      storage: storage,
      child: StarMapReferenceResultScreen(presentation: presentation),
    );
    final orY = tester.getTopLeft(find.byType(OrAskButton)).dy;
    final shareY = tester.getTopLeft(find.byType(DiscoveryShareAction)).dy;
    final favY = tester.getTopLeft(find.byType(SaveFavoriteMomentLink)).dy;
    final copyY = tester.getTopLeft(find.byType(InsightCopyLink)).dy;
    expect(orY, lessThan(shareY));
    expect(shareY, lessThan(favY));
    expect(favY, lessThan(copyY));
  });

  test('artifact OR forbidden firewall', () {
    final artifact = yildiznameFixtureNarrativeArtifact();
    final ctx = YildiznameArtifactOrContext.build(artifact);
    final blob =
        '${ctx.interpretationSummary}|${ctx.fullInterpretation}|${ctx.cardsSummary}|${ctx.readingTitle}';
    expect(YildiznameArtifactOrContext.containsForbidden(blob), isFalse);
  });

  test('copy text matches StarMapInsightCopy', () {
    final p = YildiznameArtifactPresentation.of(
      yildiznameFixtureNarrativeArtifact(),
      chromeLocale: 'tr',
    );
    expect(
      p.actions.copyText,
      StarMapInsightCopy.fromResult(
        title: p.title,
        sections: p.sections,
        planets: p.planets,
      ),
    );
  });
}
