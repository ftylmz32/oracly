/// Coffee landing matches coffee_target composition without mock nav.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_cup_hero.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_error_view.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_loading_view.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_reference_screen.dart';
import 'package:oracly_new/features/coffee/providers/coffee_providers.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_input_port.dart';
import 'package:oracly_new/features/coffee/services/unavailable_coffee_analysis.dart';
import 'package:oracly_new/shared/widgets/oracly_asset_image.dart';
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

  testWidgets('camera CTA reaches capture without mock bottom nav', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(_coffeeApp(storage, images: const _SilentCoffeeImages()));
    await tester.pump();

    expect(find.byType(OraclyBottomBar), findsNothing);
    expect(find.text('Ana Sayfa'), findsNothing);
    expect(find.text('Astroloji'), findsNothing);
    expect(find.text(CoffeeCopy.landingTitle), findsOneWidget);
    expect(find.textContaining(CoffeeCopy.hubLead), findsOneWidget);
    expect(find.text(CoffeeCopy.overallTitle), findsOneWidget);
    expect(find.text(CoffeeCopy.capabilityNote), findsNothing);

    await tester.tap(find.text(CoffeeCopy.photoCta));
    await tester.pump();
    expect(find.text(CoffeeCopy.landingTitle), findsNothing);
    expect(find.text(CoffeeCopy.photoCta), findsOneWidget);
  });

  testWidgets('gallery CTA reaches preview for analysis', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      _coffeeApp(storage, images: const _FakeCoffeeImages(path: 'cup.jpg')),
    );
    await tester.pump();
    await tester.tap(find.text(CoffeeCopy.galleryLabel));
    await tester.pump();
    expect(find.text(CoffeeCopy.usePhotoLabel), findsOneWidget);
  });

  testWidgets('loading and error states stay visible', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CoffeeLoadingView(message: CoffeeCopy.analyzing),
        ),
      ),
    );
    expect(find.text(CoffeeCopy.analyzing), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CoffeeErrorView(
            message: CoffeeCopy.analysisFailed,
            onRetry: () {},
            onBack: () {},
          ),
        ),
      ),
    );
    expect(find.text(CoffeeCopy.analysisFailed), findsOneWidget);
    expect(find.text(CoffeeCopy.retry), findsOneWidget);
  });

  for (final size in viewports) {
    final label = 'landing fits ${size.width.toInt()}x${size.height.toInt()}';
    testWidgets(label, (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size),
          child: _coffeeApp(storage),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text(CoffeeCopy.photoCta), findsOneWidget);
      expect(find.text(CoffeeCopy.galleryLabel), findsOneWidget);
      expect(find.text(CoffeeCopy.landingTitle), findsOneWidget);
      expect(find.text(CoffeeCopy.overallTitle), findsOneWidget);
      expect(find.textContaining('…'), findsNothing);
      expect(find.textContaining('...'), findsNothing);
      expect(find.byType(SingleChildScrollView), findsWidgets);
      expect(find.byType(OraclyBottomBar), findsNothing);
      final screenW = size.width;
      final photo = tester.getRect(
        find.widgetWithText(OraclyGoldButton, CoffeeCopy.photoCta),
      );
      expect(photo.width, lessThan(screenW * 0.82));
      expect(photo.width, greaterThan(screenW * 0.42));
      final image = tester.getRect(
        find.descendant(
          of: find.byType(CoffeeCupHero),
          matching: find.byType(OraclyAssetImage),
        ),
      );
      final px = CoffeeCupHero.assetPx;
      expect(
        image.width / image.height,
        closeTo(px.width / px.height, 0.02),
      );
      final plate = tester.widgetList<OraclyAssetImage>(
        find.byType(OraclyAssetImage),
      );
      expect(plate.any((w) => w.fit == BoxFit.contain), isTrue);
    });
  }
}

Widget _coffeeApp(LocalStorage storage, {CoffeeImageInputPort? images}) {
  return ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(storage),
      coffeeAnalysisProvider.overrideWithValue(const UnavailableCoffeeAnalysis()),
      if (images != null) coffeeImageInputProvider.overrideWithValue(images),
    ],
    child: const MaterialApp(home: CoffeeReferenceScreen()),
  );
}

class _FakeCoffeeImages implements CoffeeImageInputPort {
  const _FakeCoffeeImages({required this.path});
  final String path;
  @override
  bool get cameraAvailable => true;
  @override
  bool get galleryAvailable => true;
  @override
  Future<CoffeeImagePick?> pickFromCamera() async => CoffeeImagePick(path: path);
  @override
  Future<CoffeeImagePick?> pickFromGallery() async => CoffeeImagePick(path: path);
}

class _SilentCoffeeImages implements CoffeeImageInputPort {
  const _SilentCoffeeImages();
  @override
  bool get cameraAvailable => true;
  @override
  bool get galleryAvailable => true;
  @override
  Future<CoffeeImagePick?> pickFromCamera() async => null;
  @override
  Future<CoffeeImagePick?> pickFromGallery() async => null;
}