/// Phase 7A — structural visual baselines (settled, no provider).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/copy/star_map_polish_copy.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_app_bar.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_chart.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_screen.dart';
import 'package:oracly_new/shared/widgets/oracly_adaptive_scroll_view.dart';
import 'package:oracly_new/shared/widgets/oracly_scaffold.dart';

import 'yildizname_golden_harness.dart';
import 'yildizname_visual_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  testWidgets('hub empty settles — one chart, no overflow', (tester) async {
    final key = await yildiznameGoldenPumpHub(tester, withBirth: false);
    expect(find.byType(StarMapReferenceScreen), findsOneWidget);
    expect(find.byType(StarMapReferenceChart), findsOneWidget);
    expect(find.byType(StarMapReferenceAppBar), findsOneWidget);
    expect(find.text(StarMapPolishCopy.enterBirthInfo), findsOneWidget);
    expect(tester.takeException(), isNull);
    await yildiznameVisualMaybeCapture(tester, key, 'hub_empty');
  });

  testWidgets('hub with birth settles — chart ready', (tester) async {
    final key = await yildiznameGoldenPumpHub(tester, withBirth: true);
    expect(find.text(StarMapPolishCopy.chartReady), findsOneWidget);
    expect(find.byType(StarMapReferenceChart), findsOneWidget);
    expect(tester.takeException(), isNull);
    await yildiznameVisualMaybeCapture(tester, key, 'hub_with_birth');
  });

  testWidgets('legacy result — one scroll owner, no nested scaffold',
      (tester) async {
    final key = await yildiznameGoldenPumpResult(
      tester,
      title: 'Gökyüzü Mesajı',
      sections: yildiznameVisualLegacySections(),
      planets: yildiznameVisualLegacyPlanets(),
    );
    expect(find.byType(StarMapReferenceResultScreen), findsOneWidget);
    expect(find.byType(OraclyScaffold), findsOneWidget);
    expect(find.byType(OraclyAdaptiveScrollView), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget); // MaterialApp harness only
    expect(find.textContaining('theme.'), findsNothing);
    expect(find.textContaining('factRef'), findsNothing);
    expect(tester.takeException(), isNull);
    await yildiznameVisualMaybeCapture(tester, key, 'legacy_result');
  });

  testWidgets('B1 closed — Narrative adapter never exposes raw titles',
      (tester) async {
    // 7A documented raw `summary` / `coreIdentity` / `reflection` / `closing`
    // leaking from the adapter. 7B routes the SAME content through the typed
    // production projection: chrome is localized, prose is untouched.
    final artifact = yildiznameVisualNarrativeArtifact(
      id: 'yid_bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      full: false,
    );
    await yildiznameGoldenPumpPresentation(
      tester,
      presentation: YildiznameArtifactPresentation.of(
        artifact,
        chromeLocale: 'tr',
      ),
    );
    expect(find.text('summary'), findsNothing);
    expect(find.text('coreIdentity'), findsNothing);
    expect(find.text('reflection'), findsNothing);
    expect(find.text('closing'), findsNothing);
    expect(find.text('Özet'), findsOneWidget);
    expect(find.text('Kimlik'), findsOneWidget);
    expect(find.text('Üzerine düşün'), findsOneWidget);
    expect(find.text('Kapanış'), findsOneWidget);
    expect(find.textContaining('reducedNatal'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
