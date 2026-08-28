/// EPIC-011 — Executes pending daily-ritual draw intents on the tarot tab.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/oracly_navigation_service.dart';
import '../../tarot/first_session/tarot_first_reading.dart';
import '../../tarot/shared/tarot_scope.dart';
import '../services/daily_ritual_intent.dart';

/// Listens for cross-tab daily ritual intents inside [TarotScope].
///
/// First-reading intent is never auto-started here — Home CTA must be tapped.
class DailyRitualTarotBridge extends ConsumerStatefulWidget {
  const DailyRitualTarotBridge({super.key, required this.child});

  final Widget child;

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
    final dailyDraw = DailyRitualIntent.consumePendingDraw();
    if (!dailyDraw) return;
    if (!mounted) return;

    final scope = TarotScope.maybeOf(context);
    if (scope == null) return;

    await TarotFirstReading.applySpread(ref, context);
    if (!mounted) return;

    OraclyNavigationService.startTarotFlow(
      context,
      spreadType: TarotFirstReading.spread.label,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
