/// Regression: `showSettingsChoiceSheet` rendered its title + option rows
/// in a plain `Column(mainAxisSize: min)` with no scroll container. The
/// zodiac "atmosphere" picker has 12 options — on a small viewport with
/// larger text scaling this overflowed the bottom of the sheet by hundreds
/// of pixels (a real RenderFlex overflow, not merely a lint). The sheet must
/// cap its height and let long option lists scroll instead.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/screens/settings/reference/settings_reference_pickers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const viewports = <Size>[
    Size(320, 568),
    Size(360, 800),
    Size(375, 812),
    Size(390, 844),
    Size(412, 915),
  ];

  Future<void> pumpPicker(
    WidgetTester tester,
    Size size, {
    double textScale = 1.0,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SettingsReferencePickers.atmosphere(
                  context,
                  'en',
                  ZodiacSignId.aries,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  for (final size in viewports) {
    testWidgets(
      'zodiac atmosphere picker (12 options) fits '
      '${size.width.toInt()}x${size.height.toInt()} at 1.3x text scale',
      (tester) async {
        await pumpPicker(tester, size, textScale: 1.3);
        expect(tester.takeException(), isNull);
        // Every option must actually be reachable — findsOneWidget would
        // still pass for an off-screen/overflowed widget, so this also
        // exercises scrolling to the last option.
        final lastOption = find.text(ZodiacSignId.pisces.labeled('en'));
        expect(lastOption, findsOneWidget);
        await tester.scrollUntilVisible(
          lastOption,
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'choice sheet content is wrapped in a Scrollable so long lists never '
    'silently overflow',
    (tester) async {
      await pumpPicker(tester, const Size(320, 568), textScale: 1.3);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    },
  );
}
