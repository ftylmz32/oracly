/// OR-1170 — Nested navigator hosting the full tarot ritual stack.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/first_session/first_session_scope.dart';
import '../../daily_ritual/widgets/daily_ritual_tarot_bridge.dart';
import '../navigation/tarot_navigator.dart';
import '../presentation/animations/tarot_transition.dart';
import '../shared/constants/tarot_routes.dart';
import '../shared/tarot_scope.dart';
import '../presentation/screens/tarot_home_screen.dart';

/// Wraps the tarot tab with its own navigator and controller scope.
class TarotModuleNavigator extends ConsumerStatefulWidget {
  const TarotModuleNavigator({super.key});

  @override
  ConsumerState<TarotModuleNavigator> createState() =>
      _TarotModuleNavigatorState();
}

class _TarotModuleNavigatorState extends ConsumerState<TarotModuleNavigator> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  Future<void> _onSystemBack() async {
    final inner = _navigatorKey.currentState;
    if (inner != null && await inner.maybePop()) return;
    if (!mounted) return;
    final outer = Navigator.of(context);
    if (outer.canPop()) await outer.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(localStorageProvider);
    final isFirstSession = ref.watch(isFirstSessionProvider).value ?? false;

    return TarotModuleRoot(
      storage: storage,
      navigatorKey: _navigatorKey,
      child: FirstSessionScope(
        isFirstSession: isFirstSession,
        child: DailyRitualTarotBridge(
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              _onSystemBack();
            },
            child: Navigator(
              key: _navigatorKey,
              onGenerateRoute: TarotNavigator.onGenerateRoute,
              initialRoute: TarotRoutes.home,
              onGenerateInitialRoutes: (navigator, initialRoute) {
                return [
                  tarotRitualRoute<void>(
                    page: const TarotHomeScreen(),
                    settings: const RouteSettings(name: TarotRoutes.home),
                  ),
                ];
              },
            ),
          ),
        ),
      ),
    );
  }
}
