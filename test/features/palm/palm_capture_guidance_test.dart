/// Palm capture guidance — presentation only, all viewports.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/constants/app_assets.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/palm/copy/palm_copy.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/presentation/palm_capture_palm_guide.dart';
import 'package:oracly_new/features/palm/presentation/palm_capture_view.dart';
import 'package:oracly_new/features/palm/presentation/palm_hero.dart';
import 'package:oracly_new/features/palm/presentation/palm_reference_screen.dart';
import 'package:oracly_new/features/palm/providers/palm_providers.dart';
import 'package:oracly_new/features/palm/services/unavailable_palm_analysis.dart';
import 'package:oracly_new/shared/widgets/oracly_bottom_bar.dart';
import 'package:oracly_new/shared/widgets/oracly_gold_button.dart';
import 'package:oracly_new/shared/widgets/oracly_asset_image.dart';
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
    ProviderScope.containerOf(
      tester.element(find.byType(PalmReferenceScreen)),
    ).read(palmReadingControllerProvider).startCapture();
    await tester.pump();
  }

  for (final size in viewports) {
    testWidgets(
      'palm capture guidance fits ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        SharedPreferences.setMockInitialValues({});
        final storage = await LocalStorage.open();
        await openCapture(tester, storage);

        expect(tester.takeException(), isNull);
        expect(find.byType(PalmCaptureView), findsOneWidget);
        expect(find.byType(PalmCapturePalmGuide), findsOneWidget);
        expect(
          tester
              .widget<OraclyAssetImage>(find.byType(OraclyAssetImage))
              .assetPath,
          AppAssets.homePalm,
        );
        expect(find.text(PalmCopy.captureHeading), findsOneWidget);
        expect(find.text(PalmCopy.captureGuide), findsOneWidget);
        expect(find.text(PalmCopy.captureTips), findsOneWidget);
        expect(find.text(PalmCopy.leftHand), findsOneWidget);
        expect(find.text(PalmCopy.rightHand), findsOneWidget);
        expect(find.text(PalmCopy.landingCameraLabel), findsOneWidget);
        expect(find.text(PalmCopy.galleryLabel), findsOneWidget);
        expect(find.text(PalmCopy.landingLine), findsNothing);
        expect(find.byType(OraclyBottomBar), findsNothing);

        expect(find.byType(SingleChildScrollView), findsWidgets);
        await tester.ensureVisible(
          find.widgetWithText(OraclyGoldButton, PalmCopy.landingCameraLabel),
        );
        await tester.pump();
        final cta = tester.getRect(
          find.widgetWithText(OraclyGoldButton, PalmCopy.landingCameraLabel),
        );
        expect(cta.height, greaterThan(40));
      },
    );
  }

  // home_palm.webp is a RIGHT palm: palm up, fingers up, thumb on the image's
  // right, wrist at the bottom. Right shows it as-is; only left mirrors it.
  testWidgets('selected hand mirrors the photographic guide correctly', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await openCapture(tester, storage);

    await tester.tap(find.text(PalmCopy.leftHand));
    await tester.pump();
    final left = tester.widget<Transform>(
      find.byKey(const ValueKey('palm-capture-guide-left')),
    );
    expect(left.transform.entry(0, 0), -1);
    expect(find.bySemanticsLabel(PalmCopy.leftHand), findsWidgets);
    expect(
      ProviderScope.containerOf(
        tester.element(find.byType(PalmReferenceScreen)),
      ).read(palmReadingControllerProvider).hand,
      PalmHand.left,
    );

    await tester.tap(find.text(PalmCopy.rightHand));
    await tester.pump();
    final right = tester.widget<Transform>(
      find.byKey(const ValueKey('palm-capture-guide-right')),
    );
    expect(right.transform.entry(0, 0), 1);
    expect(find.byKey(const ValueKey('palm-capture-guide-left')), findsNothing);
    expect(
      ProviderScope.containerOf(
        tester.element(find.byType(PalmReferenceScreen)),
      ).read(palmReadingControllerProvider).hand,
      PalmHand.right,
    );
    expect(tester.takeException(), isNull);
  });
  // palm_ritual_hero.webp is a RIGHT palm (wrist at the right edge, thumb
  // toward the top). Landing hero follows the chosen hand.
  for (final size in const <Size>[
    Size(320, 568),
    Size(360, 640),
    Size(390, 844),
    Size(412, 915),
  ]) {
    testWidgets(
      'landing hero follows the chosen hand at ${size.width.toInt()} px',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(_app(await LocalStorage.open()));
        await tester.pump();

        Matrix4 hero(PalmHand hand) => tester
            .widget<Transform>(find.byKey(ValueKey('palm-hero-${hand.name}')))
            .transform;

        expect(
          tester.widget<PalmHero>(find.byType(PalmHero)).hand,
          PalmHand.right,
        );
        expect(hero(PalmHand.right).entry(0, 0), 1);

        await tester.tap(find.text(PalmCopy.leftHand));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(hero(PalmHand.left).entry(0, 0), -1);
        expect(find.byKey(const ValueKey('palm-hero-right')), findsNothing);
        expect(
          find.bySemanticsLabel(RegExp('${PalmCopy.leftHand}\$')),
          findsWidgets,
        );

        await tester.tap(find.text(PalmCopy.rightHand));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(hero(PalmHand.right).entry(0, 0), 1);
        expect(find.byKey(const ValueKey('palm-hero-left')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Widget _app(LocalStorage storage) {
  return ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(storage),
      palmAnalysisProvider.overrideWithValue(const UnavailablePalmAnalysis()),
    ],
    child: const MaterialApp(
      home: PalmReferenceScreen(bypassPaidEntryForTest: true),
    ),
  );
}
