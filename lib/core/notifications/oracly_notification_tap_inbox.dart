/// Queues notification tap payloads until navigation is ready.
library;

import 'oracly_notification_kind.dart';

class OraclyNotificationTapInbox {
  OraclyNotificationTapInbox._();

  static final instance = OraclyNotificationTapInbox._();

  OraclyNotificationKind? _pending;
  String? _lastConsumedRaw;

  OraclyNotificationKind? get pendingKind => _pending;

  void resetForTests() {
    _pending = null;
    _lastConsumedRaw = null;
  }

  void offer(String? raw) {
    if (raw == null) return;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;
    if (trimmed == _lastConsumedRaw) return;
    final kind = _kindOf(trimmed);
    if (kind == null) return;
    _pending = kind;
  }

  OraclyNotificationKind? take() {
    final kind = _pending;
    if (kind == null) return null;
    _pending = null;
    _lastConsumedRaw = kind.name;
    return kind;
  }

  OraclyNotificationKind? _kindOf(String raw) {
    for (final kind in OraclyNotificationKind.values) {
      if (kind.name == raw) return kind;
    }
    return null;
  }
}
