/// Phase 7F — app-bar gem hit target under large balance + high text scale.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/design_system/oracly_app_bar.dart';
import 'package:oracly_new/core/design_system/oracly_crystal_capsule.dart';
import 'package:oracly_new/core/accessibility/oracly_a11y.dart';

import '../../../visual/yildizname/yildizname_visual_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  testWidgets('large gem balance keeps ≥44 hit at 320×568 @ textScale 2.0',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 568),
          textScaler: TextScaler.linear(2.0),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: OraclyAppBar(
              title: 'Yıldızname',
              gemCount: '999,999',
              onPremiumTap: () {},
              onLeadingTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final capsule = find.byType(OraclyCrystalCapsule);
    expect(capsule, findsOneWidget);
    final size = tester.getSize(capsule);
    expect(size.height, greaterThanOrEqualTo(OraclyA11y.minTouchTarget));
    expect(size.width, greaterThanOrEqualTo(OraclyA11y.minTouchTarget));
  });
}
