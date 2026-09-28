/// G0 — one live shell: tab helpers and warm deep links never stack a shell.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/account_deletion_pending_state.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/navigation/oracly_navigation_service.dart';
import 'package:oracly_new/core/navigation/oracly_navigator_key.dart';
import 'package:oracly_new/core/navigation/oracly_route_generator.dart';
import 'package:oracly_new/features/discovery_share/models/shareable_discovery.dart';
import 'package:oracly_new/features/home/home_page.dart';
import 'package:oracly_new/features/share_reopen/models/share_public_payload.dart';
import 'package:oracly_new/features/share_reopen/presentation/share_reopen_screen.dart';
import 'package:oracly_new/features/share_reopen/services/share_link_inbox.dart';
import 'package:oracly_new/features/share_reopen/services/share_link_parser.dart';
import 'package:oracly_new/features/share_reopen/widgets/share_link_host.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation.dart';
import 'package:oracly_new/shared/navigation/oracly_shell_bridge.dart';
import 'package:oracly_new/shared/widgets/oracly_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/provider_scope_harness.dart';

String _shareLink() => ShareLinkParser.build(
      const SharePublicPayload(
        id: 'ab12cd34ef56ab78',
        kind: DiscoveryShareKind.tarot,
        highlight: 'Denge',
      ),
    ).toString();

Future<void> _pumpLiveShell(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorage.open();
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    buildProviderScopeHarness(
      storage: storage,
      child: ShareLinkHost(
        child: MaterialApp(
          navigatorKey: oraclyNavigatorKey,
          onGenerateRoute: OraclyRouteGenerator.onGenerateRoute,
          home: const OraclyAppShell(),
        ),
      ),
    ),
  );
  await tester.pump();
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

int _scopeIndex(WidgetTester tester) => OraclyNavigationScope.of(
      tester.element(find.byType(OraclyBottomBar)),
    ).currentIndex;

final _anyShell = find.byType(OraclyAppShell, skipOffstage: false);

void _expectSingleShell() {
  expect(_anyShell, findsOneWidget);
  expect(find.byType(OraclyBottomBar, skipOffstage: false), findsOneWidget);
  expect(oraclyNavigatorKey.currentState!.canPop(), isFalse);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AccountDeletionPendingState.markClear();
    ShareLinkInbox.instance.clearForTest();
  });
  tearDown(() => ShareLinkInbox.instance.clearForTest());

  testWidgets('inside shell: Home / Profile / Explore x5 switch tabs only',
      (tester) async {
    await _pumpLiveShell(tester);
    final ctx = tester.element(find.byType(HomePage));
    for (final (open, tab) in [
      (OraclyNavigationService.openProfile, OraclyTab.profile),
      (OraclyNavigationService.openHome, OraclyTab.home),
      (OraclyNavigationService.openExploreTab, OraclyTab.astrology),
      (OraclyNavigationService.openDailyEnergy, OraclyTab.home),
      (OraclyNavigationService.openAchievements, OraclyTab.home),
    ]) {
      for (var i = 0; i < 5; i++) {
        open(ctx);
        await _settle(tester);
        expect(_scopeIndex(tester), tab.index);
        _expectSingleShell();
      }
    }
    expect(await tester.binding.handlePopRoute(), isFalse);
  });

  testWidgets('outside shell scope: bridge switches the live shell, no push',
      (tester) async {
    await _pumpLiveShell(tester);
    final rootCtx = oraclyNavigatorKey.currentContext!;
    expect(OraclyNavigationScope.maybeOf(rootCtx), isNull);
    expect(OraclyShellBridge.isActive, isTrue);
    OraclyNavigationService.openProfile(rootCtx);
    await _settle(tester);
    expect(_scopeIndex(tester), OraclyTab.profile.index);
    OraclyNavigationService.openHome(rootCtx);
    await _settle(tester);
    expect(_scopeIndex(tester), OraclyTab.home.index);
    _expectSingleShell();
  });

  testWidgets('no shell mounted: tab helpers are a safe no-op, never a push',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: await LocalStorage.open(),
        child: MaterialApp(
          navigatorKey: oraclyNavigatorKey,
          onGenerateRoute: OraclyRouteGenerator.onGenerateRoute,
          home: const SizedBox.shrink(),
        ),
      ),
    );
    final ctx = oraclyNavigatorKey.currentContext!;
    expect(OraclyShellBridge.isActive, isFalse);
    OraclyNavigationService.openHome(ctx);
    OraclyNavigationService.openProfile(ctx);
    OraclyNavigationService.openExploreTab(ctx);
    await _settle(tester);
    expect(find.byType(OraclyAppShell), findsNothing);
    expect(oraclyNavigatorKey.currentState!.canPop(), isFalse);
  });

  testWidgets('warm share link over the live shell opens share, never a shell',
      (tester) async {
    await _pumpLiveShell(tester);
    for (var i = 0; i < 3; i++) {
      await tester.binding.handlePushRoute(_shareLink());
      await _settle(tester);
      expect(find.byType(ShareReopenScreen), findsOneWidget);
      expect(_anyShell, findsOneWidget);
      oraclyNavigatorKey.currentState!.pop();
      await _settle(tester);
      _expectSingleShell();
    }
  });

  testWidgets('warm malformed / unsupported links never stack a shell',
      (tester) async {
    await _pumpLiveShell(tester);
    for (final raw in [
      'oracly://share/not-a-token',
      'oracly://share',
      'oracly://open/home',
      'oracly://open/profile',
      'oracly://open/numerology',
      'oracly://open/soul-mate',
      'oracly://open/%00%ZZ',
    ]) {
      await tester.binding.handlePushRoute(raw);
      await _settle(tester);
      _expectSingleShell();
      expect(find.byType(ShareReopenScreen), findsNothing);
    }
  });
}
