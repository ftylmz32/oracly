/// Regression: ReviewAccessSheet renders inside OraclyBottomSheet, which
/// uses showGeneralDialog — content lands directly in the Overlay with no
/// implicit Material ancestor. The sheet's TextField needs one; this test
/// pumps the real sheet (not a stand-in) so a missing ancestor throws here.
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
  String? validCode = 'PLAY-REVIEW-1';
  bool networkFailureNext = false;

  @override
  bool get isConfigured => true;

  @override
  Future<ReviewAccessResult> activate(String code) async {
    if (networkFailureNext) {
      networkFailureNext = false;
      return ReviewAccessResult.denied('network_or_parse', definitive: false);
    }
    return code == validCode
        ? ReviewAccessResult.granted()
        : ReviewAccessResult.denied('invalid_code');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> buildContainer({
    _FakeReviewAccessService? reviewService,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final secure = InMemorySecureStorage();
    final service = PremiumService(
      MockPremiumRepository(storage, secureStorage: secure),
      MockUserRepository(storage),
      const UnavailablePremiumPurchase(),
      null,
      ReviewAccessRepository(storage, secureStorage: secure),
      reviewService ?? _FakeReviewAccessService(),
    );
    final container = ProviderContainer(
      overrides: [premiumServiceProvider.overrideWithValue(service)],
    );
    await container.read(premiumStatusProvider).load();
    return container;
  }

  testWidgets(
    'renders with a valid Material ancestor and the code field stays '
    'interactable — regression for "No Material widget found" on the real '
    'showGeneralDialog sheet',
    (tester) async {
      final container = await buildContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
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

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'PLAY-REVIEW-1');
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('PLAY-REVIEW-1'), findsOneWidget);

      await tester.tap(find.text('Activate'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(container.read(premiumStatusProvider).isPremium, isTrue);
      container.dispose();
    },
  );

  testWidgets(
    'a transient network/server failure shows an honest retry message, not '
    '"code is not valid" — the code was never actually checked',
    (tester) async {
      final reviewService = _FakeReviewAccessService()
        ..networkFailureNext = true;
      final container = await buildContainer(reviewService: reviewService);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
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

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'PLAY-REVIEW-1');
      await tester.tap(find.text('Activate'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('This code is not valid right now.'), findsNothing);
      expect(
        find.textContaining("Couldn't reach the server"),
        findsOneWidget,
      );
      // A transient failure must never grant or persist access.
      expect(container.read(premiumStatusProvider).isPremium, isFalse);
      container.dispose();
    },
  );
}
