/// Holds an inbound share URI until the navigator can present it.
library;

import 'package:flutter/foundation.dart';

import 'share_link_parser.dart';

class ShareLinkInbox {
  Uri? _pending;

  static final ShareLinkInbox instance = ShareLinkInbox();

  Uri? get pending => _pending;

  void capture(String? raw) {
    final uri = ShareLinkParser.parse(raw);
    if (uri != null) _pending = uri;
  }

  void offer(Uri uri) {
    if (ShareLinkParser.payloadOf(uri) != null) _pending = uri;
  }

  Uri? take() {
    final uri = _pending;
    _pending = null;
    return uri;
  }

  @visibleForTesting
  void clearForTest() => _pending = null;

  @visibleForTesting
  bool get hasPendingForTest => _pending != null;
}
