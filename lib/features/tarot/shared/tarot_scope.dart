/// OR-1170 — Provider scope for tarot controllers with persistence.
library;

import 'package:flutter/widgets.dart';

import '../../../core/data/datasources/local_storage.dart';
import '../controllers/tarot_flow_controller.dart';
import '../controllers/tarot_reading_controller.dart';
import '../data/repositories/tarot_reading_repository_impl.dart';
import '../domain/models/reading_session.dart';
import '../shared/constants/tarot_routes.dart';

/// Inherited controller bundle for the tarot ritual subtree.
class TarotScope extends InheritedWidget {
  const TarotScope({
    super.key,
    required this.flow,
    required this.reading,
    required super.child,
  });

  final TarotFlowController flow;
  final TarotReadingController reading;

  static TarotScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TarotScope>();
    assert(scope != null, 'TarotScope not found above context.');
    return scope!;
  }

  static TarotScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TarotScope>();
  }

  @override
  bool updateShouldNotify(TarotScope oldWidget) {
    return flow != oldWidget.flow || reading != oldWidget.reading;
  }
}

/// Root widget that wires tarot controllers for nested navigators.
class TarotModuleRoot extends StatefulWidget {
  const TarotModuleRoot({
    super.key,
    required this.storage,
    required this.child,
    this.navigatorKey,
  });

  final LocalStorage storage;
  final Widget child;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  State<TarotModuleRoot> createState() => _TarotModuleRootState();
}

class _TarotModuleRootState extends State<TarotModuleRoot> {
  late final TarotFlowController _flow;
  late final TarotReadingController _reading;

  @override
  void initState() {
    super.initState();
    _flow = TarotFlowController();
    _reading = TarotReadingController(
      repository: TarotReadingRepositoryImpl.fromStorage(widget.storage),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreSession());
  }

  Future<void> _restoreSession() async {
    await _reading.restoreActiveSession();
    if (!mounted) return;
    final session = _reading.session;
    if (session == null || session.status == ReadingSessionStatus.completed) {
      return;
    }
    _flow.selectSpread(session.spread);
    final route = _routeForStep(session.flowStep);
    widget.navigatorKey?.currentState?.pushNamedAndRemoveUntil(
      route,
      (route) => route.settings.name == TarotRoutes.home,
    );
  }

  String _routeForStep(ReadingFlowStep step) => switch (step) {
        ReadingFlowStep.deckSelection => TarotRoutes.deckSelection,
        ReadingFlowStep.shuffle => TarotRoutes.shuffle,
        ReadingFlowStep.cardSelection => TarotRoutes.cardSelection,
        ReadingFlowStep.reveal => TarotRoutes.cardReveal,
        ReadingFlowStep.reading => TarotRoutes.reading,
        ReadingFlowStep.completed => TarotRoutes.home,
      };

  @override
  void dispose() {
    _flow.dispose();
    _reading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TarotScope(
      flow: _flow,
      reading: _reading,
      child: widget.child,
    );
  }
}
