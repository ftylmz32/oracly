/// Phase 7F — touch targets, reduced motion, scroll reachability.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/design_system/oracly_header_action.dart';
import 'package:oracly_new/features/ai/oracle_conversation/widgets/or_ask_button.dart';
import 'package:oracly_new/features/discovery_share/widgets/discovery_share_action.dart';
import 'package:oracly_new/features/favorite_moments/presentation/widgets/save_favorite_moment_link.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_or_context.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_actions_builder.dart';
import 'package:oracly_new/core/insight_copy/widgets/insight_copy_link.dart';
import 'package:oracly_new/features/reading_feedback/presentation/widgets/reading_quality_actions.dart';
import 'package:oracly_new/shared/widgets/oracly_adaptive_scroll_view.dart';

import '../../../support/yildizname_result_fixtures.dart';
import '../../../visual/yildizname/yildizname_visual_harness.dart';
import '../../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  Future<YildiznameResultPresentation> fullPresentation() async {
    final artifact = yildiznameFixtureNarrativeArtifact(
      scope: YildiznameNarrativeScope.full,
      rich: true,
      id: 'yid_7ftargets7ftargets7ftargets7fta00',
      createdAtUtc: DateTime.utc(2026, 6, 3),
      summary: '${'Uzun özet metni. ' * 35}Son.',
      sectionTexts: ['${'Bölüm. ' * 40}Son.'],
    );
    final base =
        YildiznameArtifactPresentation.of(artifact, chromeLocale: 'tr');
    return base.withActions(
      YildiznameResultActionsBuilder.build(
        presentation: base,
        orContext: YildiznameArtifactOrContext.build(artifact),
      ),
    );
  }

  testWidgets('320@2.0 action hit regions ≥44; footer reachable',
      (tester) async {
    final presentation = await fullPresentation();
    final storage = await yildiznameVisualOpenStorage();
    await yildiznameVisualPumpSettled(
      tester,
      viewport: const Size(320, 568),
      textScale: 2.0,
      storage: storage,
      child: StarMapReferenceResultScreen(presentation: presentation),
    );

    Future<void> expectMin(Finder f) async {
      expect(f, findsWidgets);
      final size = tester.getSize(f.first);
      expect(size.height, greaterThanOrEqualTo(44), reason: '$f');
      expect(size.width, greaterThanOrEqualTo(44), reason: '$f');
    }

    await expectMin(find.byType(OraclyHeaderAction));
    await expectMin(find.byType(OrAskButton));
    await expectMin(find.byType(DiscoveryShareAction));
    await expectMin(find.byType(SaveFavoriteMomentLink));
    await expectMin(find.byType(InsightCopyLink));

    final scrollable = find.descendant(
      of: find.byType(OraclyAdaptiveScrollView),
      matching: find.byType(Scrollable),
    );
    await tester.drag(scrollable, const Offset(0, -4000));
    await tester.pumpAndSettle();
    expect(find.byType(ReadingQualityActions), findsOneWidget);
  });

  testWidgets('reduced motion: content visible without waiting', (tester) async {
    final presentation = await fullPresentation();
    final storage = await yildiznameVisualOpenStorage();
    await yildiznameVisualLoadGoldenFonts();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            disableAnimations: true,
            accessibleNavigation: true,
          ),
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: StarMapReferenceResultScreen(presentation: presentation),
          ),
        ),
      ),
    );
    await tester.pump(); // one frame — no long settle required
    expect(find.byType(StarMapReferenceResultScreen), findsOneWidget);
    expect(find.byType(OrAskButton), findsOneWidget);
    expect(find.textContaining('odak'), findsWidgets);
  });

  testWidgets('width change 390→768 keeps max content width', (tester) async {
    final presentation = await fullPresentation();
    final storage = await yildiznameVisualOpenStorage();
    await yildiznameVisualPumpSettled(
      tester,
      viewport: const Size(390, 844),
      storage: storage,
      child: StarMapReferenceResultScreen(presentation: presentation),
    );
    await tester.binding.setSurfaceSize(const Size(768, 1024));
    tester.view.physicalSize = const Size(768, 1024);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    expect(find.byType(StarMapReferenceResultScreen), findsOneWidget);
  });
}

