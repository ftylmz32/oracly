/// Phase 7D — role-aware section renderer + visual order + prose safety.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/design_system/chamber_narrative_block.dart';
import 'package:oracly_new/core/design_system/chamber_reading_lane.dart';
import 'package:oracly_new/core/design_system/chamber_story_panel.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_continuity_echo.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_result_closing.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_result_section_card.dart';
import 'package:oracly_new/features/star_map/result/yildizname_continuity_presentation.dart';

import '../../../support/yildizname_result_fixtures.dart';
import '../../../visual/yildizname/yildizname_visual_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  testWidgets('summary uses hero narrative block', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StarMapResultSectionCard(
            section: StarMapResultSection(
              title: 'Özet',
              body: 'Uzun özet metni saklanır.',
              role: YildiznameSectionRole.summary,
            ),
          ),
        ),
      ),
    );
    expect(find.byType(ChamberNarrativeBlock), findsOneWidget);
    expect(find.byType(ChamberReadingLane), findsNothing);
  });

  testWidgets('chapter uses reading lane', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StarMapResultSectionCard(
            section: StarMapResultSection(
              title: 'Kimlik',
              body: 'Bölüm metni.',
              role: YildiznameSectionRole.chapter,
            ),
          ),
        ),
      ),
    );
    expect(find.byType(ChamberReadingLane), findsOneWidget);
    expect(find.byType(ChamberNarrativeBlock), findsNothing);
  });

  testWidgets('reflection uses story panel — not lane, not ritual invite',
      (tester) async {
    final long = 'Uzun bir yansıma sorusu. ' * 20;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StarMapResultSectionCard(
              section: StarMapResultSection(
                title: 'Yansıma',
                body: long,
                role: YildiznameSectionRole.reflection,
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(ChamberStoryPanel), findsOneWidget);
    expect(find.byType(ChamberReadingLane), findsNothing);
    expect(find.textContaining('Uzun bir yansıma'), findsOneWidget);
  });

  testWidgets('closing uses epilogue widget', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StarMapResultSectionCard(
            section: StarMapResultSection(
              title: 'Kapanış',
              body: 'Arşiv kapanır.',
              role: YildiznameSectionRole.closing,
            ),
          ),
        ),
      ),
    );
    expect(find.byType(StarMapResultClosing), findsOneWidget);
    expect(find.byType(ChamberReadingLane), findsNothing);
  });

  testWidgets('visual order: chapters then continuity then reflection',
      (tester) async {
    final base = YildiznameArtifactPresentation.of(
      yildiznameFixtureNarrativeArtifact(
        summary: 'Özet metni.',
        sectionTexts: const ['Bölüm bir.'],
        reflection: 'Yansıma sorusu?',
        closing: 'Kapanış cümlesi.',
      ),
      chromeLocale: 'tr',
    );
    final presentation = base.withContinuity(
      const YildiznameContinuityPresentation(
        heading: 'Arşiv yankısı',
        body: 'Bu temalar önceki Yıldızname okumalarında da tekrar etmişti.',
        labels: ['Sabır'],
      ),
    );
    final storage = await yildiznameVisualOpenStorage();
    await yildiznameVisualPumpSettled(
      tester,
      viewport: yildiznameVisualCanonicalViewport,
      storage: storage,
      child: StarMapReferenceResultScreen(presentation: presentation),
    );
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    final summaryAt = texts.indexWhere((t) => t.contains('Özet metni'));
    final chapterAt = texts.indexWhere((t) => t.contains('Bölüm bir'));
    final echoAt = texts.indexWhere((t) => t.contains('Arşiv yankısı'));
    final sabirAt = texts.indexWhere((t) => t == 'Sabır');
    final reflectionAt =
        texts.indexWhere((t) => t.contains('Yansıma sorusu'));
    final closingAt =
        texts.indexWhere((t) => t.contains('Kapanış cümlesi'));
    expect(summaryAt, greaterThanOrEqualTo(0));
    expect(chapterAt, greaterThan(summaryAt));
    expect(echoAt, greaterThan(chapterAt));
    expect(sabirAt, greaterThan(echoAt));
    expect(reflectionAt, greaterThan(sabirAt));
    expect(closingAt, greaterThan(reflectionAt));
    expect(find.byType(StarMapContinuityEcho), findsOneWidget);
  });

  testWidgets('continuity absent → no placeholder', (tester) async {
    final presentation = YildiznameArtifactPresentation.of(
      yildiznameFixtureNarrativeArtifact(),
      chromeLocale: 'tr',
    );
    expect(presentation.continuity.isEmpty, isTrue);
    final storage = await yildiznameVisualOpenStorage();
    await yildiznameVisualPumpSettled(
      tester,
      viewport: yildiznameVisualCanonicalViewport,
      storage: storage,
      child: StarMapReferenceResultScreen(presentation: presentation),
    );
    expect(find.byType(StarMapContinuityEcho), findsNothing);
    expect(find.textContaining('Arşiv yankısı'), findsNothing);
  });

  testWidgets('prose unchanged at textScale 1.3', (tester) async {
    const reflection =
        'Bu yansıma tam olarak saklanmalı ve kesilmemeli.';
    final presentation = YildiznameArtifactPresentation.of(
      yildiznameFixtureNarrativeArtifact(reflection: reflection),
      chromeLocale: 'tr',
    );
    final storage = await yildiznameVisualOpenStorage();
    await yildiznameVisualPumpSettled(
      tester,
      storage: storage,
      textScale: 1.3,
      viewport: const Size(360, 800),
      child: StarMapReferenceResultScreen(presentation: presentation),
    );
    expect(find.text(reflection), findsOneWidget);
  });
}
