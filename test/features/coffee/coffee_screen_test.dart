/// Coffee landing + history wiring.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_reference_screen.dart';
import 'package:oracly_new/features/coffee/providers/coffee_providers.dart';
import 'package:oracly_new/features/coffee/services/unavailable_coffee_analysis.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('landing opens with hero lead and photo pickers', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();

    await tester.pumpWidget(_coffeeApp(storage));
    await tester.pump();

    expect(find.text(CoffeeCopy.screenTitle), findsWidgets);
    expect(find.text(CoffeeCopy.hubLead), findsOneWidget);
    expect(find.text(CoffeeCopy.photoCta), findsOneWidget);
    expect(find.text(CoffeeCopy.capabilityNote), findsOneWidget);
    expect(find.text(CoffeeCopy.galleryLabel), findsOneWidget);
    expect(find.text(CoffeeCopy.ritualTease), findsNothing);
    expect(find.text(CoffeeCopy.historyLink), findsNothing);
  });

  testWidgets('history reopens the saved coffee result', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await CoffeeReadingStore(storage).save(
      CoffeeReading(
        id: 'saved-1',
        createdAt: DateTime(2026, 8, 8),
        overall: 'Kayıtlı fincan yorumu burada.',
        love: 'Aşkta sakinlik.',
        career: 'İşde netlik.',
        money: 'Denge.',
        nearFuture: 'Yavaşla.',
        takeaway: 'Nefes.',
      ),
    );

    await tester.pumpWidget(_coffeeApp(storage));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text(CoffeeCopy.historyLink));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(CoffeeCopy.historyTitle), findsOneWidget);
    expect(find.textContaining('Kayıtlı fincan yorumu'), findsOneWidget);

    await tester.tap(find.textContaining('Kayıtlı fincan yorumu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Kayıtlı fincan yorumu'), findsAtLeastNWidgets(1));
    expect(find.text(CoffeeCopy.overallTitle), findsAtLeastNWidgets(1));
  });
}

Widget _coffeeApp(LocalStorage storage) {
  return ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(storage),
      coffeeAnalysisProvider.overrideWithValue(const UnavailableCoffeeAnalysis()),
    ],
    child: const MaterialApp(home: CoffeeReferenceScreen()),
  );
}
