/// OR-1170 — Cinematic card selection ritual screen.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/copy/resilience_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../domain/models/tarot_position.dart';
import '../../shared/constants/tarot_routes.dart';
import '../../shared/tarot_scope.dart';
import '../../theme/tarot_tokens.dart';
import '../animations/tarot_transition.dart';
import '../widgets/card_selection/card_selection_background.dart';
import '../widgets/card_selection/card_selection_deck.dart';
import '../widgets/card_selection/card_selection_header.dart';
import '../widgets/card_selection/sacred_moment.dart';
import 'card_reveal_screen.dart';

/// Face-down card picker — continues seamlessly from the shuffle ritual.
class CardSelectionScreen extends StatefulWidget {
  const CardSelectionScreen({super.key});

  @override
  State<CardSelectionScreen> createState() => _CardSelectionScreenState();
}

class _CardSelectionScreenState extends State<CardSelectionScreen>
    with TickerProviderStateMixin {
  int? _selectedIndex;
  late final AnimationController _screenFade;
  late final Animation<double> _screenOpacity;
  late final AnimationController _sacred;

  @override
  void initState() {
    super.initState();
    _screenFade = AnimationController(
      vsync: this,
      duration: TarotTokens.screenSettle,
    );
    _screenOpacity = Tween<double>(
      begin: TarotTokens.screenSettleOpacityBegin,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _screenFade,
      curve: TarotTokens.revealCurve,
    ));
    _screenFade.forward();
    _sacred = AnimationController(
      vsync: this,
      duration: SacredMoment.ritualDuration,
    );
  }

  @override
  void dispose() {
    _screenFade.dispose();
    _sacred.dispose();
    super.dispose();
  }

  Future<void> _selectCard(int index) async {
    if (_selectedIndex != null) return;
    setState(() => _selectedIndex = index);
    final sacredFuture = _sacred.forward(from: 0);
    final scope = TarotScope.of(context);

    try {
      await scope.reading.drawCard();
      final drawn = scope.reading.session?.currentCard;
      if (drawn != null && mounted) {
        await precacheImage(AssetImage(drawn.card.image), context);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _selectedIndex = null);
        _sacred.reset();
        OraclySnackBar.error(context, ResilienceCopy.cardDrawFailed);
      }
      return;
    }

    // Draw is the meaningful work — don't block navigation on the sacred pause.
    unawaited(sacredFuture);
    if (!mounted || _selectedIndex != index) return;
    Navigator.of(context).pushReplacement(
      cardRevealRitualRoute<void>(
        page: const CardRevealScreen(),
        settings: const RouteSettings(name: TarotRoutes.cardReveal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = TarotScope.of(context).reading.session;
    final position = session == null
        ? null
        : SpreadService.positionAt(
            session.spread,
            session.drawnCards.length,
          );
    final progress = session == null
        ? ''
        : '${session.drawnCards.length + 1}/${session.requiredCardCount}';

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: FadeTransition(
          opacity: _screenOpacity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedBuilder(
                animation: _sacred,
                builder: (context, _) {
                  final sacred = SacredMoment.progress(_sacred.value);
                  final breath = SacredMoment.breathHold(_sacred.value);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CardSelectionBackground(sacred: sacred),
                      if (sacred > 0.08)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: const Alignment(0, 0.22),
                                  radius: 0.92 - sacred * 0.08,
                                  colors: [
                                    AppColors.transparent,
                                    Colors.black.withValues(
                                      alpha: sacred * 0.38 + breath * 0.08,
                                    ),
                                  ],
                                  stops: const [0.38, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              SafeArea(
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _sacred,
                      builder: (context, _) {
                        return Opacity(
                          opacity: (1 -
                                  SacredMoment.chromeFade(_sacred.value) *
                                      0.88)
                              .clamp(0.0, 1.0),
                          child: CardSelectionHeader(
                            positionLabel: position?.labelTr,
                            progressLabel: progress,
                          ),
                        );
                      },
                    ),
                    const Spacer(flex: 1),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: TarotTokens.maxContentWidth,
                        ),
                        child: AnimatedBuilder(
                          animation: _sacred,
                          builder: (context, _) {
                            return CardSelectionDeck(
                              selectedIndex: _selectedIndex,
                              sacred: SacredMoment.progress(_sacred.value),
                              sacredLinear: _sacred.value,
                              onSelect: _selectCard,
                            );
                          },
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Smooth fade from the shuffle ritual into card selection.
PageRouteBuilder<T> cardSelectionRitualRoute<T>({
  required Widget page,
  RouteSettings? settings,
}) {
  return tarotRitualDepthHandoffRoute<T>(
    page: page,
    settings: settings,
    scaleBegin: TarotTokens.handoffScaleSelectionBegin,
  );
}
