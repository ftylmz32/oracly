/// Palm capture guidance — presentation only, all viewports.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/palm/copy/palm_copy.dart';
import 'package:oracly_new/features/palm/presentation/palm_capture_palm_guide.dart';
import 'package:oracly_new/features/palm/presentation/palm_capture_view.dart';
import 'package:oracly_new/features/palm/presentation/palm_reference_screen.dart';
import 'package:oracly_new/features/palm/providers/palm_providers.dart';
import 'package:oracly_new/features/palm/services/unavailable_palm_analysis.dart';
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
    ProviderScope.containerOf(tester.element(find.byType(PalmReferenceScreen)))
        .read(palmReadingControllerProvider)
        .startCapture();
    await tester.pump();
  }

  for (final size in viewports) {
    testWidgets('palm capture guidance fits ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      await openCapture(tester, storage);

      expect(tester.takeException(), isNull);
      expect(find.byType(PalmCaptureView), findsOneWidget);
      expect(find.byType(PalmCapturePalmGuide), findsOneWidget);
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
    });
  }
}

Widget _app(LocalStorage storage) {
  return ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(storage),
      palmAnalysisProvider.overrideWithValue(const UnavailablePalmAnalysis()),
    ],
    child: const MaterialApp(home: PalmReferenceScreen()),
  );
}