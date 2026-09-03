/// Shell Android back: nested pop, home tab, root exit.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/home/home_page.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/provider_scope_harness.dart';

Future<void> _pumpShell(WidgetTester tester, LocalStorage storage) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    buildProviderScopeHarness(
      storage: storage,
      child: MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          padding: EdgeInsets.only(bottom: 34),
        ),
        child: const MaterialApp(home: OraclyAppShell()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home root back is not swallowed', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await _pumpShell(tester, storage);
    expect(find.byType(HomePage), findsOneWidget);
    final handled = await tester.binding.handlePopRoute();
    expect(handled, isFalse);
  });

  testWidgets('non-home root back switches toward home', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await _pumpShell(tester, storage);
    final homeCtx = tester.element(find.byType(HomePage));
    OraclyNavigation.switchToTab(homeCtx, OraclyTab.profile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final handled = await tester.binding.handlePopRoute();
    expect(handled, isTrue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final scope = OraclyNavigationScope.of(
      tester.element(find.byType(OraclyNavigationScope)),
    );
    expect(scope.currentIndex, OraclyTab.home.index);
  });
}
