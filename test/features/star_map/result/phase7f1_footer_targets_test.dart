/// Phase 7F.1 — footer hit targets + distinct feedback (Tasks 5–6).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/continuation/widgets/session_continuation_link.dart';
import 'package:oracly_new/core/insight_copy/widgets/insight_copy_link.dart';
import 'package:oracly_new/features/ai/oracle_conversation/widgets/or_ask_button.dart';
import 'package:oracly_new/features/discovery_share/widgets/discovery_share_action.dart';
import 'package:oracly_new/features/favorite_moments/presentation/widgets/save_favorite_moment_link.dart';
import 'package:oracly_new/features/reading_feedback/copy/reading_feedback_copy.dart';
import 'package:oracly_new/features/reading_feedback/presentation/widgets/reading_feedback_link.dart';
import 'package:oracly_new/features/reading_feedback/presentation/widgets/reading_positive_link.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';
import 'package:oracly_new/shared/widgets/oracly_adaptive_scroll_view.dart';
import 'package:oracly_new/shared/widgets/oracly_pressable.dart';

import '../../../visual/yildizname/yildizname_visual_harness.dart';
import 'phase7f1_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  Future<void> expectMin(WidgetTester tester, Finder f, String name) async {
    expect(f, findsWidgets, reason: name);
    final size = tester.getSize(f.first);
    expect(size.width, greaterThanOrEqualTo(44), reason: '$name w');
    expect(size.height, greaterThanOrEqualTo(44), reason: '$name h');
  }

  testWidgets('T5–T6 all footer actions ≥44 incl. continuation + feedback',
      (tester) async {
    final handle = tester.ensureSemantics();
    final presentation = await phase7f1FullPresentation();
    await phase7f1Pump(
      tester,
      presentation: presentation,
      viewport: const Size(320, 568),
      textScale: 2.0,
      overrides: [phase7f1DiscoveryOverride()],
    );

    final scrollable = find.descendant(
      of: find.byType(OraclyAdaptiveScrollView),
      matching: find.byType(Scrollable),
    );
    await tester.drag(scrollable, const Offset(0, -6000));
    await tester.pumpAndSettle();

    expect(find.byType(ReadingPositiveLink), findsOneWidget);
    expect(find.byType(ReadingFeedbackLink), findsOneWidget);
    expect(
      ReadingFeedbackCopy.positive,
      isNot(equals(ReadingFeedbackCopy.action)),
    );

    await expectMin(tester, find.byType(OrAskButton), 'OR');
    await expectMin(tester, find.byType(DiscoveryShareAction), 'Share');
    await expectMin(tester, find.byType(SaveFavoriteMomentLink), 'Favorite');
    await expectMin(tester, find.byType(InsightCopyLink), 'Copy');
    await expectMin(tester, find.byType(ReadingPositiveLink), 'Positive');
    await expectMin(tester, find.byType(ReadingFeedbackLink), 'Negative');

    final contPressable = find.descendant(
      of: find.byType(SessionContinuationLink),
      matching: find.byType(OraclyPressable),
    );
    expect(contPressable, findsOneWidget, reason: 'continuation must render');
    await expectMin(tester, contPressable, 'Continuation');

    final root = tester.getSemantics(find.byType(StarMapReferenceResultScreen));
    expect(phase7f1ButtonCount(root, ReadingFeedbackCopy.positive), 1);
    expect(phase7f1ButtonCount(root, ReadingFeedbackCopy.action), 1);
    handle.dispose();
  });
}
