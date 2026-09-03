/// E3H.1 — fixed UI disclaimer present once; not duplicated by narrative policy.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_result_view.dart';
import 'package:oracly_new/features/palm/copy/palm_copy.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/presentation/palm_result_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  testWidgets('Coffee result shows fixed disclaimer once', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage)],
        child: MaterialApp(
          home: Scaffold(
            body: CoffeeResultView(
              reading: CoffeeReading(
                id: 'e3h1-coffee',
                createdAt: DateTime(2026, 9, 3),
                imagePath: 'tool/e3e_private/fixtures/e3f/coffee_e3f.jpg',
                visualObservation: 'Fincanin agiz kenari ve dibi gorunuyor.',
                overall: 'Yogun birikim ile acik alan yan yana duruyor.',
                love: '',
                career: '',
                money: '',
                nearFuture: '',
                takeaway: 'Dip ile kume yan yana: temposunu fark etmek yeterli.',
              ),
              onNewCup: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final coffeeDisc = find.text(CoffeeCopy.disclaimer);
    await tester.scrollUntilVisible(coffeeDisc, 200);
    await tester.pump();
    expect(coffeeDisc, findsOneWidget);
    expect(CoffeeCopy.disclaimer.toLowerCase(), contains('sembolik'));
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Palm result shows fixed disclaimer once', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage)],
        child: MaterialApp(
          home: Scaffold(
            body: PalmResultView(
              reading: PalmReading(
                id: 'e3h1-palm',
                createdAt: DateTime(2026, 9, 3),
                hand: PalmHand.right,
                imagePath: 'tool/e3e_private/fixtures/e3f/palm_e3f.jpg',
                overall: 'Tek bir avuc ici; kalp ve zihin cizgileri secilebiliyor.',
                heartLine: 'Ustte kivrimli.',
                headLine: 'Ortada duz.',
                lifeLine: 'Basparmak kokunden yay.',
                fateLine: '',
                takeaway: 'Kivrim ve yay yan yana.',
              ),
              onNewPalm: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final palmDisc = find.text(PalmCopy.disclaimer);
    await tester.scrollUntilVisible(palmDisc, 200);
    await tester.pump();
    expect(palmDisc, findsOneWidget);
    expect(PalmCopy.disclaimer.toLowerCase(), contains('sembolik'));
    await tester.binding.setSurfaceSize(null);
  });
}