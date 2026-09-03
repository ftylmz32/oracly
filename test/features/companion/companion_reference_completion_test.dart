/// OR/Luna live screen completion matrix.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_providers.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_app_bar.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_screen.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_tokens.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/features/premium/providers/premium_providers.dart';
import 'package:oracly_new/features/premium/services/unavailable_premium_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _matrix = <Size>[
  Size(320, 568),
  Size(360, 640),
  Size(360, 800),
  Size(375, 812),
  Size(390, 844),
  Size(412, 915),
  Size(430, 932),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<LocalStorage> openStorage() async {
    SharedPreferences.setMockInitialValues({});
    return LocalStorage.open();
  }

  Future<PremiumStatusController> activePremium(LocalStorage storage) async {
    final premium = MockPremiumRepository(storage);
    final users = MockUserRepository(storage);
    await premium.activatePlan(PremiumPlanKind.yearly, authoritative: true);
    final service = PremiumService(
      premium,
      users,
      const UnavailablePremiumPurchase(),
    );
    final status = PremiumStatusController(service);
    await status.load();
    return status;
  }

  Widget shell({
    required Size size,
    required LocalStorage storage,
    required Widget child,
    double textScale = 1.0,
    List<Override> overrides = const [],
  }) {
    final pad = CompanionReferenceTokens.shellSafePadding(size);
    return ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        oraclyAiServiceProvider.overrideWithValue(
          const UnconfiguredOraclyAiService(allowsLocalFallback: true),
        ),
        ...overrides,
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: pad,
            viewPadding: pad,
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: SizedBox(width: size.width, height: size.height, child: child),
        ),
      ),
    );
  }

  Future<void> pumpOr(
    WidgetTester tester,
    Size size, {
    double textScale = 1.0,
    PremiumStatusController? premium,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = await openStorage();
    final overrides = <Override>[];
    if (premium != null) {
      overrides.add(premiumStatusProvider.overrideWith((ref) => premium));
    }
    await tester.pumpWidget(
      shell(
        size: size,
        storage: storage,
        textScale: textScale,
        overrides: overrides,
        child: const CompanionReferenceScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('OR completion matrix', () {
    for (final size in _matrix) {
      testWidgets('free x', (
        tester,
      ) async {
        await pumpOr(tester, size);
        expect(tester.takeException(), isNull);
        expect(find.byType(CompanionReferenceAppBar), findsOneWidget);
        expect(find.text(CompanionCopy.orPremiumLead), findsOneWidget);
      });
    }
  });

  testWidgets('320x568 premium chamber', (tester) async {
    final storage = await openStorage();
    final premium = await activePremium(storage);
    await pumpOr(tester, const Size(320, 568), premium: premium);
    expect(tester.takeException(), isNull);
    expect(find.byType(CompanionReferenceAppBar), findsOneWidget);
  });

  testWidgets('360x640 textScale 1.3 and 1.5 premium', (tester) async {
    final storage = await openStorage();
    final premium = await activePremium(storage);
    await pumpOr(
      tester,
      const Size(360, 640),
      textScale: 1.3,
      premium: premium,
    );
    expect(tester.takeException(), isNull);
    await pumpOr(
      tester,
      const Size(360, 640),
      textScale: 1.5,
      premium: premium,
    );
    expect(tester.takeException(), isNull);
  });
}

