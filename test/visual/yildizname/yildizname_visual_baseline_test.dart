/// Phase 7A — structural visual baselines (settled, no provider).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('current narrative reduced exposes raw titles (blocker B1)',
      (tester) async {
    await yildiznameGoldenPumpResult(
      tester,
      title: 'Yıldızname',
      sections: yildiznameVisualNarrativeReducedSections(),
      artifactId: 'yid_bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      artifactCreatedAt: DateTime.utc(2026, 1, 10),
    );
    // Documents CURRENT production adapter debt — fix in 7B, not 7A.
    expect(find.text('summary'), findsOneWidget);
    expect(find.text('coreIdentity'), findsOneWidget);
    expect(find.text('reflection'), findsOneWidget);
    expect(find.text('closing'), findsOneWidget);
    expect(find.textContaining('reducedNatal'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
