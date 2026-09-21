/// Defense in depth for a route requested while the deletion gate is still
/// [AccountDeletionGatePhase.unresolved] — e.g. Navigator.pushNamed called
/// before the gate has resolved. Renders the neutral, brand-safe
/// [GateUnresolvedScreen] and LISTENS for the gate to resolve, then replays
/// the ORIGINAL requested route exactly once through the real route
/// generator — never a permanent black/neutral screen once the gate
/// resolves, and never a second, independent interpretation of "what should
/// this route show now" (the replay goes through the same
/// [OraclyRouteGenerator.onGenerateRoute] every other caller uses).
library;

import 'package:flutter/material.dart';

import '../auth/account_deletion_pending_state.dart';
import '../auth/presentation/gate_unresolved_screen.dart';
import 'oracly_route_generator.dart';

class DeferredGateRouteHost extends StatefulWidget {
  const DeferredGateRouteHost({super.key, required this.originalSettings});

  final RouteSettings originalSettings;

  @override
  State<DeferredGateRouteHost> createState() => _DeferredGateRouteHostState();
}

class _DeferredGateRouteHostState extends State<DeferredGateRouteHost> {
  bool _replayed = false;

  @override
  void initState() {
    super.initState();
    AccountDeletionPendingState.phase.addListener(_onPhaseChanged);
    _maybeReplay();
  }

  @override
  void dispose() {
    AccountDeletionPendingState.phase.removeListener(_onPhaseChanged);
    super.dispose();
  }

  void _onPhaseChanged() {
    if (!mounted) return;
    _maybeReplay();
  }

  void _maybeReplay() {
    if (_replayed) return;
    if (AccountDeletionPendingState.isUnresolved) return;
    _replayed = true;
    // Defer past this build/listener callback — Navigator mutation must not
    // happen synchronously inside a phase-change notification.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // The gate is no longer unresolved, so this can never again return an
      // unresolved-destination route — no risk of recursing back into
      // another DeferredGateRouteHost for the same settings.
      final route = OraclyRouteGenerator.onGenerateRoute(
        widget.originalSettings,
      );
      if (route == null) return;
      Navigator.of(context).pushReplacement(route);
    });
  }

  @override
  Widget build(BuildContext context) => const GateUnresolvedScreen();
}
