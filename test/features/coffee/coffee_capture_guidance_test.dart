/// Coffee capture guidance — presentation only, all viewports.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/controllers/coffee_reading_controller.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_capture_cup_guide.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_capture_view.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_reference_screen.dart';
import 'package:oracly_new/features/coffee/providers/coffee_providers.dart';
import 'package:oracly_new/features/coffee/services/unavailable_coffee_analysis.dart';
import 'package:oracly_new/shared/widgets/oracly_bottom_bar.dart';
import 'package:oracly_new/shared/widgets/oracly_gold_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const viewports = <Size>[
    Size(320, 568),
    Size(360, 640),
    Size(360, 800),
    Size(390, 844),
    Size(412, 915),
    Size(430, 932),
  ];

  Future<void> openCapture(WidgetTester tester, LocalStorage storage) async {
    await tester.pumpWidget(_app(storage));
    await tester.pump();
    ProviderScope.containerOf(tester.element(find.byType(CoffeeReferenceScreen)))
        .read(coffeeReadingControllerProvider)
        .startCapture();
    await tester.pump();
  }

  for (final size in viewports) {
    testWidgets('capture guidance fits ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      await openCapture(tester, storage);

      expect(tester.takeException(), isNull);
      expect(find.byType(CoffeeCaptureView), findsOneWidget);
      expect(find.byType(CoffeeCaptureCupGuide), findsOneWidget);
      expect(find.text(CoffeeCopy.captureHeading), findsOneWidget);
      expect(find.text(CoffeeCopy.captureGuide), findsOneWidget);
      expect(find.text(CoffeeCopy.captureTips), findsOneWidget);
      expect(find.text(CoffeeCopy.photoCta), findsOneWidget);
      expect(find.text(CoffeeCopy.galleryLabel), findsOneWidget);
      expect(find.text(CoffeeCopy.landingTitle), findsNothing);
      expect(find.textContaining(CoffeeCopy.hubLead), findsNothing);
      expect(find.byType(OraclyBottomBar), findsNothing);

      expect(find.byType(SingleChildScrollView), findsWidgets);
      await tester.ensureVisible(
        find.widgetWithText(OraclyGoldButton, CoffeeCopy.photoCta),
      );
      await tester.pump();
      final cta = tester.getRect(
        find.widgetWithText(OraclyGoldButton, CoffeeCopy.photoCta),
      );
      expect(cta.height, greaterThan(40));
    });
  }
}

Widget _app(LocalStorage storage) {
  return ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(storage),
      coffeeAnalysisProvider.overrideWithValue(const UnavailableCoffeeAnalysis()),
    ],
    child: const MaterialApp(home: CoffeeReferenceScreen()),
  );
}