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

  test(
    'an admitted catalog still hides a product the store did not return',
    () {
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
    },
  );

  testWidgets('the buy button is absent until a store price exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ReadingCommerceBody(
          view: ReadingCommerceView(coffeeCredits: 0, palmCredits: 0),
        ),
      ),
    );
    expect(find.text(ReadingCommerceCopy.buy), findsNothing);
    expect(find.text(ReadingCommerceCopy.closed), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
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
      ),
    );
    expect(find.text('₺69,99'), findsOneWidget);
    expect(find.text(ReadingCommerceCopy.buy), findsOneWidget);
    expect(find.textContaining('Kahve hakkı: 2'), findsOneWidget);
    expect(find.textContaining('QA satın alma'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: ReadingCommerceBody(
          view: ReadingCommerceView.decide(
            commerceOpen: true,
            purchasable: true,
            platformAdmitted: true,
            storePrices: const {'app.oracly.reading.coffee': '₺69,99'},
            coffeeCredits: 0,
            palmCredits: 0,
            billingQa: true,
          ),
          onBuy: (_) {},
        ),
      ),
    );
    expect(find.textContaining('QA satın alma testidir'), findsOneWidget);
    expect(find.text(ReadingCommerceCopy.buy), findsOneWidget);
  });

  testWidgets('coffee entry shows owned credit and continues without buying', (
    tester,
  ) async {
    var continued = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ReadingCommerceBody(
          view: const ReadingCommerceView(coffeeCredits: 1, palmCredits: 0),
          focus: ReadingCommerceFocus.coffee,
          onContinue: () => continued = true,
        ),
      ),
    );

    expect(find.text(ReadingCommerceCopy.useCoffeeCredit), findsOneWidget);
    expect(find.text(ReadingCommerceCopy.buy), findsNothing);
    await tester.tap(find.text(ReadingCommerceCopy.useCoffeeCredit));
    expect(continued, isTrue);
  });

  testWidgets('coffee entry offers one and three pack only at store prices', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReadingCommerceBody(
          view: const ReadingCommerceView(
            coffeeCredits: 0,
            palmCredits: 0,
            coffeePrice: r'$1.99',
            palmPrice: r'$2.99',
            packPrice: r'$4.99',
          ),
          focus: ReadingCommerceFocus.coffee,
          onBuy: (_) {},
        ),
      ),
    );

    expect(find.text(r'$1.99'), findsOneWidget);
    expect(find.text(r'$4.99'), findsOneWidget);
    expect(find.text(r'$2.99'), findsNothing);
    expect(find.text(ReadingCommerceCopy.buy), findsNWidgets(2));
  });

  testWidgets('blocked palm fulfillment never opens capture or purchase', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReadingCommerceBody(
          view: const ReadingCommerceView(
            coffeeCredits: 0,
            palmCredits: 1,
            palmPrice: r'$2.99',
          ),
          focus: ReadingCommerceFocus.palm,
          fulfillmentAvailable: false,
          onContinue: () => fail('must stay blocked'),
          onBuy: (_) => fail('must not sell an unavailable fulfillment'),
        ),
      ),
    );

    expect(find.textContaining('1'), findsWidgets);
    expect(find.text(ReadingCommerceCopy.palmUnavailable), findsOneWidget);
    expect(find.text(ReadingCommerceCopy.buy), findsNothing);
    expect(find.text(ReadingCommerceCopy.usePalmCredit), findsNothing);
  });

  testWidgets(
    'owned palm credit can continue once server fulfillment is enabled',
    (tester) async {
      var continued = false;
      await tester.pumpWidget(
        MaterialApp(
          home: ReadingCommerceBody(
            view: const ReadingCommerceView(coffeeCredits: 0, palmCredits: 1),
            focus: ReadingCommerceFocus.palm,
            fulfillmentAvailable: true,
            onContinue: () => continued = true,
          ),
        ),
      );

      expect(find.text(ReadingCommerceCopy.usePalmCredit), findsOneWidget);
      expect(find.text(ReadingCommerceCopy.palmUnavailable), findsNothing);
      await tester.tap(find.text(ReadingCommerceCopy.usePalmCredit));
      expect(continued, isTrue);
    },
  );
}
