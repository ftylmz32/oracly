/// P1 — Accessibility / responsive release pass (TECNO KN8 class).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/accessibility/oracly_a11y.dart';
import 'package:oracly_new/core/design_system/app_layout.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/shared/ui/oracly_dialog.dart';
import 'package:oracly_new/shared/ui/oracly_dialog_actions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('confirm dialog actions wrap at 360 without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    OraclyL10n.bind('tr');

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 800),
          textScaler: TextScaler.linear(1.3),
        ),
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () {
                    OraclyDialog.confirm(
                      context,
                      title: OraclyL10n.t('settings.notifications'),
                      message: OraclyL10n.t('notif.permission'),
                      confirmLabel: OraclyL10n.t('notif.permission_yes'),
                      cancelLabel: OraclyL10n.t('notif.permission_later'),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(OraclyDialogActions), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.text(OraclyL10n.t('notif.permission_yes')), findsOneWidget);
    expect(find.text(OraclyL10n.t('notif.permission_later')), findsOneWidget);
  });

  testWidgets('scrollBottomInset keeps floating nav clearance with keyboard', (
    tester,
  ) async {
    late double inset;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 800),
          viewInsets: EdgeInsets.only(bottom: 280),
          padding: EdgeInsets.only(bottom: 0),
        ),
        child: Builder(
          builder: (context) {
            inset = AppLayout.scrollBottomInset(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(
      inset,
      AppLayout.navBarHeight +
          AppLayout.navBarMarginBottom +
          AppLayout.contentBottomBreath,
    );
    expect(inset, greaterThan(AppLayout.contentBottomBreath));
  });

  test('touch floor stays at least 44', () {
    expect(OraclyA11y.minTouchTarget, greaterThanOrEqualTo(44));
  });
}
