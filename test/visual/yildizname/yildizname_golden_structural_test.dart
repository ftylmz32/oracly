/// Phase 7A — viewport / structural invariants.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_app_bar.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_result_footer.dart';
import 'package:oracly_new/shared/widgets/oracly_adaptive_scroll_view.dart';

import 'yildizname_golden_harness.dart';
import 'yildizname_visual_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  for (final size in yildiznameVisualViewports) {
    testWidgets(
        'legacy result no overflow @ ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      final storage = await yildiznameVisualOpenStorage();
      await yildiznameVisualPumpSettled(
        tester,
        viewport: size,
        storage: storage,
        child: StarMapReferenceResultScreen(
          title: 'Gökyüzü Mesajı',
          sections: yildiznameVisualLegacySections(),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(StarMapReferenceAppBar), findsOneWidget);
      expect(find.byType(OraclyAdaptiveScrollView), findsOneWidget);
      expect(find.byType(StarMapResultFooter), findsOneWidget);
    });
  }

  testWidgets('a11y textScale 1.3 — meaning remains', (tester) async {
    final storage = await yildiznameVisualOpenStorage();
    await yildiznameVisualPumpSettled(
      tester,
      viewport: yildiznameVisualTextScaleViewport,
      textScale: yildiznameVisualTextScale,
      storage: storage,
      child: StarMapReferenceResultScreen(
        title: 'Yıldızname',
        sections: yildiznameVisualNarrativeReducedSections(),
      ),
    );
    expect(find.text('summary'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('summary section precedes reflection/closing in tree',
      (tester) async {
    await yildiznameGoldenPumpResult(
      tester,
      title: 'Yıldızname',
      sections: yildiznameVisualNarrativeReducedSections(),
    );
    final summary = tester.getTopLeft(find.text('summary'));
    final reflection = tester.getTopLeft(find.text('reflection'));
    final closing = tester.getTopLeft(find.text('closing'));
    expect(summary.dy < reflection.dy, isTrue);
    expect(reflection.dy < closing.dy, isTrue);
  });
}
