/// Maps notification payloads to canonical destinations.
library;

import 'package:flutter/widgets.dart';

import '../navigation/oracly_navigator_key.dart';
import '../navigation/oracly_navigation_service.dart';
import '../../shared/navigation/oracly_navigation_scope.dart';
import '../../shared/navigation/oracly_shell_bridge.dart';
import 'oracly_notification_kind.dart';
import 'oracly_notification_tap_inbox.dart';

abstract final class OraclyNotificationTapRouter {
  OraclyNotificationTapRouter._();

  static void offerPayload(String? payload) {
    OraclyNotificationTapInbox.instance.offer(payload);
  }

  static void openPending([BuildContext? context]) {
    if (!_navigatorReady(context)) return;
    final kind = OraclyNotificationTapInbox.instance.take();
    if (kind == null) return;
    final ctx = _resolveContext(context);
    if (ctx == null) return;
    _openKind(ctx, kind);
  }

  static bool _navigatorReady(BuildContext? context) {
    if (context != null && context.mounted) {
      if (OraclyNavigationScope.maybeOf(context) != null) return true;
    }
    return OraclyShellBridge.isActive;
  }

  static BuildContext? _resolveContext(BuildContext? context) {
    if (context != null && context.mounted) return context;
    final navContext = oraclyNavigatorKey.currentContext;
    if (navContext != null && navContext.mounted) return navContext;
    return null;
  }

  static void _openKind(BuildContext context, OraclyNotificationKind kind) {
    switch (kind) {
      case OraclyNotificationKind.daily:
        OraclyNavigationService.openDailyMessage(context);
      case OraclyNotificationKind.discovery:
        OraclyNavigationService.openDiscoveryJournal(context);
      case OraclyNotificationKind.companion:
        OraclyNavigationService.openChat(context);
    }
  }
}
