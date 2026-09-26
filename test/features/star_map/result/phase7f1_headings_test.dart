/// Phase 7F.1 — heading semantics + no duplicate speech (Tasks 12–13).
library;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/design_system/chamber_story_panel.dart';
import 'package:oracly_new/core/reading_ux/reading_expand_section.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_continuity_echo.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_fact_snapshot_plate.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_result_closing.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_scope_note.dart';

import '../../../visual/yildizname/yildizname_visual_harness.dart';
import 'phase7f1_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  int headerHits(List<SemanticsNode> headers, String label) =>
      headers.where((n) => n.label == label).length;

  testWidgets('T12–T13 major headings header==true; no duplicate speech',
      (tester) async {
    final handle = tester.ensureSemantics();
    final presentation = await phase7f1FullPresentation();
    await phase7f1Pump(tester, presentation: presentation);
    await tester.pumpAndSettle();

    expect(find.byType(StarMapScopeNote), findsOneWidget);
    expect(find.byType(StarMapFactSnapshotPlate), findsOneWidget);
    expect(find.byType(StarMapContinuityEcho), findsOneWidget);
    expect(find.byType(ChamberStoryPanel), findsOneWidget);
    expect(find.byType(StarMapResultClosing), findsOneWidget);

    final root = tester.getSemantics(find.byType(StarMapReferenceResultScreen));
    final headers = phase7f1Traverse(root)
        .where((n) => n.flagsCollection.isHeader)
        .toList();
    expect(headers.length, greaterThanOrEqualTo(6));

    expect(
      headers.any(
        (n) => n.label.toUpperCase() == presentation.title.toUpperCase(),
      ),
      isTrue,
      reason: 'app bar heading',
    );
    expect(
      headers
          .where(
            (n) => n.label.toUpperCase() == presentation.title.toUpperCase(),
          )
          .length,
      1,
    );
    expect(headerHits(headers, presentation.scopeDisclosure!.kicker), 1);
    expect(headerHits(headers, presentation.factSnapshot.title), 1);
    expect(headerHits(headers, presentation.continuity.heading), 1);

    for (final s in presentation.sections) {
      final title = s.title.trim();
      if (title.isEmpty) continue;
      if (s.role == YildiznameSectionRole.summary ||
          s.role == YildiznameSectionRole.chapter ||
          s.role == YildiznameSectionRole.reflection ||
          s.role == YildiznameSectionRole.closing) {
        expect(headerHits(headers, title), 1, reason: '${s.role} "$title"');
      }
    }

    expect(find.byType(ReadingExpandSection), findsWidgets);
    handle.dispose();
  });
}
