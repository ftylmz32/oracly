/// EPIC-011 / RC-012 — Executes pending ritual intents on the tarot tab.

library;



import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import '../../../core/first_session/first_session_intent.dart';

import '../../../core/navigation/oracly_navigation_service.dart';

import '../../tarot/domain/models/tarot_spread.dart';

import '../../tarot/shared/tarot_scope.dart';

import '../services/daily_ritual_intent.dart';

import '../../../app/providers/app_providers.dart';



/// Listens for cross-tab daily ritual and first-session intents inside [TarotScope].

class DailyRitualTarotBridge extends ConsumerStatefulWidget {

  const DailyRitualTarotBridge({

    super.key,

    required this.child,

  });



  final Widget child;



  @override

  ConsumerState<DailyRitualTarotBridge> createState() =>

      _DailyRitualTarotBridgeState();

}



class _DailyRitualTarotBridgeState extends ConsumerState<DailyRitualTarotBridge> {

  @override

  void initState() {

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartPendingFlow());

  }



  Future<void> _maybeStartPendingFlow() async {

    final firstSession = FirstSessionIntent.consumePendingFirstReading();

    final dailyDraw = DailyRitualIntent.consumePendingDraw();

    if (!firstSession && !dailyDraw) return;

    if (!mounted) return;



    final scope = TarotScope.maybeOf(context);

    if (scope == null) return;



    scope.flow.selectSpread(TarotSpreadType.single);

    ref.read(selectedSpreadProvider.notifier).state =

        TarotSpreadType.single.label;

    await ref

        .read(tarotServiceProvider)

        .selectSpread(TarotSpreadType.single.label);

    if (!mounted) return;



    OraclyNavigationService.startTarotFlow(

      context,

      spreadType: TarotSpreadType.single.label,

    );

  }



  @override

  Widget build(BuildContext context) => widget.child;

}


