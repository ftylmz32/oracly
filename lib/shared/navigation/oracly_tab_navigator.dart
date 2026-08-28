/// Per-tab navigator — created once, never rebuilt as a new route tree.
library;

import 'package:flutter/material.dart';

import '../../core/navigation/oracly_page_transitions.dart';
import '../../core/navigation/oracly_route_generator.dart';
import '../../core/navigation/oracly_routes.dart';

class OraclyTabNavigator extends StatelessWidget {
  const OraclyTabNavigator({
    super.key,
    required this.navigatorKey,
    required this.root,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget root;

  /// Shell roots belong on the root navigator — never nest another AppShell.
  static const blockedShellRoutes = <String>{
    OraclyRoutes.home,
    OraclyRoutes.profile,
    OraclyRoutes.coffee,
    OraclyRoutes.astrology,
    OraclyRoutes.starMap,
    OraclyRoutes.onboarding,
  };

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        final name = settings.name;
        if (name != null && blockedShellRoutes.contains(name)) {
          return OraclyPageTransitions.enter<void>(
            page: root,
            settings: settings,
          );
        }
        final generated = OraclyRouteGenerator.onGenerateRoute(settings);
        if (generated != null) return generated;
        return OraclyPageTransitions.enter<void>(
          page: root,
          settings: const RouteSettings(name: '/'),
        );
      },
      onGenerateInitialRoutes: (navigator, initialRoute) {
        return [
          OraclyPageTransitions.enter<void>(
            page: root,
            settings: const RouteSettings(name: '/'),
          ),
        ];
      },
    );
  }
}
