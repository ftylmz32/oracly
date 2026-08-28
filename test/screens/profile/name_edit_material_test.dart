/// Name-edit dialog — TextField must have a Material ancestor.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/shared/ui/oracly_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('name prompt TextField has Material and can type/save', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    String? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  saved = await OraclyDialog.prompt(
                    context,
                    title: 'İsim',
                    hint: 'Adın',
                    initial: 'Yolcu',
                    confirmLabel: 'Kaydet',
                  );
                },
                child: const Text('edit-name'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('edit-name'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(TextField),
        matching: find.byType(Material),
      ),
      findsWidgets,
    );

    await tester.enterText(find.byType(TextField), 'Fatih');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(saved, 'Fatih');
    expect(find.byType(TextField), findsNothing);
  });
}
