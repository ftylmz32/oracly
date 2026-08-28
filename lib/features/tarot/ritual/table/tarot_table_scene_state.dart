/// State logic for [TarotTableScene].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/oracly_reduced_motion.dart';
import '../../../ai/oracle_conversation/navigation/oracle_conversation_route.dart';
import '../../domain/models/tarot_spread.dart';
import '../../first_session/tarot_first_reading.dart';
import '../../presentation/screens/reading_screen.dart';
import '../../presentation/widgets/card_reveal/card_reveal_spread.dart';
import '../../shared/constants/tarot_routes.dart';
import '../../shared/tarot_scope.dart';
import '../tarot_ritual_controller.dart';
import 'card_flight_actor.dart';
import 'tarot_table_custom_intent.dart';
import 'tarot_table_flow.dart';
import 'tarot_table_phase.dart';
import 'tarot_table_scene.dart';

mixin TarotTableSceneActions on ConsumerState<TarotTableScene> {
  TarotRitualController get ritual;
  GlobalKey<CardFlightActorState> get flightKey;

  TarotTablePhase phase = TarotTablePhase.intention;
  String? intentId;
  TarotSpreadType? spread;
  bool hintVisible = true;
  bool starting = false;
  RevealCardData? focusCard;

  Future<void> restoreIfNeeded() async {
    if (!mounted) return;
    final session = TarotScope.maybeOf(context)?.reading.session;
    if (session == null) return;
    setState(() => phase = TarotTablePhase.draw);
    await ritual.bootstrap(context);
  }

  Future<void> onIntent(String id) async {
    setState(() => intentId = id);
    if (id == 'custom') {
      final text = await showTarotCustomIntentDialog(context);
      if (!mounted) return;
      if (text == null) {
        setState(() => intentId = null);
        return;
      }
      TarotTableFlow.captureCustomIntention(context, text);
    } else {
      TarotTableFlow.captureTopicIntention(context, id);
    }
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    if (TarotFirstReading.shouldUseFirstSpread(context, ref)) {
      await onSpread(TarotFirstReading.spread);
      return;
    }
    setState(() => phase = TarotTablePhase.spread);
  }

  Future<void> onSpread(TarotSpreadType value) async {
    if (starting) return;
    setState(() {
      spread = value;
      starting = true;
    });
    final ok = await TarotTableFlow.startSession(
      context: context,
      ref: ref,
      spread: value,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => starting = false);
      return;
    }
    setState(() => phase = TarotTablePhase.preparing);
    if (!OraclyReducedMotion.of(context)) {
      await Future<void>.delayed(const Duration(milliseconds: 220));
    }
    if (!mounted) return;
    await ritual.prepareQuickly(context);
    if (!mounted) return;
    setState(() {
      phase = TarotTablePhase.draw;
      starting = false;
    });
  }

  Future<RevealCardData?> requestDraw() async {
    final ok = await ritual.commitDraw(context);
    if (!ok) return null;
    return ritual.active;
  }

  Future<void> onFlightComplete(RevealCardData data) async {
    // Domain settle — reading stays on table (no pushReplacement).
    final ready = await ritual.settleAfterReveal(context);
    if (!mounted) return;
    if (ready) {
      setState(() {
        phase = TarotTablePhase.reading;
        focusCard = data;
      });
      return;
    }
    // Same actor resets for next draw — identity preserved.
    flightKey.currentState?.resetForNextDraw();
    setState(() {});
  }

  Offset? placeTargetFor(int totalSlots) {
    if (totalSlots <= 1) return null;
    final index = ritual.placed.length; // next slot
    final spacing = 82.0;
    final origin = -((totalSlots - 1) * spacing) / 2;
    return Offset(origin + index * spacing, -210);
  }

  void deepen() {
    // Explicit expand only — never automatic route replacement on reveal.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: TarotRoutes.reading),
        builder: (_) => const ReadingScreen(),
      ),
    );
  }

  void askOr() {
    final session = TarotScope.of(context).reading.session;
    final focus = focusCard;
    if (session == null || focus == null) return;
    openOracleConversation(
      context,
      readingContext: TarotTableFlow.buildOrContext(
        session: session,
        focus: focus,
      ),
    );
  }
}
