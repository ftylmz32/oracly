/// Deep links / notifications / routes fail-closed while deletion gate blocks.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/account_deletion_pending_state.dart';
import 'package:oracly_new/core/auth/presentation/account_deletion_pending_screen.dart';
import 'package:oracly_new/core/navigation/oracly_route_generator.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/core/notifications/oracly_notification_kind.dart';
import 'package:oracly_new/core/notifications/oracly_notification_tap_inbox.dart';
import 'package:oracly_new/core/notifications/oracly_notification_tap_router.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_screen.dart';
import 'package:oracly_new/features/discovery_share/models/shareable_discovery.dart';
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
}

class _UnusedContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
