/// Calm return copy. Never dream text, chat, or birth date.
library;

import '../l10n/l10n.dart';
import 'oracly_notification_kind.dart';

abstract final class OraclyNotificationCopy {
  OraclyNotificationCopy._();

  static String get title => OraclyL10n.t('notif.title');

  static String body(
    OraclyNotificationKind kind, {
    String? theme,
  }) {
    if (kind == OraclyNotificationKind.discovery &&
        theme != null &&
        theme.trim().isNotEmpty) {
      return OraclyL10n.t('notif.discovery_theme').replaceAll('{theme}', theme);
    }
    return OraclyL10n.t('notif.${kind.name}');
  }
}
