/// Home micro-motion — dispose, reduced motion, entrance contract.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/home/master/home_master_reveal.dart';
import 'package:oracly_new/features/home/reference/home_living_sweep.dart';
import 'package:oracly_new/shared/widgets/oracly_entrance.dart';

void main() {
  testWidgets('HomeLivingSweep disposes without leak', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 120,
            child: HomeLivingSweep(seed: 3),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('reduced motion snaps entrance complete', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Scaffold(
            body: OraclyEntrance(
              delay: const Duration(milliseconds: 400),
              child: const Text('ready'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('ready'), findsOneWidget);
    final opacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(OraclyEntrance),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, equals(1.0));
  });

  testWidgets('HomeMasterReveal wraps child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomeMasterReveal(
            index: 0,
            child: Text('section'),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('section'), findsOneWidget);
  });
}
