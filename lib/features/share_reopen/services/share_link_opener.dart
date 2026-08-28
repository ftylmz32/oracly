/// Opens a pending share URI on the root navigator.
library;

import 'package:flutter/material.dart';

import '../../../core/navigation/oracly_navigator_key.dart';
import '../../../core/navigation/oracly_page_transitions.dart';
import '../presentation/share_reopen_screen.dart';
import 'share_link_inbox.dart';
import 'share_link_parser.dart';

abstract final class ShareLinkOpener {
  ShareLinkOpener._();

  static void openPending([BuildContext? context]) {
    final uri = ShareLinkInbox.instance.take();
    if (uri == null) return;
    open(uri, context: context);
  }

  static void open(Uri uri, {BuildContext? context}) {
    if (ShareLinkParser.payloadOf(uri) == null) return;
    final nav = oraclyNavigatorKey.currentState;
    final page = OraclyPageTransitions.fade(
      page: ShareReopenScreen(uri: uri),
    );
    if (nav != null) {
      nav.push(page);
      return;
    }
    if (context != null && context.mounted) {
      Navigator.of(context, rootNavigator: true).push(page);
    }
  }
}
