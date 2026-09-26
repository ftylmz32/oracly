/// Phase 7G — presentation pump helpers (test-only).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/constants/app_assets.dart';
import 'package:oracly_new/features/birth_chart/data/birth_chart_record_mapper.dart';
import 'package:oracly_new/features/birth_chart/services/natal_chart_calculator.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_or_context.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_continuity_echo.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_screen.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_actions_builder.dart';

import '../../features/birth_chart/evidence/test_birth_owner.dart';
import 'yildizname_phase7g_fixtures.dart';
import 'yildizname_visual_harness.dart';

export 'yildizname_phase7g_asserts.dart';
export 'yildizname_phase7g_parity.dart';

const phase7gPrecacheAssets = [
  AppAssets.yildiznameArchiveBg,
  AppAssets.yildiznameHero,
];

YildiznameResultPresentation phase7gNarrativeOf(
  YildiznameArtifact artifact, {
  String chromeLocale = 'tr',
  bool withOr = true,
  bool withContinuity = false,
}) {
  var base =
      YildiznameArtifactPresentation.of(artifact, chromeLocale: chromeLocale);
  if (withContinuity) base = base.withContinuity(phase7gContinuity);
  return base.withActions(
    YildiznameResultActionsBuilder.build(
      presentation: base,
      orContext: withOr ? YildiznameArtifactOrContext.build(artifact) : null,
    ),
  );
}

Future<GlobalKey> phase7gPumpHub(
  WidgetTester tester, {
  required bool withBirth,
}) async {
  final storage = await yildiznameVisualOpenStorage();
  if (withBirth) {
    final chart =
        const NatalChartCalculator().calculate(yildiznameVisualBirthProfile());
    await testBirthChartRepo(storage)
        .save(BirthChartRecordMapper.toRecord(chart));
  }
  final key = GlobalKey();
  await yildiznameVisualPumpSettled(
    tester,
    viewport: yildiznameVisualCanonicalViewport,
    storage: storage,
    captureKey: key,
    precacheAssets: phase7gPrecacheAssets,
    child: const StarMapReferenceScreen(),
  );
  await tester.pump(const Duration(milliseconds: 300));
  return key;
}

Future<GlobalKey> phase7gPumpPresentation(
  WidgetTester tester, {
  required YildiznameResultPresentation presentation,
  Size viewport = yildiznameVisualCanonicalViewport,
  double textScale = 1.0,
  List<Override> overrides = const [],
  bool openDeeper = false,
  bool revealContinuity = false,
}) async {
  final storage = await yildiznameVisualOpenStorage();
  final key = GlobalKey();
  await yildiznameVisualPumpSettled(
    tester,
    viewport: viewport,
    textScale: textScale,
    storage: storage,
    captureKey: key,
    overrides: overrides,
    precacheAssets: phase7gPrecacheAssets,
    child: StarMapReferenceResultScreen(presentation: presentation),
  );
  if (openDeeper) {
    final toggle = find.byKey(const ValueKey('starFactMoreToggle'));
    if (toggle.evaluate().isNotEmpty) {
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 4000));
      await tester.pumpAndSettle();
    }
  }
  if (revealContinuity) {
    final echo = find.byType(StarMapContinuityEcho);
    expect(echo, findsOneWidget);
    await tester.ensureVisible(echo);
    await tester.pumpAndSettle();
  }
  return key;
}
