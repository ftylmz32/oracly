/// P3A — compact table chrome, semantics, and keyboard reach.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_custom_intent.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_hint.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_intent_catalogue.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_intent_chip.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_spread_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('tr'));

  testWidgets('table title and spread tiles at 320', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const TarotTableTitle(),
              TarotTableSpreadOverlay(selected: null, onSelected: (_) {}),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Tarot'), findsOneWidget);
    expect(find.text('Tek Kart'), findsOneWidget);
    expect(find.text('3 Kart'), findsOneWidget);
    expect(find.text('Derin Açılım'), findsOneWidget);
    expect(find.text('Yedi Kart'), findsNothing);
    expect(find.text('Kelt Haçı'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('intention chip is one button', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TarotTableIntentChip(
            option: TableIntentCatalogue.options.first,
            selected: true,
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Aşk'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('custom intention confirm stays reachable above the keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showTarotCustomIntentDialog(context),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Tamam'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
