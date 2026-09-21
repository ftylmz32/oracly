/// OR-1170 — Tarot module root: controllers, restore, lifecycle.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/datasources/local_storage.dart';
import '../../ai/production/oracly_ai_providers.dart';
import '../../daily_ritual/services/daily_ritual_intent.dart';
import '../art/tarot_image_budget.dart';
import '../controllers/tarot_flow_controller.dart';
import '../controllers/tarot_reading_controller.dart';
import '../data/repositories/tarot_reading_repository_impl.dart';
import '../domain/models/reading_session.dart';
import '../interpretation/services/interpretation_engine.dart';
import '../services/tarot_interpretation_service.dart';
import '../shared/constants/tarot_routes.dart';
import 'tarot_interpretation_wiring.dart';
import 'tarot_scope.dart';

/// Root widget that wires tarot controllers for nested navigators.
class TarotModuleRoot extends ConsumerStatefulWidget {
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
  ConsumerState<TarotModuleRoot> createState() => _TarotModuleRootState();
}

class _TarotModuleRootState extends ConsumerState<TarotModuleRoot>
    with WidgetsBindingObserver {
  late final TarotFlowController _flow;
  late final TarotReadingController _reading;
  final Completer<void> _restoreReady = Completer<void>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    TarotImageBudget.enter();
    _flow = TarotFlowController();
    _reading = TarotReadingController(
      repository: TarotReadingRepositoryImpl.fromStorage(widget.storage),
      interpretationService: _buildInterpretationService(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _restoreSession();
      } finally {
        if (!_restoreReady.isCompleted) _restoreReady.complete();
      }
    });
  }

  TarotInterpretationService _buildInterpretationService() {
    final ai = ref.read(oraclyAiServiceProvider);
    return TarotInterpretationService(
      allowLocalFallback: ai.allowsLocalFallback,
      engine: InterpretationEngineFactory.create(
        cache: InMemoryInterpretationCache(),
        executor: tarotInterpretationExecutorFor(ai),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_reading.flush());
    }
  }

  Future<void> _restoreSession() async {
    if (DailyRitualIntent.hasPendingDraw) {
      await _reading.abandonActiveForNewStart();
      return;
    }
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
    ReadingFlowStep.cardSelection => TarotRoutes.shuffle,
    ReadingFlowStep.reveal => TarotRoutes.shuffle,
    ReadingFlowStep.reading => TarotRoutes.reading,
    ReadingFlowStep.completed => TarotRoutes.home,
  };

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    TarotImageBudget.leave();
    _flow.dispose();
    _reading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TarotScope(
      flow: _flow,
      reading: _reading,
      restoreReady: _restoreReady.future,
      child: widget.child,
    );
  }
}
