/// Phase 7F.1 — real footer semantic order + availability (Tasks 7–11).
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/continuation/models/session_continuation.dart';
import 'package:oracly_new/core/continuation/services/session_continuation_engine.dart';
import 'package:oracly_new/core/copy/conversation_copy.dart';
import 'package:oracly_new/core/insight_copy/insight_copy_strings.dart';
import 'package:oracly_new/features/discovery_share/copy/discovery_share_copy.dart';
import 'package:oracly_new/features/favorite_moments/copy/favorite_moments_copy.dart';
import 'package:oracly_new/features/reading_feedback/copy/reading_feedback_copy.dart';
import 'package:oracly_new/features/star_map/copy/star_map_polish_copy.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_actions.dart';
import 'package:oracly_new/shared/widgets/oracly_adaptive_scroll_view.dart';

import '../../../visual/yildizname/yildizname_visual_harness.dart';
import 'phase7f1_harness.dart';

String _contLine(YildiznameResultActions actions) {
  final item = SessionContinuationEngine.decide(
    from: SessionContinuationSource.starMap,
    profile: phase7f1CrossModalProfile(),
    sessionThemes: actions.continuationThemes,
    orAlreadyOffered: actions.hasOr,
  );
  expect(item, isNotNull);
  return item!.line;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  Future<void> scrollFooter(WidgetTester tester) async {
    final scrollable = find.descendant(
      of: find.byType(OraclyAdaptiveScrollView),
      matching: find.byType(Scrollable),
    );
    await tester.drag(scrollable, const Offset(0, -6000));
    await tester.pumpAndSettle();
  }

  List<String> footerLabels(SemanticsNode root, List<String> wanted) {
    final buttons = phase7f1ActionButtons(root);
    return [
      for (final n in buttons)
        if (wanted.contains(n.label)) n.label,
    ];
  }

  testWidgets('T7–T8 real semantic action order + one node each',
      (tester) async {
    final handle = tester.ensureSemantics();
    final presentation = await phase7f1FullPresentation();
    await phase7f1Pump(
      tester,
      presentation: presentation,
      overrides: [phase7f1DiscoveryOverride()],
    );
    await scrollFooter(tester);

    final contLine = _contLine(presentation.actions);
    final wanted = [
      ConversationCopy.askOr,
      DiscoveryShareCopy.share,
      FavoriteMomentsCopy.save,
      InsightCopyStrings.action,
      contLine,
      ReadingFeedbackCopy.positive,
      ReadingFeedbackCopy.action,
    ];

    final root = tester.getSemantics(find.byType(StarMapReferenceResultScreen));
    final ordered = footerLabels(root, wanted);
    expect(ordered, wanted, reason: 'semantic DFS order of footer actions');

    for (final label in wanted) {
      expect(phase7f1ButtonCount(root, label), 1, reason: label);
    }

    // Fact toggle is content, not footer — must appear before OR in DFS.
    final more = presentation.factSnapshot.moreLabel;
    final all = [
      for (final n in phase7f1ActionButtons(root)) n.label,
    ];
    final factIdx = all.indexOf(more);
    final orIdx = all.indexOf(ConversationCopy.askOr);
    expect(factIdx, greaterThanOrEqualTo(0));
    expect(orIdx, greaterThan(factIdx));
    handle.dispose();
  });

  testWidgets('T9 no-OR matrix: Share→Favorite→Copy→Continue→feedback',
      (tester) async {
    final handle = tester.ensureSemantics();
    final presentation = await phase7f1FullPresentation(withOr: false);
    await phase7f1Pump(
      tester,
      presentation: presentation,
      overrides: [phase7f1DiscoveryOverride()],
    );
    await scrollFooter(tester);

    final contLine = _contLine(presentation.actions);
    final wanted = [
      DiscoveryShareCopy.share,
      FavoriteMomentsCopy.save,
      InsightCopyStrings.action,
      contLine,
      ReadingFeedbackCopy.positive,
      ReadingFeedbackCopy.action,
    ];
    final root = tester.getSemantics(find.byType(StarMapReferenceResultScreen));
    expect(footerLabels(root, [...wanted, ConversationCopy.askOr]), wanted);
    expect(phase7f1ButtonCount(root, ConversationCopy.askOr), 0);
    expect(find.text(StarMapPolishCopy.orHint), findsNothing);
    handle.dispose();
  });

  testWidgets('T10 no-Favorite: OR→Share→Copy→Continue→feedback',
      (tester) async {
    final handle = tester.ensureSemantics();
    final presentation = await phase7f1FullPresentation(withFavorite: false);
    await phase7f1Pump(
      tester,
      presentation: presentation,
      overrides: [phase7f1DiscoveryOverride()],
    );
    await scrollFooter(tester);

    final contLine = _contLine(presentation.actions);
    final wanted = [
      ConversationCopy.askOr,
      DiscoveryShareCopy.share,
      InsightCopyStrings.action,
      contLine,
      ReadingFeedbackCopy.positive,
      ReadingFeedbackCopy.action,
    ];
    final root = tester.getSemantics(find.byType(StarMapReferenceResultScreen));
    expect(
      footerLabels(root, [...wanted, FavoriteMomentsCopy.save]),
      wanted,
    );
    expect(phase7f1ButtonCount(root, FavoriteMomentsCopy.save), 0);
    expect(find.text(FavoriteMomentsCopy.sourceUnavailable), findsNothing);
    handle.dispose();
  });
}
