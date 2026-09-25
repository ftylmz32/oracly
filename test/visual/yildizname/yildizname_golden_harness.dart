/// Phase 7A — golden compare helpers (test-only).
library;

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/data/birth_chart_record_mapper.dart';
import 'package:oracly_new/features/birth_chart/services/natal_chart_calculator.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_factory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_or_context.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_legacy_payload.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_legacy_section_kind.dart';
import 'package:oracly_new/features/star_map/models/star_map_reading.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_artifact_reopen_screen.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_screen.dart';

import '../../features/birth_chart/evidence/test_birth_owner.dart';
import 'yildizname_visual_harness.dart';

String yildiznameGoldenPath(String name) =>
    '../../goldens/yildizname/$name.png';

const yildiznameGoldenMasterDir = 'test/goldens/yildizname';

/// Phase 7B expected-delta fixtures — phase-scoped, NEVER the 7A masters.
/// The frozen 7A masters above stay untouched; the final master refresh
/// belongs to Phase 7G.
const yildiznamePhase7bGoldenDir = 'test/goldens/yildizname/phase7b';

String yildiznamePhase7bGoldenPath(String name) =>
    '../../goldens/yildizname/phase7b/$name.png';

Future<void> yildiznamePhase7bGoldenExpect(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await expectLater(
    find.byKey(key),
    matchesGoldenFile(yildiznamePhase7bGoldenPath(name)),
  );
}

Future<void> yildiznameGoldenExpect(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await expectLater(
    find.byKey(key),
    matchesGoldenFile(yildiznameGoldenPath(name)),
  );
}

String yildiznameGoldenSha256(String relativePath) {
  final bytes = File(relativePath).readAsBytesSync();
  return sha256.convert(bytes).toString();
}

Future<GlobalKey> yildiznameGoldenPumpHub(
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
    child: const StarMapReferenceScreen(),
  );
  await tester.pump(const Duration(milliseconds: 300));
  return key;
}

/// Phase 7A pre-typed chrome path (display-ready strings, NO scope claim).
///
/// Frozen forensic baseline: keeps the 7A pixel masters exercising the shared
/// chrome unchanged. Phase 7B production paths use the typed presentation —
/// see [yildiznameGoldenPumpPresentation].
Future<GlobalKey> yildiznameGoldenPumpResult(
  WidgetTester tester, {
  required String title,
  required List<StarMapResultSection> sections,
  List<StarMapPlanetInfluence> planets = const [],
  String? artifactId,
  DateTime? artifactCreatedAt,
}) async {
  final storage = await yildiznameVisualOpenStorage();
  final key = GlobalKey();
  await yildiznameVisualPumpSettled(
    tester,
    viewport: yildiznameVisualCanonicalViewport,
    storage: storage,
    captureKey: key,
    child: StarMapReferenceResultScreen.unscoped(
      title: title,
      sections: sections,
      planets: planets,
      artifactId: artifactId,
      artifactCreatedAt: artifactCreatedAt,
    ),
  );
  return key;
}

YildiznameArtifact yildiznameGoldenLegacyArtifact() =>
    YildiznameArtifactFactory.createLegacy(
      ownerId: 'visual-o1',
      id: 'yid_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      title: 'Gökyüzü Mesajı',
      sections: yildiznameVisualLegacySections(),
      sectionKind: YildiznameLegacySectionKind.skyMessage,
      locale: 'tr',
      planets: yildiznameVisualLegacyPlanets(),
      sunSignId: 'leo',
      dayKey: '2026-01-10',
      createdAtUtc: DateTime.utc(2026, 1, 10),
    );

/// Pre-7B legacy artifact reopen chrome (7A master `artifact_legacy_reopen`).
///
/// Renders the STORED legacy payload through the unscoped 7A chrome path — the
/// exact pre-7B reopen output. Production reopen (typed presentation + scope
/// note) is covered by [yildiznameGoldenPumpLegacyArtifactReopen].
Future<GlobalKey> yildiznameGoldenPumpLegacyArtifact(
  WidgetTester tester,
) async {
  final storage = await yildiznameVisualOpenStorage();
  final artifact = yildiznameGoldenLegacyArtifact();
  final key = GlobalKey();
  await yildiznameVisualPumpSettled(
    tester,
    viewport: yildiznameVisualCanonicalViewport,
    storage: storage,
    captureKey: key,
    child: StarMapReferenceResultScreen.unscoped(
      title: YildiznameLegacyPayload.titleOf(artifact.payload) ?? '',
      sections: YildiznameLegacyPayload.sectionsOf(artifact.payload),
      planets: YildiznameLegacyPayload.planetsOf(artifact.payload),
      artifactId: artifact.id,
      artifactCreatedAt: artifact.createdAtUtc,
      readingContext: YildiznameArtifactOrContext.build(artifact),
    ),
  );
  return key;
}

/// Phase 7B production legacy reopen — typed presentation + scope note.
Future<GlobalKey> yildiznameGoldenPumpLegacyArtifactReopen(
  WidgetTester tester, {
  Size viewport = yildiznameVisualCanonicalViewport,
  double textScale = 1.0,
}) async {
  final storage = await yildiznameVisualOpenStorage();
  final key = GlobalKey();
  await yildiznameVisualPumpSettled(
    tester,
    viewport: viewport,
    textScale: textScale,
    storage: storage,
    captureKey: key,
    child: StarMapArtifactReopenScreen(artifact: yildiznameGoldenLegacyArtifact()),
  );
  return key;
}

/// Phase 7B production presentation pump (typed presentation, scope note).
Future<GlobalKey> yildiznameGoldenPumpPresentation(
  WidgetTester tester, {
  required YildiznameResultPresentation presentation,
  Size viewport = yildiznameVisualCanonicalViewport,
  double textScale = 1.0,
}) async {
  final storage = await yildiznameVisualOpenStorage();
  final key = GlobalKey();
  await yildiznameVisualPumpSettled(
    tester,
    viewport: viewport,
    textScale: textScale,
    storage: storage,
    captureKey: key,
    child: StarMapReferenceResultScreen(presentation: presentation),
  );
  return key;
}
