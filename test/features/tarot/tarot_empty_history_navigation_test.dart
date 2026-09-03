/// Tarot empty history CTA enters module with TarotScope.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/navigation/oracly_route_generator.dart';
import 'package:oracly_new/core/services/history_service.dart';
import 'package:oracly_new/features/tarot/navigation/tarot_module_navigator.dart';
import 'package:oracly_new/features/tarot/presentation/screens/reading_history_screen.dart';
import 'package:oracly_new/features/tarot/presentation/screens/tarot_home_screen.dart';
import 'package:oracly_new/features/tarot/shared/tarot_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('tr'));

  testWidgets('empty history CTA opens tarot module with scope', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          historyServiceProvider.overrideWith(
            (ref) => HistoryService(MockHistoryRepository(storage)),
          ),
        ],
        child: MaterialApp(
          onGenerateRoute: OraclyRouteGenerator.onGenerateRoute,
          home: const ReadingHistoryScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text(OraclyL10n.t('tarot.empty.history_cta')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(TarotModuleNavigator), findsOneWidget);
    expect(find.byType(TarotHomeScreen), findsOneWidget);
    final scoped = tester.element(find.byType(TarotHomeScreen));
    expect(TarotScope.maybeOf(scoped), isNotNull);
  });
}
