/// EPIC-011 — Executes pending daily-ritual draw intents on the tarot tab.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tarot/first_session/tarot_first_reading.dart';
import '../../tarot/navigation/tarot_navigator.dart';
import '../../tarot/shared/constants/tarot_routes.dart';
import '../../tarot/shared/tarot_scope.dart';
import '../services/daily_ritual_intent.dart';

/// Listens for cross-tab daily ritual intents inside [TarotScope].
///
/// First-reading intent is never auto-started here — Home CTA must be tapped.
///
/// Must push onto the nested Tarot [Navigator] via [navigatorKey]. This
/// widget sits *above* that navigator, so [Navigator.of] would hit the outer
/// app navigator and open deck-ready outside [TarotScope].
class DailyRitualTarotBridge extends ConsumerStatefulWidget {
  const DailyRitualTarotBridge({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  ConsumerState<DailyRitualTarotBridge> createState() =>
      _DailyRitualTarotBridgeState();
}

class _DailyRitualTarotBridgeState
    extends ConsumerState<DailyRitualTarotBridge> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeStartPendingFlow(),
    );
  }

  Future<void> _maybeStartPendingFlow() async {
    if (!DailyRitualIntent.hasPendingDraw) return;
    if (!mounted) return;

    final scope = TarotScope.maybeOf(context);
    if (scope == null) return;

    // Wait for restore so a stale active session cannot overwrite this draw.
    final ready = scope.restoreReady;
    if (ready != null) await ready;
    if (!mounted) return;
    if (!DailyRitualIntent.hasPendingDraw) return;

    await scope.reading.abandonActiveForNewStart();
    if (!DailyRitualIntent.consumePendingDraw()) return;
    if (!mounted) return;

    await TarotFirstReading.applySpread(ref, context);
    if (!mounted) return;

    final inner = widget.navigatorKey.currentState;
    if (inner == null) {
      debugPrint(
        '[DailyRitualTarotBridge] inner Tarot navigator not ready — '
        'cannot open deck selection',
      );
      return;
    }
    scope.flow.selectSpread(TarotFirstReading.spread);
    await TarotNavigator.pushNamedOn(inner, TarotRoutes.deckSelection);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
