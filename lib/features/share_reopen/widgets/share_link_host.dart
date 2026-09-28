/// Owns every warm (app-already-running) deep link.
library;

import 'package:flutter/widgets.dart';

import '../../../shared/navigation/oracly_shell_bridge.dart';
import '../services/share_link_inbox.dart';
import '../services/share_link_opener.dart';
import '../services/share_link_parser.dart';

/// Must wrap [WidgetsApp] so it registers before the app's own observer:
/// otherwise the platform URI becomes a raw `pushNamed(uri.path)` and the
/// named-route table recovers unknown names by building a second shell.
class ShareLinkHost extends StatefulWidget {
  const ShareLinkHost({super.key, required this.child});

  final Widget child;

  @override
  State<ShareLinkHost> createState() => _ShareLinkHostState();
}

class _ShareLinkHostState extends State<ShareLinkHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) {
    final uri = ShareLinkParser.parse(routeInformation.uri.toString());
    if (uri != null) {
      ShareLinkInbox.instance.offer(uri);
      // Before the shell exists, Splash / the deletion gate drain the inbox
      // once the destination is committed.
      if (OraclyShellBridge.isActive) ShareLinkOpener.openPending();
    }
    // Malformed or unsupported links stay where the user is.
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
