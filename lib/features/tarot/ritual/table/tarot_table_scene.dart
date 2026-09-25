/// Persistent single Tarot table — intention → spread → draw → reading.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/oracly_reduced_motion.dart';
import '../../shared/tarot_scope.dart';
import '../../theme/tarot_tokens.dart';
import '../tarot_ritual_controller.dart';
import '../widgets/ritual_spread_slots.dart';
import 'card_flight_actor.dart';
import 'tarot_table_actor_ownership.dart';
import 'tarot_table_background.dart';
import 'tarot_table_deck_stage.dart';
import 'tarot_table_hint.dart';
import 'tarot_table_intent_overlay.dart';
import 'tarot_table_phase.dart';
import 'tarot_table_reading_overlay.dart';
import 'tarot_table_scene_state.dart';
import 'tarot_table_settle_actions.dart';
import 'tarot_table_spread_overlay.dart';

class TarotTableScene extends ConsumerStatefulWidget {
  const TarotTableScene({super.key});

  @override
  ConsumerState<TarotTableScene> createState() => _TarotTableSceneState();
}

class _TarotTableSceneState extends ConsumerState<TarotTableScene>
    with TarotTableSceneActions, TarotTableSettleActions {
  late final TarotRitualController _ritual;
  final GlobalKey<CardFlightActorState> _flightKey =
      GlobalKey<CardFlightActorState>();

  @override
  TarotRitualController get ritual => _ritual;
  @override
  GlobalKey<CardFlightActorState> get flightKey => _flightKey;

  @override
  void initState() {
    super.initState();
    _ritual = TarotRitualController();
    WidgetsBinding.instance.addPostFrameCallback((_) => restoreIfNeeded());
  }

  @override
  void dispose() {
    _ritual.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spreadType =
        spread ?? TarotScope.maybeOf(context)?.reading.session?.spread;
    final total = spreadType?.cardCount ?? 1;
    final showFlight = TarotTableActorOwnership.ownsActiveCard(
      phase: phase,
      ritualStage: _ritual.visual.stage,
      cardCount: total,
      placedCount: _ritual.placed.length,
    );

    return Scaffold(
      backgroundColor: TarotTokens.tableVoid,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const TarotTableBackground(),
          SafeArea(
            child: AnimatedBuilder(
              animation: _ritual,
              builder: (context, _) {
                return Column(
                  children: [
                    const SizedBox(height: TarotTokens.tableTitleTopGap),
                    Text(
                      'Tarot',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.gold.withValues(alpha: 0.9),
                        letterSpacing: TarotTokens.tableTitleTracking,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TarotTableIntentOverlay(
                      selectedId: intentId,
                      receded: phase != TarotTablePhase.intention,
                      onSelected: onIntent,
                    ),
                    if (phase == TarotTablePhase.spread) ...[
                      const SizedBox(height: AppSpacing.md),
                      TarotTableSpreadOverlay(
                        selected: spread,
                        onSelected: onSpread,
                      ),
                    ],
                    if (total > 1 &&
                        spreadType != null &&
                        _ritual.placed.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      RitualSpreadSlots(
                        placed: _ritual.placed,
                        spread: spreadType,
                      ),
                    ],
                    Expanded(
                      child: TarotTableDeckStage(
                        ritual: _ritual,
                        phase: phase,
                        flightKey: _flightKey,
                        showFlight: showFlight &&
                            phase != TarotTablePhase.intention &&
                            phase != TarotTablePhase.spread &&
                            phase != TarotTablePhase.preparing,
                        reducedMotion: OraclyReducedMotion.of(context),
                        placeTarget: placeTargetFor(spreadType),
                        onInteracted: () =>
                            setState(() => hintVisible = false),
                        onRequestDraw: requestDraw,
                        onFlightComplete: onFlightComplete,
                      ),
                    ),
                    if (phase == TarotTablePhase.draw)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: TarotTokens.tableHintBottomInset,
                        ),
                        child: TarotTableHint(visible: hintVisible),
                      ),
                    if (phase == TarotTablePhase.reading && focusCard != null)
                      TarotTableReadingOverlay(
                        card: focusCard!,
                        onDeepen: deepen,
                        onAskOr: askOr,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
