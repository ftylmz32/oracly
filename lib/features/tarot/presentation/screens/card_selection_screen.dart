/// OR-1170 — Cinematic card selection ritual screen.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/copy/resilience_copy.dart';
import '../../../../core/performance/oracly_decode_cache.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/oracly_reduced_motion.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../art/tarot_card_asset.dart';
import '../../controllers/tarot_deck_controller.dart';
import '../../domain/models/tarot_position.dart';
import '../../motion/tarot_cinematic_motion.dart';
import '../../shared/constants/tarot_routes.dart';
import '../../shared/tarot_scope.dart';
import '../../theme/tarot_tokens.dart';
import '../animations/tarot_transition.dart';
import '../widgets/card_reveal/card_reveal_spread.dart';
import '../widgets/card_selection/card_selection_background.dart';
import '../widgets/card_selection/card_selection_deck.dart';
import '../widgets/card_selection/card_selection_header.dart';
import '../widgets/card_selection/card_selection_pick_flip.dart';
import '../widgets/card_selection/card_selection_picks.dart';
import '../widgets/card_selection/sacred_moment.dart';
import 'card_reveal_screen.dart';

/// Face-down card picker — physical pick, extract, flip, then reveal.
class CardSelectionScreen extends StatefulWidget {
  const CardSelectionScreen({super.key});

  @override
  State<CardSelectionScreen> createState() => _CardSelectionScreenState();
}

class _CardSelectionScreenState extends State<CardSelectionScreen>
    with TickerProviderStateMixin {
  int? _selectedIndex;
  RevealCardData? _flipData;
  late final AnimationController _screenFade;
  late final Animation<double> _screenOpacity;
  late final AnimationController _sacred;
  late final AnimationController _flip;

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
    _sacred = AnimationController(
      vsync: this,
      duration: SacredMoment.ritualDuration,
    );
    _flip = AnimationController(
      vsync: this,
      duration: TarotCinematicMotion.flip,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyReducedMotion.playOnce(context, _screenFade);
  }

  @override
  void dispose() {
    _screenFade.dispose();
    _sacred.dispose();
    _flip.dispose();
    super.dispose();
  }

  Future<void> _selectCard(int index) async {
    if (_selectedIndex != null) return;
    setState(() => _selectedIndex = index);
    final reduced = OraclyReducedMotion.of(context);
    if (reduced) {
      _sacred.value = 1;
      _flip.value = 1;
    }
    final sacredFuture =
        reduced ? Future<void>.value() : _sacred.forward(from: 0);
    final extract = Future<void>.delayed(
      TarotCinematicMotion.of(
        context,
        TarotCinematicMotion.cardMove + TarotCinematicMotion.preFlip,
      ),
    );
    final scope = TarotScope.of(context);

    try {
      await scope.reading.drawCard(fanIndex: index);
      final drawn = scope.reading.session?.currentCard;
      if (drawn != null && mounted) {
        final cacheW = oraclyDecodeCachePx(
          168,
          MediaQuery.devicePixelRatioOf(context),
          maxPx: TarotCardAsset.fullCapPx,
        );
        await precacheImage(
          ResizeImage(
            AssetImage(TarotCardAsset.full(drawn.card.image)),
            width: cacheW,
          ),
          context,
        );
        if (!mounted) return;
        setState(() => _flipData = RevealCardData.fromDrawnCard(drawn));
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _selectedIndex = null;
          _flipData = null;
        });
        _sacred.reset();
        _flip.reset();
        OraclySnackBar.error(context, ResilienceCopy.cardDrawFailed);
      }
      return;
    }

    // Extract to center + slight pause — then physical flip.
    await extract;
    if (!mounted || _selectedIndex != index) return;
    if (_flipData != null && !reduced) {
      await _flip.forward(from: 0);
    }
    unawaited(sacredFuture);
    if (!mounted || _selectedIndex != index) return;
    Navigator.of(context).pushReplacement(
      cardRevealRitualRoute<void>(
        page: const CardRevealScreen(fromManualPick: true),
        settings: const RouteSettings(name: TarotRoutes.cardReveal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = TarotScope.of(context).reading.session;
    final deck = TarotScope.of(context).reading.deckController;
    final drawn = session?.drawnCards ?? const [];
    final requiredCount = session?.requiredCardCount ?? 3;
    final fanCount = deck.visibleFanCount.clamp(1, TarotDeckController.fanLimit);
    final position = session == null
        ? null
        : SpreadService.positionAt(
            session.spread,
            session.drawnCards.length,
          );

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
                            positionLabel: position?.label,
                            drawnCount: drawn.length,
                            requiredCount: requiredCount,
                          ),
                        );
                      },
                    ),
                    CardSelectionPicks(cards: drawn),
                    const Spacer(flex: 1),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: TarotTokens.maxContentWidth,
                        ),
                        child: AnimatedBuilder(
                          animation: Listenable.merge([_sacred, _flip]),
                          builder: (context, _) {
                            final flipping = _flip.value > 0.02;
                            return SizedBox(
                              height: 280,
                              child: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  CardSelectionDeck(
                                    selectedIndex: _selectedIndex,
                                    sacred:
                                        SacredMoment.progress(_sacred.value),
                                    sacredLinear: _sacred.value,
                                    onSelect: _selectCard,
                                    cardCount: fanCount,
                                    hideSelectedFace: flipping,
                                  ),
                                  if (_flipData != null && flipping)
                                    Positioned(
                                      bottom: 72,
                                      child: CardSelectionPickFlip(
                                        data: _flipData!,
                                        progress: _flip.value,
                                      ),
                                    ),
                                ],
                              ),
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

Route<T> cardSelectionRitualRoute<T>({
  required Widget page,
  RouteSettings? settings,
}) {
  return tarotRitualDepthHandoffRoute<T>(
    page: page,
    settings: settings,
    scaleBegin: TarotTokens.handoffScaleSelectionBegin,
  );
}
