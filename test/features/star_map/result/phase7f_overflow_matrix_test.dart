/// Phase 7F — overflow firewall for the responsive viewport matrix.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_or_context.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_actions_builder.dart';

import '../../../support/yildizname_result_fixtures.dart';
import '../../../visual/yildizname/yildizname_golden_harness.dart';
import '../../../visual/yildizname/yildizname_visual_harness.dart';

const _matrix = <(Size, double)>[
  (Size(320, 568), 1.0),
  (Size(320, 568), 1.3),
  (Size(320, 568), 2.0),
  (Size(360, 800), 1.0),
  (Size(360, 800), 1.3),
  (Size(360, 800), 2.0),
  (Size(375, 812), 1.3),
  (Size(390, 844), 1.0),
  (Size(390, 844), 1.3),
  (Size(390, 844), 2.0),
  (Size(393, 852), 1.3),
  (Size(412, 915), 1.3),
  (Size(430, 932), 1.0),
  (Size(430, 932), 2.0),
  (Size(600, 900), 1.3),
  (Size(768, 1024), 1.3),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  for (final entry in _matrix) {
    final size = entry.$1;
    final scale = entry.$2;
    testWidgets(
      'FULL rich no overflow @ ${size.width.toInt()}x${size.height.toInt()} ts$scale',
      (tester) async {
        final errors = <Object>[];
        final old = FlutterError.onError;
        FlutterError.onError = (details) {
          final text = details.exceptionAsString();
          if (text.contains('overflowed') || text.contains('RenderFlex')) {
            errors.add(details.exception);
          }
          old?.call(details);
        };
        addTearDown(() => FlutterError.onError = old);

        final artifact = yildiznameFixtureNarrativeArtifact(
          scope: YildiznameNarrativeScope.full,
          rich: true,
          id: 'yid_7fmatrix7fmatrix7fmatrix7fmat00',
          createdAtUtc: DateTime.utc(2026, 6, 1),
          summary: '${'Uzun özet. ' * 24}Son.',
          sectionTexts: [
            '${'Birinci bölüm gövdesi. ' * 30}Son.',
            '${'İkinci bölüm gövdesi. ' * 28}Son.',
            '${'Üçüncü bölüm gövdesi. ' * 26}Son.',
          ],
          reflection: '${'Yansıma metni. ' * 20}Son.',
          closing: '${'Kapanış cümlesi. ' * 18}Son.',
        );
        final base =
            YildiznameArtifactPresentation.of(artifact, chromeLocale: 'tr');
        final presentation = base
            .withActions(
              YildiznameResultActionsBuilder.build(
                presentation: base,
                orContext: YildiznameArtifactOrContext.build(artifact),
              ),
            );
        await yildiznameGoldenPumpPresentation(
          tester,
          presentation: presentation,
          viewport: size,
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        expect(errors, isEmpty, reason: '$errors');
        if (size.width >= 600) {
          expect(find.byType(StarMapReferenceResultScreen), findsOneWidget);
        }
      },
    );
  }
}

