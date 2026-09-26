/// Phase 7F — phase-scoped responsive/a11y expected-delta goldens.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_or_context.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_actions_builder.dart';

import '../../support/yildizname_result_fixtures.dart';
import 'yildizname_golden_harness.dart';
import 'yildizname_visual_harness.dart';

const yildiznamePhase7fGoldenNames = <String>[
  'phase7f_full_rich_320x568',
  'phase7f_full_rich_430x932',
  'phase7f_full_rich_360x800_ts20',
  'phase7f_full_rich_768x1024',
  'phase7f_reduced_320x568_ts13',
  'phase7f_ru_320x568_ts13',
  'phase7f_deeper_open_320x568_ts20',
  'phase7f_longform_360x800_ts20',
];

Future<void> _pump(
  WidgetTester tester, {
  required Size viewport,
  double textScale = 1.0,
  required String name,
  YildiznameNarrativeScope scope = YildiznameNarrativeScope.full,
  bool rich = true,
  String chromeLocale = 'tr',
  String languageCode = 'tr',
  bool openDeeper = false,
  String summary = 'Güneş Leo konumunda sabırlı bir odak taşır.',
}) async {
  final artifact = yildiznameFixtureNarrativeArtifact(
    scope: scope,
    rich: rich,
    languageCode: languageCode,
    id: 'yid_7fgolden7fgolden7fgolden7fgol00',
    createdAtUtc: DateTime.utc(2026, 6, 4),
    summary: summary,
  );
  final base = YildiznameArtifactPresentation.of(
    artifact,
    chromeLocale: chromeLocale,
  );
  final presentation = base.withActions(
    YildiznameResultActionsBuilder.build(
      presentation: base,
      orContext: YildiznameArtifactOrContext.build(artifact),
    ),
  );
  final key = await yildiznameGoldenPumpPresentation(
    tester,
    presentation: presentation,
    viewport: viewport,
    textScale: textScale,
  );
  if (openDeeper) {
    final toggle = find.byKey(const ValueKey('starFactMoreToggle'));
    if (toggle.evaluate().isNotEmpty) {
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle, warnIfMissed: false);
      await tester.pumpAndSettle();
      // Return to top so the golden captures the heading chrome consistently.
      final scrollable = find.byType(Scrollable).first;
      await tester.drag(scrollable, const Offset(0, 4000));
      await tester.pumpAndSettle();
    }
  }
  await yildiznamePhase7fGoldenExpect(tester, key, name);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  testWidgets('phase7f_full_rich_320x568', (tester) async {
    await _pump(
      tester,
      viewport: const Size(320, 568),
      name: 'phase7f_full_rich_320x568',
    );
  });

  testWidgets('phase7f_full_rich_430x932', (tester) async {
    await _pump(
      tester,
      viewport: const Size(430, 932),
      name: 'phase7f_full_rich_430x932',
    );
  });

  testWidgets('phase7f_full_rich_360x800_ts20', (tester) async {
    await _pump(
      tester,
      viewport: const Size(360, 800),
      textScale: 2.0,
      name: 'phase7f_full_rich_360x800_ts20',
    );
  });

  testWidgets('phase7f_full_rich_768x1024', (tester) async {
    await _pump(
      tester,
      viewport: const Size(768, 1024),
      name: 'phase7f_full_rich_768x1024',
    );
  });

  testWidgets('phase7f_reduced_320x568_ts13', (tester) async {
    await _pump(
      tester,
      viewport: const Size(320, 568),
      textScale: 1.3,
      scope: YildiznameNarrativeScope.reduced,
      rich: false,
      name: 'phase7f_reduced_320x568_ts13',
    );
  });

  testWidgets('phase7f_ru_320x568_ts13', (tester) async {
    await yildiznameVisualBindLocale('ru');
    await _pump(
      tester,
      viewport: const Size(320, 568),
      textScale: 1.3,
      chromeLocale: 'ru',
      languageCode: 'ru',
      name: 'phase7f_ru_320x568_ts13',
    );
  });

  testWidgets('phase7f_deeper_open_320x568_ts20', (tester) async {
    await _pump(
      tester,
      viewport: const Size(320, 568),
      textScale: 2.0,
      openDeeper: true,
      name: 'phase7f_deeper_open_320x568_ts20',
    );
  });

  testWidgets('phase7f_longform_360x800_ts20', (tester) async {
    await _pump(
      tester,
      viewport: const Size(360, 800),
      textScale: 2.0,
      summary: '${'Çok uzun arşiv özeti. ' * 40}Son.',
      name: 'phase7f_longform_360x800_ts20',
    );
  });

  test('phase7f golden inventory is phase-scoped', () {
    expect(Directory(yildiznamePhase7fGoldenDir).existsSync(), isTrue);
    expect(yildiznamePhase7fGoldenNames, hasLength(8));
  });
}

