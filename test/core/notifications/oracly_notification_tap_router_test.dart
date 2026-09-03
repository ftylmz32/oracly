/// Notification tap routing — payload map, defer, dedupe.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/notifications/oracly_notification_kind.dart';
import 'package:oracly_new/core/notifications/oracly_notification_tap_inbox.dart';
import 'package:oracly_new/core/notifications/oracly_notification_tap_router.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation_scope.dart';

void main() {
  setUp(() => OraclyNotificationTapInbox.instance.resetForTests());

  test('known payload maps to kind', () {
    OraclyNotificationTapInbox.instance.offer('daily');
    expect(
      OraclyNotificationTapInbox.instance.pendingKind,
      OraclyNotificationKind.daily,
    );
    expect(
      OraclyNotificationTapInbox.instance.take(),
      OraclyNotificationKind.daily,
    );
  });

  test('unknown payload is ignored safely', () {
    OraclyNotificationTapInbox.instance.offer('not-a-kind');
    expect(OraclyNotificationTapInbox.instance.pendingKind, isNull);
    expect(OraclyNotificationTapInbox.instance.take(), isNull);
  });

  test('cold-start payload waits until navigator ready', () {
    OraclyNotificationTapInbox.instance.offer('discovery');
    OraclyNotificationTapRouter.openPending();
    expect(
      OraclyNotificationTapInbox.instance.pendingKind,
      OraclyNotificationKind.discovery,
    );
  });

  testWidgets('navigator ready consumes pending payload once', (tester) async {
    OraclyNotificationTapInbox.instance.offer('companion');
    await tester.pumpWidget(
      MaterialApp(
        home: OraclyNavigationScope(
          currentIndex: 0,
          switchToTab: (_) {},
          child: const SizedBox(),
        ),
      ),
    );
    final ctx = tester.element(find.byType(SizedBox));
    OraclyNotificationTapRouter.openPending(ctx);
    expect(OraclyNotificationTapInbox.instance.pendingKind, isNull);
    OraclyNotificationTapRouter.openPending(ctx);
    expect(OraclyNotificationTapInbox.instance.pendingKind, isNull);
  });

  test('duplicate callback does not double-open same payload', () {
    OraclyNotificationTapInbox.instance.offer('daily');
    expect(
      OraclyNotificationTapInbox.instance.take(),
      OraclyNotificationKind.daily,
    );
    OraclyNotificationTapInbox.instance.offer('daily');
    expect(OraclyNotificationTapInbox.instance.take(), isNull);
  });
}
