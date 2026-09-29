/// P4E — economy surfaces stay readable on small screens and large text.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/daily_rewards/presentation/reference/daily_rewards_reference_screen.dart';
import 'package:oracly_new/features/daily_rewards/providers/daily_rewards_providers.dart';
import 'package:oracly_new/features/daily_rewards/services/daily_rewards_service.dart';
import 'package:oracly_new/features/gems/providers/gem_providers.dart';
import 'package:oracly_new/features/premium/presentation/reference/review_access_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_gem_authority.dart';
import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('ru'));

  for (final size in const [Size(320, 568), Size(360, 640), Size(390, 844)]) {
    testWidgets(
      'daily rewards ${size.width.toInt()} large text has no overflow',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final storage = await LocalStorage.open();
        final wallet = FakeGemAuthority().wallet(storage);
        final service = DailyRewardsService(
          MockUserRepository(storage),
          storage,
          wallet,
        );
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          buildProviderScopeHarness(
            storage: storage,
            overrides: [
              dailyRewardsServiceProvider.overrideWithValue(service),
              gemWalletServiceProvider.overrideWithValue(wallet),
            ],
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.4)),
                child: child!,
              ),
              home: const DailyRewardsReferenceScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('review access sheet copy is not raw English on RU', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: ReviewAccessBody())),
      ),
    );
    await tester.pump();
    expect(find.text('Review access code'), findsNothing);
    expect(find.textContaining('Активировать'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
