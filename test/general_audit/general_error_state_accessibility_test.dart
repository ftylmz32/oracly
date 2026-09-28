/// G0 — shared error state: Retry ≥44×44, announced once, works everywhere.
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/design_system/loading_cinema/oracly_loading_kind.dart';
import 'package:oracly_new/core/design_system/premium_button.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/presentation/widgets/oracle_send_error_banner.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_error_view.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_error_view.dart';
import 'package:oracly_new/features/palm/copy/palm_copy.dart';
import 'package:oracly_new/features/palm/presentation/palm_error_view.dart';
import 'package:oracly_new/features/premium/copy/soul_mate_copy.dart';
import 'package:oracly_new/shared/widgets/oracly_error_state.dart';

typedef _Build = Widget Function(VoidCallback retry, VoidCallback back);

const _leak = 'OpenAI HTTP 500 Exception: Bearer sk-test stack trace';

final _cases = <String, (String Function(), bool, _Build)>{
  'shared': (() => ResilienceCopy.retryAction, false, (r, _) =>
      OraclyErrorState(message: _leak, onRetry: r)),
  'dream': (() => DreamCopy.retry, true, (r, b) =>
      DreamReferenceErrorView(message: _leak, onRetry: r, onBack: b)),
  'coffee': (() => CoffeeCopy.retry, true, (r, b) =>
      CoffeeErrorView(message: _leak, onRetry: r, onBack: b)),
  'palm': (() => PalmCopy.chooseAnotherPhoto, true, (r, b) =>
      PalmErrorView(message: _leak, onRetry: r, onBack: b)),
  'or': (() => CompanionCopy.retry, false, (r, _) =>
      OracleSendErrorBanner(message: _leak, onRetry: r)),
  'soulMate': (() => SoulMateCopy.retry, false, (r, _) => OraclyErrorState(
        kind: OraclyLoadingKind.soulMate,
        compact: true,
        message: _leak,
        onRetry: r,
        retryLabel: SoulMateCopy.retry,
      )),
};

Future<void> _pump(WidgetTester tester, Widget child, {double scale = 1}) {
  return tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          textScaler: TextScaler.linear(scale),
        ),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final lang in ['tr', 'en', 'ru']) {
    for (final MapEntry(key: name, value: (label, hasBack, build))
        in _cases.entries) {
      testWidgets('$lang/$name: Retry ≥44, single button node, taps work',
          (tester) async {
        OraclyL10n.bind(lang);
        final handle = tester.ensureSemantics();
        var retries = 0;
        var backs = 0;
        await _pump(tester, build(() => retries++, () => backs++));
        await tester.pump(const Duration(milliseconds: 50));

        final retry = find.byType(PremiumButton);
        final size = tester.getSize(retry);
        expect(size.height, greaterThanOrEqualTo(44), reason: '$size');
        expect(size.width, greaterThanOrEqualTo(44), reason: '$size');
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        final nodes = find.semantics.byLabel(label());
        expect(nodes, findsOne, reason: 'Retry must be announced once');
        final node = nodes.evaluate().single;
        expect(node.label, label());
        expect(node.flagsCollection.isButton, isTrue);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

        await tester.tap(retry);
        expect(retries, 1);
        tester.semantics.tap(nodes);
        expect(retries, 2, reason: 'screen-reader activation must retry');
        if (hasBack) {
          await tester.tap(find.text(OraclyL10n.t(L10nKeys.back)));
          expect(backs, 1);
        }
        for (final text in tester.widgetList<Text>(find.byType(Text))) {
          final s = text.data ?? '';
          for (final bad in ['OpenAI', 'HTTP', 'Exception', 'Bearer', 'sk-']) {
            expect(s.contains(bad), isFalse, reason: '$name leaked "$s"');
          }
        }
        handle.dispose();
      });
    }
  }

  testWidgets('max text scale: no overflow, Retry still ≥44', (tester) async {
    OraclyL10n.bind('ru');
    for (final (_, _, build) in _cases.values) {
      await _pump(tester, build(() {}, () {}), scale: 2);
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(PremiumButton)).height,
        greaterThanOrEqualTo(44),
      );
    }
  });
}
