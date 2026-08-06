/// OR-1170 — Nested navigator hosting the full tarot ritual stack.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/first_session/first_session_scope.dart';
import '../../daily_ritual/widgets/daily_ritual_tarot_bridge.dart';
import '../navigation/tarot_navigator.dart';
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
          child: Navigator(
            key: _navigatorKey,
            onGenerateRoute: TarotNavigator.onGenerateRoute,
            initialRoute: TarotRoutes.home,
            onGenerateInitialRoutes: (navigator, initialRoute) {
              return [
                MaterialPageRoute<void>(
                  settings: const RouteSettings(name: TarotRoutes.home),
                  builder: (_) => const TarotHomeScreen(),
                ),
              ];
            },
          ),
        ),
      ),
    );
  }
}
