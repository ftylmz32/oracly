/// G0 — navigation stack red team: chambers, OR and Premium never strand or
/// duplicate a route, and system back always returns to the one live shell.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/account_deletion_pending_state.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/navigation/oracly_navigation_service.dart';
import 'package:oracly_new/core/navigation/oracly_navigator_key.dart';
import 'package:oracly_new/core/navigation/oracly_route_generator.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/features/home/home_page.dart';
import 'package:oracly_new/screens/profile/reference/profile_reference_screen.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation.dart';
import 'package:oracly_new/shared/widgets/oracly_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/provider_scope_harness.dart';

class _Pushes extends NavigatorObserver {
  final names = <String?>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      names.add(route.settings.name);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<_Pushes> _pumpShell(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorage.open();
  final root = _Pushes();
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    buildProviderScopeHarness(
      storage: storage,
      child: MaterialApp(
        navigatorKey: oraclyNavigatorKey,
        navigatorObservers: [root],
        onGenerateRoute: OraclyRouteGenerator.onGenerateRoute,
        home: const OraclyAppShell(),
      ),
    ),
  );
  await tester.pump();
  await _settle(tester);
  root.names.clear();
  return root;
}

final _anyShell = find.byType(OraclyAppShell, skipOffstage: false);

NavigatorState _homeStack(WidgetTester tester) =>
    Navigator.of(tester.element(find.byType(HomePage, skipOffstage: false)));

Future<void> _backToShell(WidgetTester tester) async {
  // false would hand back to the OS: Android closes the app mid-journey.
  expect(await tester.binding.handlePopRoute(), isTrue);
  await _settle(tester);
  expect(_anyShell, findsOneWidget);
  expect(find.byType(OraclyBottomBar, skipOffstage: false), findsOneWidget);
  expect(oraclyNavigatorKey.currentState!.canPop(), isFalse);
  expect(_homeStack(tester).canPop(), isFalse);
  expect(find.byType(HomePage), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(AccountDeletionPendingState.markClear);

  testWidgets('Dream → Coffee → Palm → OR → Premium, back each time',
      (tester) async {
    final root = await _pumpShell(tester);
    final opens = <void Function(BuildContext)>[
      OraclyNavigationService.openDream,
      OraclyNavigationService.openCoffee,
      OraclyNavigationService.openPalm,
      OraclyNavigationService.openChat,
      OraclyNavigationService.openPremium,
    ];
    for (final open in opens) {
      open(tester.element(find.byType(HomePage)));
      await _settle(tester);
      expect(_anyShell, findsOneWidget);
      await _backToShell(tester);
    }
    expect(root.names, isNot(contains(OraclyRoutes.home)));
    OraclyNavigationService.openProfile(tester.element(find.byType(HomePage)));
    await _settle(tester);
    OraclyNavigationService.openHome(
      tester.element(find.byType(OraclyBottomBar)),
    );
    await _settle(tester);
    expect(find.byType(HomePage), findsOneWidget);
    expect(_anyShell, findsOneWidget);
  });

  testWidgets('Profile tab chamber: back pops it, then returns Home',
      (tester) async {
    await _pumpShell(tester);
    OraclyNavigationService.openProfile(tester.element(find.byType(HomePage)));
    await _settle(tester);
    final profile = tester.element(find.byType(ProfileReferenceScreen));
    OraclyNavigationService.openSettings(profile);
    await _settle(tester);
    expect(Navigator.of(profile).canPop(), isTrue);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await _settle(tester);
    expect(Navigator.of(profile).canPop(), isFalse);
    expect(find.byType(ProfileReferenceScreen), findsOneWidget);
    await _backToShell(tester);
    expect(await tester.binding.handlePopRoute(), isFalse);
  });

  testWidgets('repeated taps never stack a duplicate top route',
      (tester) async {
    final root = await _pumpShell(tester);
    for (final open in <void Function(BuildContext)>[
      OraclyNavigationService.openDream,
      OraclyNavigationService.openCoffee,
      OraclyNavigationService.openPalm,
      OraclyNavigationService.openPremium,
    ]) {
      final ctx = tester.element(find.byType(HomePage));
      for (var i = 0; i < 3; i++) {
        open(ctx);
      }
      await _settle(tester);
      // One back must land on the shell: a duplicate would leave a route.
      await _backToShell(tester);
    }
    final ctx = tester.element(find.byType(HomePage));
    for (var i = 0; i < 3; i++) {
      OraclyNavigationService.openChat(ctx);
      await tester.pump();
    }
    await _settle(tester);
    expect(root.names.where((n) => n == OraclyRoutes.chat), hasLength(1));
    await _backToShell(tester);
  });
}
