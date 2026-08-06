/// OR-020.1 — Central tab navigation for the Oracly app shell.
library;

import 'package:flutter/material.dart';

import '../../core/navigation/oracly_route_generator.dart';
import '../../features/home/home_page.dart';
import '../../features/tarot/navigation/tarot_module_navigator.dart';
import '../../features/companion/presentation/screens/companion_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../widgets/oracly_bottom_bar.dart';

/// Primary bottom navigation destinations.
enum OraclyTab {
  home,
  tarot,
  chat,
  profile;

  static OraclyTab fromIndex(int index) => OraclyTab.values[index];
}

/// Inherited tab controller — feature widgets switch tabs without duplicating routes.
class OraclyNavigationScope extends InheritedWidget {
  const OraclyNavigationScope({
    super.key,
    required this.currentIndex,
    required this.switchToTab,
    required super.child,
  });

  final int currentIndex;
  final ValueChanged<int> switchToTab;

  static OraclyNavigationScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<OraclyNavigationScope>();
    assert(scope != null, 'OraclyNavigationScope not found in widget tree.');
    return scope!;
  }

  static OraclyNavigationScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<OraclyNavigationScope>();
  }

  @override
  bool updateShouldNotify(OraclyNavigationScope oldWidget) {
    return currentIndex != oldWidget.currentIndex;
  }
}

/// Convenience API for switching tabs from feature entry points.
abstract final class OraclyNavigation {
  OraclyNavigation._();

  static void switchToTab(BuildContext context, OraclyTab tab) {
    final scope = OraclyNavigationScope.maybeOf(context);
    if (scope == null) return;
    scope.switchToTab(tab.index);
  }
}

/// Root shell — preserves tab state and exposes one shared bottom bar.
class OraclyAppShell extends StatefulWidget {
  const OraclyAppShell({
    super.key,
    this.initialTab = OraclyTab.home,
  });

  final OraclyTab initialTab;

  @override
  State<OraclyAppShell> createState() => _OraclyAppShellState();
}

class _OraclyAppShellState extends State<OraclyAppShell> {
  late int _currentIndex = widget.initialTab.index;

  late final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List.generate(OraclyTab.values.length, (_) => GlobalKey<NavigatorState>());

  static const List<Widget> _roots = [
    HomePage(),
    TarotModuleNavigator(),
    CompanionScreen(),
    ProfileScreen(),
  ];

  void _onDestinationSelected(int index) {
    if (_currentIndex == index) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _currentIndex = index);
  }

  Future<bool> _onWillPop() async {
    final navigator = _navigatorKeys[_currentIndex].currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return OraclyNavigationScope(
      currentIndex: _currentIndex,
      switchToTab: _onDestinationSelected,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _onWillPop();
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            fit: StackFit.expand,
            children: [
              for (var i = 0; i < _roots.length; i++)
                IgnorePointer(
                  ignoring: _currentIndex != i,
                  child: AnimatedOpacity(
                    opacity: _currentIndex == i ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    child: _TabNavigator(
                      navigatorKey: _navigatorKeys[i],
                      root: _roots[i],
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: OraclyBottomBar(
            currentIndex: _currentIndex,
            onDestinationSelected: _onDestinationSelected,
          ),
        ),
      ),
    );
  }
}

class _TabNavigator extends StatelessWidget {
  const _TabNavigator({
    required this.navigatorKey,
    required this.root,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget root;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        final generated = OraclyRouteGenerator.onGenerateRoute(settings);
        if (generated != null) return generated;

        return MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/'),
          builder: (_) => root,
        );
      },
      onGenerateInitialRoutes: (navigator, initialRoute) {
        return [
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: '/'),
            builder: (_) => root,
          ),
        ];
      },
    );
  }
}
