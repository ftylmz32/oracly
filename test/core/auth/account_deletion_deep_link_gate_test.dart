/// Deep links / notifications / routes fail-closed while deletion gate blocks.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/account_deletion_pending_state.dart';
import 'package:oracly_new/core/auth/presentation/account_deletion_pending_screen.dart';
import 'package:oracly_new/core/auth/presentation/account_integrity_recovery_screen.dart';
import 'package:oracly_new/core/auth/presentation/gate_unresolved_screen.dart';
import 'package:oracly_new/core/auth/presentation/secure_startup_recovery_screen.dart';
import 'package:oracly_new/core/navigation/oracly_route_generator.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/core/notifications/oracly_notification_kind.dart';
import 'package:oracly_new/core/notifications/oracly_notification_tap_inbox.dart';
import 'package:oracly_new/core/notifications/oracly_notification_tap_router.dart';
import 'package:oracly_new/features/coffee/coffee_v2/presentation/coffee_v2_entry_gate.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_screen.dart';
import 'package:oracly_new/features/discovery_share/models/shareable_discovery.dart';
import 'package:oracly_new/features/gems/presentation/reference/gems_reference_screen.dart';
import 'package:oracly_new/features/share_reopen/models/share_public_payload.dart';
import 'package:oracly_new/features/share_reopen/services/share_link_inbox.dart';
import 'package:oracly_new/features/share_reopen/services/share_link_opener.dart';
import 'package:oracly_new/features/share_reopen/services/share_link_parser.dart';
import 'package:oracly_new/features/tarot/navigation/tarot_module_navigator.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AccountDeletionPendingState.markClear();
    ShareLinkInbox.instance.clearForTest();
    OraclyNotificationTapInbox.instance.resetForTests();
  });

  tearDown(() {
    AccountDeletionPendingState.markClear();
    ShareLinkInbox.instance.clearForTest();
    OraclyNotificationTapInbox.instance.resetForTests();
  });

  group('route generator fail-closed while blocked', () {
    for (final name in [
      OraclyRoutes.home,
      OraclyRoutes.tarot,
      OraclyRoutes.coffee,
      OraclyRoutes.palm,
      OraclyRoutes.dream,
      OraclyRoutes.astrology,
      OraclyRoutes.starMap,
      OraclyRoutes.chat,
      OraclyRoutes.profile,
      OraclyRoutes.settings,
      OraclyRoutes.premium,
      OraclyRoutes.gems,
      OraclyRoutes.readingHistory,
      OraclyRoutes.discoveryJournal,
      '/unknown-deep-link',
    ]) {
      test('blocked → pending route widget for $name', () {
        AccountDeletionPendingState.markBlocked();
        final route = OraclyRouteGenerator.onGenerateRoute(
          RouteSettings(name: name),
        );
        expect(route, isA<PageRouteBuilder<dynamic>>());
        final built = (route! as PageRouteBuilder<dynamic>).pageBuilder(
          _UnusedContext(),
          const AlwaysStoppedAnimation<double>(1),
          const AlwaysStoppedAnimation<double>(1),
        );
        expect(built, isA<AccountDeletionPendingScreen>());
      });
    }
  });

  test(
      'integrityRecovery → integrity screen for a named route — never the '
      'pending-deletion claim screen', () {
    AccountDeletionPendingState.markIntegrityRecovery();
    final route = OraclyRouteGenerator.onGenerateRoute(
      const RouteSettings(name: OraclyRoutes.home),
    );
    expect(route, isA<PageRouteBuilder<dynamic>>());
    final built = (route! as PageRouteBuilder<dynamic>).pageBuilder(
      _UnusedContext(),
      const AlwaysStoppedAnimation<double>(1),
      const AlwaysStoppedAnimation<double>(1),
    );
    expect(built, isA<AccountIntegrityRecoveryScreen>());
    expect(built, isNot(isA<AccountDeletionPendingScreen>()));
  });

  group(
      'P0 FIX: storageUnavailable and unresolved are NOT pending account '
      'deletion — the route generator must never fall through to the '
      'pending-deletion screen for them', () {
    for (final name in [
      OraclyRoutes.home,
      OraclyRoutes.chat,
      OraclyRoutes.coffee,
      OraclyRoutes.tarot,
      OraclyRoutes.premium,
      OraclyRoutes.gems,
      OraclyRoutes.profile,
      '/unknown-deep-link',
    ]) {
      test('storageUnavailable → secure recovery screen for $name — NOT '
          'the pending-deletion claim screen', () {
        AccountDeletionPendingState.markStorageUnavailable();
        final route = OraclyRouteGenerator.onGenerateRoute(
          RouteSettings(name: name),
        );
        expect(route, isA<PageRouteBuilder<dynamic>>());
        final built = (route! as PageRouteBuilder<dynamic>).pageBuilder(
          _UnusedContext(),
          const AlwaysStoppedAnimation<double>(1),
          const AlwaysStoppedAnimation<double>(1),
        );
        expect(built, isA<SecureStartupRecoveryScreen>());
        expect(built, isNot(isA<AccountDeletionPendingScreen>()));
      });

      test('unresolved → neutral gate screen for $name — NOT the '
          'pending-deletion claim screen, no feature route', () {
        AccountDeletionPendingState.phase.value =
            AccountDeletionGatePhase.unresolved;
        final route = OraclyRouteGenerator.onGenerateRoute(
          RouteSettings(name: name),
        );
        expect(route, isA<PageRouteBuilder<dynamic>>());
        final built = (route! as PageRouteBuilder<dynamic>).pageBuilder(
          _UnusedContext(),
          const AlwaysStoppedAnimation<double>(1),
          const AlwaysStoppedAnimation<double>(1),
        );
        expect(built, isA<GateUnresolvedScreen>());
        expect(built, isNot(isA<AccountDeletionPendingScreen>()));
        expect(built, isNot(isA<OraclyAppShell>()));
      });
    }
  });

  test('finalizing → pending-deletion screen for a named route — a real '
      'deletion lifecycle IS known to exist for this phase', () {
    AccountDeletionPendingState.markFinalizing();
    final route = OraclyRouteGenerator.onGenerateRoute(
      const RouteSettings(name: OraclyRoutes.chat),
    );
    final built = (route! as PageRouteBuilder<dynamic>).pageBuilder(
      _UnusedContext(),
      const AlwaysStoppedAnimation<double>(1),
      const AlwaysStoppedAnimation<double>(1),
    );
    expect(built, isA<AccountDeletionPendingScreen>());
  });

  test('clear gate still generates Home shell', () {
    AccountDeletionPendingState.markClear();
    final route = OraclyRouteGenerator.onGenerateRoute(
      const RouteSettings(name: OraclyRoutes.home),
    );
    final built = (route! as PageRouteBuilder<dynamic>).pageBuilder(
      _UnusedContext(),
      const AlwaysStoppedAnimation<double>(1),
      const AlwaysStoppedAnimation<double>(1),
    );
    expect(built, isA<OraclyAppShell>());
  });

  group('clear gate resolves requested feature routes normally', () {
    final cases = <(String, bool Function(dynamic))>[
      (OraclyRoutes.coffee, (w) => w is CoffeeV2EntryGate),
      (OraclyRoutes.tarot, (w) => w is TarotModuleNavigator),
      (OraclyRoutes.gems, (w) => w is GemsReferenceScreen),
      (OraclyRoutes.profile, (w) => w is OraclyAppShell),
    ];
    for (final (name, matches) in cases) {
      test('clear → requested feature resolves normally for $name', () {
        AccountDeletionPendingState.markClear();
        final route = OraclyRouteGenerator.onGenerateRoute(
          RouteSettings(name: name),
        );
        final built = (route! as PageRouteBuilder<dynamic>).pageBuilder(
          _UnusedContext(),
          const AlwaysStoppedAnimation<double>(1),
          const AlwaysStoppedAnimation<double>(1),
        );
        expect(built, isNot(isA<AccountDeletionPendingScreen>()));
        expect(built, isNot(isA<AccountIntegrityRecoveryScreen>()));
        expect(built, isNot(isA<SecureStartupRecoveryScreen>()));
        expect(built, isNot(isA<GateUnresolvedScreen>()));
        expect(matches(built), isTrue, reason: 'unexpected widget: $built');
      });
    }
  });

  testWidgets('blocked: pushNamed chat does not show Companion', (tester) async {
    AccountDeletionPendingState.markBlocked();
    await tester.pumpWidget(
      MaterialApp(
        home: const AccountDeletionPendingScreen(),
        onGenerateRoute: OraclyRouteGenerator.onGenerateRoute,
      ),
    );
    await tester.pump();
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pushNamed(OraclyRoutes.chat);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(AccountDeletionPendingScreen), findsWidgets);
    expect(find.byType(CompanionReferenceScreen), findsNothing);
    expect(find.byType(TarotModuleNavigator), findsNothing);
  });

  test('blocked: share openPending leaves inbox queued', () {
    AccountDeletionPendingState.markBlocked();
    final uri = ShareLinkParser.build(
      const SharePublicPayload(
        id: 'ab12cd34ef56ab78',
        kind: DiscoveryShareKind.tarot,
        highlight: 'Denge',
      ),
    );
    ShareLinkInbox.instance.offer(uri);
    expect(ShareLinkInbox.instance.hasPendingForTest, isTrue);
    ShareLinkOpener.openPending();
    expect(ShareLinkInbox.instance.hasPendingForTest, isTrue);
  });

  test('blocked: notification openPending leaves inbox queued', () {
    AccountDeletionPendingState.markBlocked();
    OraclyNotificationTapInbox.instance.offer('daily');
    OraclyNotificationTapRouter.openPending();
    expect(OraclyNotificationTapInbox.instance.hasPendingForTest, isTrue);
  });

  test('clear: notification inbox take works', () {
    AccountDeletionPendingState.markClear();
    OraclyNotificationTapInbox.instance.offer('daily');
    expect(AccountDeletionPendingState.blocksDeepLinks, isFalse);
    expect(
      OraclyNotificationTapInbox.instance.take(),
      OraclyNotificationKind.daily,
    );
  });

  test(
      'finalizing, storageUnavailable, integrityRecovery, and unresolved '
      'also block deep links', () {
    for (final phase in [
      AccountDeletionGatePhase.finalizing,
      AccountDeletionGatePhase.storageUnavailable,
      AccountDeletionGatePhase.integrityRecovery,
      AccountDeletionGatePhase.unresolved,
    ]) {
      AccountDeletionPendingState.phase.value = phase;
      expect(AccountDeletionPendingState.blocksDeepLinks, isTrue);
      expect(AccountDeletionPendingState.allowsOwnerBoundExperience, isFalse);
      ShareLinkInbox.instance.offer(
        ShareLinkParser.build(
          const SharePublicPayload(
            id: 'ab12cd34ef56ab78',
            kind: DiscoveryShareKind.tarot,
            highlight: 'Denge',
          ),
        ),
      );
      ShareLinkOpener.openPending();
      expect(ShareLinkInbox.instance.hasPendingForTest, isTrue);
      ShareLinkInbox.instance.clearForTest();
    }
  });
}

class _UnusedContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
