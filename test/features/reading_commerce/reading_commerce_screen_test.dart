import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/reading_commerce/copy/reading_commerce_copy.dart';
import 'package:oracly_new/features/reading_commerce/models/reading_commerce_view.dart';
import 'package:oracly_new/features/reading_commerce/presentation/reading_commerce_body.dart';

void main() {
  test('a closed catalog offers no price and no buy', () {
    final view = ReadingCommerceView.decide(
      commerceOpen: false,
      purchasable: true,
      platformAdmitted: true,
      storePrices: const {'app.oracly.reading.coffee': '₺69,99'},
      coffeeCredits: 0,
      palmCredits: 0,
    );
    expect(view.showCoffee, isFalse);
    expect(view.showPalm, isFalse);
    expect(view.showPack, isFalse);
  });

  test('an admitted catalog still hides a product the store did not return', () {
    final view = ReadingCommerceView.decide(
      commerceOpen: true,
      purchasable: true,
      platformAdmitted: true,
      storePrices: const {'app.oracly.reading.palm': '₺49,99'},
      coffeeCredits: 1,
      palmCredits: 0,
    );
    expect(view.showPalm, isTrue);
    expect(view.showCoffee, isFalse);
    expect(view.coffeeCredits, 1);
  });

  testWidgets('the buy button is absent until a store price exists', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: ReadingCommerceBody(view: ReadingCommerceView(coffeeCredits: 0, palmCredits: 0)),
    ));
    expect(find.text(ReadingCommerceCopy.buy), findsNothing);
    expect(find.text(ReadingCommerceCopy.closed), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      home: ReadingCommerceBody(
        view: ReadingCommerceView.decide(
          commerceOpen: true,
          purchasable: true,
          platformAdmitted: true,
          storePrices: const {'app.oracly.reading.coffee': '₺69,99'},
          coffeeCredits: 2,
          palmCredits: 0,
        ),
        onBuy: (_) {},
      ),
    ));
    expect(find.text('₺69,99'), findsOneWidget);
    expect(find.text(ReadingCommerceCopy.buy), findsOneWidget);
    expect(find.textContaining('Kahve hakkı: 2'), findsOneWidget);
  });
}
