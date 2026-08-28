/// Persistent single Tarot table — intention → spread → draw → reading.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/oracly_reduced_motion.dart';
import '../../shared/tarot_scope.dart';
import '../tarot_ritual_controller.dart';
import '../tarot_ritual_stage.dart';
import '../widgets/ritual_spread_slots.dart';
import 'card_flight_actor.dart';
import 'tarot_table_background.dart';
import 'tarot_table_deck_stage.dart';
import 'tarot_table_hint.dart';
import 'tarot_table_intent_overlay.dart';
import 'tarot_table_phase.dart';
import 'tarot_table_reading_overlay.dart';
import 'tarot_table_scene_state.dart';
import 'tarot_table_spread_overlay.dart';

class TarotTableScene extends ConsumerStatefulWidget {
  const TarotTableScene({super.key});

  @override
  ConsumerState<TarotTableScene> createState() => _TarotTableSceneState();
}

class _TarotTableSceneState extends ConsumerState<TarotTableScene>
    with TarotTableSceneActions {
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
    final total =
        TarotScope.maybeOf(context)?.reading.session?.spread.cardCount ??
            (spread?.cardCount ?? 1);
    final showFlight = phase == TarotTablePhase.draw ||
        phase == TarotTablePhase.reading ||
        (_ritual.visual.stage == TarotRitualStage.draw ||
            _ritual.visual.stage == TarotRitualStage.reveal ||
            _ritual.visual.stage == TarotRitualStage.place);

    return Scaffold(
      backgroundColor: const Color(0xFF05030A),
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
                    const SizedBox(height: 8),
                    Text(
                      'Tarot',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.gold.withValues(alpha: 0.9),
                        letterSpacing: 2.2,
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
                    if (total > 1 && _ritual.placed.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      RitualSpreadSlots(
                        placed: _ritual.placed,
                        totalSlots: total,
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
                        placeTarget: placeTargetFor(total),
                        onInteracted: () =>
                            setState(() => hintVisible = false),
                        onRequestDraw: requestDraw,
                        onFlightComplete: onFlightComplete,
                      ),
                    ),
                    if (phase == TarotTablePhase.draw)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
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
