import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/star_map/copy/star_map_polish_copy.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_chart.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  const viewports = <Size>[
    Size(360, 800),
    Size(375, 812),
    Size(390, 844),
    Size(411, 901),
    Size(430, 932),
    Size(600, 960),
  ];

  group('Yıldızname reference — no overflow', () {
    for (final size in viewports) {
      testWidgets('full page at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        SharedPreferences.setMockInitialValues({});
        final storage = await LocalStorage.open();

        await tester.pumpWidget(
          buildProviderScopeHarness(
            storage: storage,
            child: const MaterialApp(home: StarMapReferenceScreen()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull);
        expect(find.text('YILDIZNAME'), findsOneWidget);
        expect(find.text(StarMapPolishCopy.whatItIs), findsOneWidget);
        expect(find.text(StarMapPolishCopy.enterBirthInfo), findsOneWidget);
        expect(find.text(StarMapPolishCopy.leadLine), findsOneWidget);
        expect(find.text(StarMapPolishCopy.toldToday), findsOneWidget);
        expect(find.text(StarMapPolishCopy.todayReflectionTitle), findsOneWidget);
        // First archive entry: honest empty chapter — not invented theme depth.
        expect(find.text(StarMapPolishCopy.journeyTitle), findsOneWidget);
        expect(find.text(StarMapPolishCopy.journeyEmpty), findsOneWidget);
        expect(find.text(StarMapPolishCopy.leftQuestionTitle), findsOneWidget);
        expect(find.text(StarMapPolishCopy.karmicResultTitle), findsNothing);
        expect(find.text(StarMapPolishCopy.karmicAsk), findsNothing);
        expect(find.text('KARMİK ANALİZ'), findsNothing);
        expect(find.byType(StarMapReferenceChart), findsOneWidget);
      });
    }
  });

  testWidgets('inner themes result is not titled KARMİK ANALİZ', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();

    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: const MaterialApp(home: StarMapReferenceScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(StarMapPolishCopy.toldToday), findsOneWidget);
    expect(find.text(StarMapPolishCopy.todayReflectionTitle), findsOneWidget);
    expect(find.text(StarMapPolishCopy.journeyTitle), findsOneWidget);
    expect(find.text(StarMapPolishCopy.journeyEmpty), findsOneWidget);
    expect(find.text(StarMapPolishCopy.leftQuestionTitle), findsOneWidget);
    expect(find.text(StarMapPolishCopy.karmicResultTitle), findsNothing);
    expect(find.text(StarMapPolishCopy.karmicAsk), findsNothing);
    expect(find.text('KARMİK ANALİZ'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
