/// Golden-path honesty regressions for Favorites + Premium gate sheet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/favorite_moments/models/favorite_moment.dart';
import 'package:oracly_new/features/favorite_moments/presentation/screens/favorite_moments_screen.dart';
import 'package:oracly_new/features/favorite_moments/presentation/widgets/favorite_moments_empty.dart';
import 'package:oracly_new/features/favorite_moments/providers/favorite_moments_providers.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_entry_sheet.dart';
import 'package:oracly_new/shared/widgets/oracly_error_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('favorites load error is not empty state', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          favoriteMomentsProvider.overrideWith(_FailingFavorites.new),
        ],
        child: const MaterialApp(
          home: FavoriteMomentsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(FavoriteMomentsEmpty), findsNothing);
    expect(find.byType(OraclyErrorState), findsOneWidget);
    expect(find.text(ResilienceCopy.temporaryFailure), findsOneWidget);
  });

  testWidgets('premium gate shows store-closed only when unconfigured',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: PremiumEntryBody(showCta: true),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // Harness defaults to UnavailablePremiumPurchase → honest notice.
    expect(find.text(PremiumCopy.ctaUnavailable), findsOneWidget);
    expect(find.text(PremiumCopy.ctaExplore), findsOneWidget);
  });
}

class _FailingFavorites extends FavoriteMomentsNotifier {
  @override
  Future<List<FavoriteMoment>> build() async {
    throw StateError('favorites load failed');
  }
}
