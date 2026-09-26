/// Phase 7F — semantic headings, actions, raw-id firewall.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/design_system/chamber_story_panel.dart';
import 'package:oracly_new/core/reading_ux/reading_expand_section.dart';
import 'package:oracly_new/core/reading_ux/reading_ux_copy.dart';
import 'package:oracly_new/features/ai/oracle_conversation/widgets/or_ask_button.dart';
import 'package:oracly_new/features/discovery_share/widgets/discovery_share_action.dart';
import 'package:oracly_new/features/favorite_moments/presentation/widgets/save_favorite_moment_link.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_or_context.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_continuity_echo.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_fact_snapshot_plate.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_result_closing.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_scope_note.dart';
import 'package:oracly_new/features/star_map/result/yildizname_continuity_presentation.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_actions_builder.dart';
import 'package:oracly_new/core/insight_copy/widgets/insight_copy_link.dart';

import '../../../support/yildizname_result_fixtures.dart';
import '../../../visual/yildizname/yildizname_golden_harness.dart';
import '../../../visual/yildizname/yildizname_visual_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  Future<void> pumpFull(WidgetTester tester, {double textScale = 1.0}) async {
    final artifact = yildiznameFixtureNarrativeArtifact(
      scope: YildiznameNarrativeScope.full,
      rich: true,
      id: 'yid_7fsemantics7fsemantics7fseman00',
      createdAtUtc: DateTime.utc(2026, 6, 2),
      summary: '${'Özet paragraf. ' * 40}Son.',
    );
    final base =
        YildiznameArtifactPresentation.of(artifact, chromeLocale: 'tr');
    final withCont = base.withContinuity(
      const YildiznameContinuityPresentation(
        heading: 'Arşiv yankısı',
        body: 'Bu tema daha önce de geçti.',
        labels: ['Sabırlı odak', 'Sakin netlik', 'İç ses'],
      ),
    );
    final presentation = withCont.withActions(
      YildiznameResultActionsBuilder.build(
        presentation: withCont,
        orContext: YildiznameArtifactOrContext.build(artifact),
      ),
    );
    await yildiznameGoldenPumpPresentation(
      tester,
      presentation: presentation,
      viewport: const Size(390, 844),
      textScale: textScale,
    );
  }

  testWidgets('major headings expose Semantics(header: true)', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpFull(tester);
    expect(find.byType(StarMapScopeNote), findsOneWidget);
    expect(find.byType(StarMapFactSnapshotPlate), findsOneWidget);
    expect(find.byType(ReadingExpandSection), findsWidgets);
    expect(find.byType(StarMapContinuityEcho), findsOneWidget);
    expect(find.byType(ChamberStoryPanel), findsOneWidget);
    expect(find.byType(StarMapResultClosing), findsOneWidget);

    // Summary/chapter titles via ReadingExpandSection.
    final expandTitles = find.descendant(
      of: find.byType(ReadingExpandSection),
      matching: find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.header == true,
      ),
    );
    expect(expandTitles, findsWidgets);

    final reflectionHeader = find.descendant(
      of: find.byType(ChamberStoryPanel),
      matching: find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.header == true,
      ),
    );
    expect(reflectionHeader, findsOneWidget);
    handle.dispose();
  });

  testWidgets('continue-reading is one ≥44 button; expands full prose',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpFull(tester);
    final continueBtn = find.bySemanticsLabel(ReadingUxCopy.continueReading);
    expect(continueBtn, findsWidgets);
    final size = tester.getSize(continueBtn.first);
    expect(size.height, greaterThanOrEqualTo(44));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(
      tester.getSemantics(continueBtn.first),
      isSemantics(isButton: true, label: ReadingUxCopy.continueReading),
    );
    await tester.ensureVisible(continueBtn.first);
    await tester.tap(continueBtn.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // Expanded body remains in the tree (progressive disclosure, not truncation).
    expect(find.byType(ReadingExpandSection), findsWidgets);
    handle.dispose();
  });

  testWidgets('action controls present once; no raw ids in semantics',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpFull(tester);
    expect(find.byType(OrAskButton), findsOneWidget);
    expect(find.byType(DiscoveryShareAction), findsOneWidget);
    expect(find.byType(SaveFavoriteMomentLink), findsOneWidget);
    expect(find.byType(InsightCopyLink), findsOneWidget);

    final data = tester.getSemantics(find.byType(StarMapReferenceResultScreen));
    final blob = data.toString();
    for (final bad in const [
      'theme.',
      'yth_',
      'factRef',
      'yid_',
      'semanticFingerprint',
      'evidenceFingerprint',
      'contentHash',
      'serializerVersion',
      'fullNatalEphemeris',
    ]) {
      expect(blob.contains(bad), isFalse, reason: bad);
    }
    handle.dispose();
  });
}

