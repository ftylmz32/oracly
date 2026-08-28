/// One scheduled invitation. Body is catalogue copy — never private text.
library;

import 'oracly_notification_kind.dart';

class OraclyNotificationPayload {
  const OraclyNotificationPayload({
    required this.kind,
    required this.title,
    required this.body,
  });

  final OraclyNotificationKind kind;
  final String title;
  final String body;

  Map<String, String> toExtra() => {'k': kind.name};
}
