/// Review Access sheet — viewport, text-scaling, and keyboard sweep.
/// Complements review_access_sheet_test.dart (Material ancestor + honest
/// network-failure copy) with the layout side: no RenderFlex overflow at the
/// required viewport sizes, the "Activate" button stays reachable under
/// larger text scaling, and the code field + button stay usable when a
/// keyboard covers part of the sheet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/data/repositories/review_access_repository.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/premium/models/review_access_result.dart';
import 'package:oracly_new/features/premium/presentation/reference/review_access_sheet.dart';
import 'package:oracly_new/features/premium/providers/premium_providers.dart';
import 'package:oracly_new/features/premium/services/review_access_service.dart';
import 'package:oracly_new/features/premium/services/unavailable_premium_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeReviewAccessService implements ReviewAccessService {
  @override
  bool get isConfigured => true;
  @override
  Future<ReviewAccessResult> activate(String code) async =>
      ReviewAccessResult.denied('invalid_code');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> buildContainer() async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final secure = InMemorySecureStorage();
    final service = PremiumService(
      MockPremiumRepository(storage, secureStorage: secure),
      MockUserRepository(storage),
      const UnavailablePremiumPurchase(),
      null,
      ReviewAccessRepository(storage, secureStorage: secure),
      _FakeReviewAccessService(),
    );
    final container = ProviderContainer(
      overrides: [premiumServiceProvider.overrideWithValue(service)],
    );
    await container.read(premiumStatusProvider).load();
    return container;
  }

  Widget host(ProviderContainer container, Size size, {double textScale = 1.0}) {
    return UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ReviewAccessSheet.show(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  const viewports = <Size>[
    Size(320, 568),
    Size(360, 800),
    Size(375, 812),
    Size(390, 844),
    Size(412, 915),
  ];

  for (final size in viewports) {
    testWidgets(
      'Review Access sheet fits ${size.width.toInt()}x${size.height.toInt()} '
      'at 1.3x text scale, Activate button reachable',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final container = await buildContainer();

        await tester.pumpWidget(host(container, size, textScale: 1.3));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(TextField), findsOneWidget);
        final activate = find.text('Activate');
        expect(activate, findsOneWidget);
        await tester.ensureVisible(activate);
        await tester.pump();
        expect(tester.takeException(), isNull);

        // The button must be genuinely tappable, not just present in the
        // tree behind other content.
        await tester.tap(activate, warnIfMissed: true);
        await tester.pump();
        expect(tester.takeException(), isNull);
        container.dispose();
      },
    );
  }

  testWidgets(
    'Review Access sheet keeps the code field and Activate button reachable '
    'when the keyboard covers part of the screen',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final container = await buildContainer();

      await tester.pumpWidget(host(container, const Size(375, 812)));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'SOME-CODE');
      await tester.pump();

      // Simulate a real on-screen keyboard covering ~40% of the screen —
      // the sheet's own maxHeight/padding logic reacts to viewInsets.bottom.
      final dpr = tester.view.devicePixelRatio;
      final priorInsets = tester.view.viewInsets;
      tester.view.viewInsets = FakeViewPadding(bottom: 320 * dpr);
      addTearDown(() => tester.view.viewInsets = priorInsets);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('SOME-CODE'), findsOneWidget);

      final activate = find.text('Activate');
      expect(activate, findsOneWidget);
      await tester.ensureVisible(activate);
      await tester.pump();
      await tester.tap(activate, warnIfMissed: true);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('This code is not valid right now.'), findsOneWidget);
      container.dispose();
    },
  );
}
