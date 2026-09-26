/// Phase 7F.1 — max width, reflow, reduced motion (Tasks 14–16).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/design_system/app_layout.dart';
import 'package:oracly_new/core/design_system/chamber_story_panel.dart';
import 'package:oracly_new/features/ai/oracle_conversation/widgets/or_ask_button.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_fact_snapshot_plate.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_result_closing.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_result_footer.dart';
import 'package:oracly_new/shared/widgets/oracly_adaptive_scroll_view.dart';

import '../../../test_helpers/provider_scope_harness.dart';
import '../../../visual/yildizname/yildizname_visual_harness.dart';
import 'phase7f1_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  testWidgets('T14 768 content column ≤ maxContentWidth', (tester) async {
    final presentation = await phase7f1FullPresentation();
    await phase7f1Pump(
      tester,
      presentation: presentation,
      viewport: const Size(768, 1024),
    );
    final size = phase7f1ContentColumnSize(tester);
    expect(size.width, lessThanOrEqualTo(AppLayout.maxContentWidth + 0.5));
    expect(size.width, closeTo(AppLayout.maxContentWidth, 0.5));
  });

  testWidgets('T15 390→768 reflow respects max 560; scroll works',
      (tester) async {
    final errors = <Object>[];
    final old = FlutterError.onError;
    FlutterError.onError = (d) {
      final t = d.exceptionAsString();
      if (t.contains('overflowed') || t.contains('RenderFlex')) {
        errors.add(d.exception);
      }
      old?.call(d);
    };
    addTearDown(() => FlutterError.onError = old);

    final presentation = await phase7f1FullPresentation();
    await phase7f1Pump(
      tester,
      presentation: presentation,
      viewport: const Size(390, 844),
    );
    final before = phase7f1ContentColumnSize(tester);
    final factBefore = tester.getSize(find.byType(StarMapFactSnapshotPlate));

    await tester.binding.setSurfaceSize(const Size(768, 1024));
    tester.view.physicalSize = const Size(768, 1024);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    final after = phase7f1ContentColumnSize(tester);
    expect(after.width, isNot(equals(before.width)));
    expect(after.width, lessThanOrEqualTo(AppLayout.maxContentWidth + 0.5));
    final factAfter = tester.getSize(find.byType(StarMapFactSnapshotPlate));
    expect(factAfter.width, isNot(equals(factBefore.width)));
    expect(errors, isEmpty, reason: '$errors');

    final scrollable = find.descendant(
      of: find.byType(OraclyAdaptiveScrollView),
      matching: find.byType(Scrollable),
    );
    await tester.drag(scrollable, const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(find.byType(StarMapResultFooter), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('T16 reduced motion: late content visible on first settle',
      (tester) async {
    final presentation = await phase7f1FullPresentation();
    final storage = await yildiznameVisualOpenStorage();
    await yildiznameVisualLoadGoldenFonts();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [phase7f1DiscoveryOverride()],
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
    await tester.pump(); // first settled frame — SoftReveal jumps to 1.0

    final summary = presentation.sections
        .firstWhere((s) => s.role == YildiznameSectionRole.summary);
    final chapter = presentation.sections
        .firstWhere((s) => s.role == YildiznameSectionRole.chapter);
    expect(find.textContaining(summary.title.trim()), findsWidgets);
    expect(find.textContaining(chapter.title.trim()), findsWidgets);
    expect(find.byType(ChamberStoryPanel), findsOneWidget);
    expect(find.byType(StarMapResultClosing), findsOneWidget);
    expect(find.byType(OrAskButton), findsOneWidget);
    expect(find.byType(StarMapResultFooter), findsOneWidget);
  });
}
