/// Listens for inbound share URIs after the first frame.
library;

import 'package:flutter/widgets.dart';

import '../services/share_link_inbox.dart';
import '../services/share_link_opener.dart';
import '../services/share_link_parser.dart';

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
    if (uri == null) return super.didPushRouteInformation(routeInformation);
    ShareLinkInbox.instance.offer(uri);
    ShareLinkOpener.openPending();
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
