/// Password confirm dialog — empty submit disabled, cancel returns null.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/privacy/copy/privacy_control_copy.dart';
import 'package:oracly_new/shared/ui/oracly_password_confirm_dialog.dart';
import 'package:oracly_new/shared/widgets/oracly_gold_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('empty password keeps submit disabled; cancel returns null',
      (tester) async {
    String? result = 'unset';
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                result = await OraclyPasswordConfirmDialog.show(
                  context,
                  title: PrivacyControlCopy.reauthPasswordTitle,
                  message: PrivacyControlCopy.reauthPasswordBody,
                  email: 'user@example.com',
                  confirmLabel: PrivacyControlCopy.reauthPasswordAction,
                  cancelLabel: PrivacyControlCopy.reauthCancel,
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('user@example.com'), findsOneWidget);
    final submit = tester.widget<OraclyGoldButton>(
      find.widgetWithText(
        OraclyGoldButton,
        PrivacyControlCopy.reauthPasswordAction,
      ),
    );
    expect(submit.onPressed, isNull);

    await tester.tap(find.text(PrivacyControlCopy.reauthCancel));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('non-empty password submits the typed value', (tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                result = await OraclyPasswordConfirmDialog.show(
                  context,
                  title: PrivacyControlCopy.reauthPasswordTitle,
                  message: PrivacyControlCopy.reauthPasswordBody,
                  email: 'user@example.com',
                  confirmLabel: PrivacyControlCopy.reauthPasswordAction,
                  cancelLabel: PrivacyControlCopy.reauthCancel,
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'secret-pass');
    await tester.pump();

    await tester.tap(
      find.widgetWithText(
        OraclyGoldButton,
        PrivacyControlCopy.reauthPasswordAction,
      ),
    );
    await tester.pumpAndSettle();
    expect(result, 'secret-pass');
  });
}
