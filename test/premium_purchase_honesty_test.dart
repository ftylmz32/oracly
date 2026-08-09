import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/domain/repositories/premium_repository.dart';
import 'package:oracly_new/features/premium/presentation/screens/premium_screen.dart';
import 'package:oracly_new/features/premium/presentation/widgets/premium_membership_cta.dart';
import 'package:oracly_new/features/premium/presentation/widgets/premium_unavailable_notice.dart';

class _CountingPremiumRepository implements PremiumRepository {
  _CountingPremiumRepository(this._inner);

  final MockPremiumRepository _inner;
  int activatePlanCalls = 0;

  @override
  Future<void> activatePlan(PremiumPlanKind plan) async {
    activatePlanCalls += 1;
    await _inner.activatePlan(plan);
  }

  @override
  Future<PremiumPlanKind?> activePlan() => _inner.activePlan();

  @override
  Future<List<PremiumPlanModel>> getPlans() => _inner.getPlans();

  @override
  Future<bool> isPremiumActive() => _inner.isPremiumActive();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late _CountingPremiumRepository countingPremium;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    countingPremium = _CountingPremiumRepository(MockPremiumRepository(storage));
  });

  Future<void> pumpPremium(WidgetTester tester) async {
    final view = tester.view;
    view.physicalSize = const Size(800, 2400);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          premiumRepositoryProvider.overrideWithValue(countingPremium),
        ],
        child: const MaterialApp(
          home: PremiumScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1600));
  }

  group('Premium purchase honesty (live UI)', () {
    testWidgets('shows unavailable copy and no purchase CTA', (tester) async {
      await pumpPremium(tester);

      expect(find.text(PremiumCopy.purchaseUnavailableTitle), findsOneWidget);
      expect(find.text(PremiumCopy.purchaseUnavailableBody), findsOneWidget);
      expect(find.byType(PremiumUnavailableNotice), findsOneWidget);
      expect(find.byType(PremiumMembershipCta), findsNothing);
      expect(find.text(PremiumCopy.ctaJoin), findsNothing);
      expect(find.text('Satın Al'), findsNothing);
      expect(find.text('Abone Ol'), findsNothing);
      expect(find.text("Premium'a Geç"), findsNothing);
      expect(find.text(PremiumCopy.activatedMessage), findsNothing);
      // Fake store prices must not appear as purchasable plan rows.
      expect(find.text('₺149,99/ay'), findsNothing);
      expect(find.text('₺899,99/yıl'), findsNothing);
      expect(find.text('₺2.499,99'), findsNothing);
      expect(find.text('Sınırsız Tarot Açılımı'), findsNothing);
      expect(find.text('Premium Desteler'), findsNothing);
      expect(find.text(PremiumCopy.plannedBenefitLabel), findsWidgets);
    });

    testWidgets(
      'tapping unavailable notice does not call activatePlan or activate Premium',
      (tester) async {
        await pumpPremium(tester);

        final notice = find.byType(PremiumUnavailableNotice);
        await tester.tap(notice);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(countingPremium.activatePlanCalls, 0);
        expect(await countingPremium.isPremiumActive(), isFalse);
        expect(find.text(PremiumCopy.activatedMessage), findsNothing);
        expect(find.text(PremiumCopy.ctaActive), findsNothing);
      },
    );
  });
}
