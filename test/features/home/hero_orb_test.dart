import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/home/widgets/hero_orb_v3/hero_orb.dart';

void main() {
  testWidgets('HeroOrb builds living crystal scene without layout errors',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: HeroOrb(size: 120),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(HeroOrb), findsOneWidget);

    await tester.tap(find.byType(HeroOrb));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });
}
