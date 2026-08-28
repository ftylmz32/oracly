/// Official ORACLY logo renders from asset — never Material sparkle.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/brand/oracly_brand_mark.dart';
import 'package:oracly_new/core/brand/oracly_wordmark.dart';
import 'package:oracly_new/core/constants/app_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('brand mark uses official logo asset, not Material sparkle',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OraclyBrandMark(size: 96, forLauncher: true),
                OraclyWordmark(size: 22),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(OraclyBrandMark), findsOneWidget);
    expect(find.text('ORACLY'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsNothing);
    expect(AppAssets.brandLogo, contains('oracly_logo.png'));
  });
}
