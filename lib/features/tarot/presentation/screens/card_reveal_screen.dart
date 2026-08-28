/// OR-1170 — Cinematic card reveal screen.
library;

import 'package:flutter/material.dart';

import '../../../../core/audio/oracly_feedback_gate.dart';
import '../../../../core/copy/reading_flow_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/oracly_reduced_motion.dart';
import '../../components/tarot_error_state.dart';
import '../../copy/tarot_polish_copy.dart';
import '../../domain/models/reading_session.dart';
import '../../shared/constants/tarot_routes.dart';
import '../../shared/tarot_scope.dart';
import '../../theme/tarot_tokens.dart';
import '../animations/tarot_transition.dart';
import '../widgets/card_reveal/card_reveal_experience.dart';
import '../widgets/card_reveal/card_reveal_spread.dart';
import '../widgets/card_reveal/reveal_sound_callbacks.dart';
import '../widgets/card_reveal/reveal_timeline.dart';
import '../widgets/tarot_flow_progress.dart';
import 'card_selection_screen.dart';
import 'reading_screen.dart';

/// Full cinematic reveal — continues from card selection.
class CardRevealScreen extends StatefulWidget {
  const CardRevealScreen({super.key, this.fromManualPick = false});

  /// When true, skip the pile-rise/flip — the pick already flipped on selection.
  final bool fromManualPick;

  @override
  State<CardRevealScreen> createState() => _CardRevealScreenState();
}

class _CardRevealScreenState extends State<CardRevealScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  RevealCardData? _data;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: TarotTokens.screenSettle,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyReducedMotion.playOnce(context, _enter);
    final drawn = TarotScope.of(context).reading.session?.currentCard;
    if (drawn != null) {
      _data = RevealCardData.fromDrawnCard(drawn);
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  String? _completionHint(BuildContext context) {
    final session = TarotScope.of(context).reading.session;
    if (session == null || !session.allCardsDrawn) return null;
    return TarotPolishCopy.revealComplete;
  }

  Future<void> _openNext() async {
    if (_opening) return;
    _opening = true;
    final reading = TarotScope.of(context).reading;
    try {
      await reading.advanceAfterReveal();
    } catch (_) {
      if (mounted) _opening = false;
      return;
    }
    if (!mounted) return;

    final session = reading.session;
    if (session != null && session.flowStep == ReadingFlowStep.reveal) {
      Navigator.of(context).pushReplacement(
        cardRevealRitualRoute<void>(
          page: const CardRevealScreen(),
          settings: const RouteSettings(name: TarotRoutes.cardReveal),
        ),
      );
      return;
    }

    if (session != null && !session.allCardsDrawn) {
      Navigator.of(context).pushReplacement(
        cardSelectionRitualRoute<void>(
          page: const CardSelectionScreen(),
          settings: const RouteSettings(name: TarotRoutes.cardSelection),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      readingRitualRoute<void>(
        page: const ReadingScreen(),
        settings: const RouteSettings(name: TarotRoutes.reading),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: TarotErrorState(
          message: ReadingFlowCopy.revealSessionMissing,
          onRetry: () => Navigator.of(context).pop(),
        ),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _opening = true;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: AnimatedBuilder(
          animation: _enter,
          builder: (context, child) {
            final enterT = TarotTokens.revealCurve.transform(
              _enter.value.clamp(0.0, 1.0),
            );
            final settleOpacity = TarotTokens.screenSettleOpacityBegin +
                (1.0 - TarotTokens.screenSettleOpacityBegin) * enterT;
            return Opacity(opacity: settleOpacity, child: child);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              CardRevealExperience(
                data: data,
                onContinue: _openNext,
                startProgress: widget.fromManualPick
                    ? RevealTimeline.flipEnd + 0.06
                    : 0,
                soundCallbacks: OraclyFeedbackGate.sound?.revealCallbacks ??
                    RevealSoundCallbacks.silent,
                completionHint: _completionHint(context),
              ),
              const SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: TarotFlowProgress(step: TarotRitualStep.reveal),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Smooth transition from card selection into reveal.
Route<T> cardRevealRitualRoute<T>({
  required Widget page,
  RouteSettings? settings,
}) {
  return tarotRitualDepthHandoffRoute<T>(
    page: page,
    settings: settings,
  );
}
