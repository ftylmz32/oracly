import 'package:flutter/material.dart';

import '../../../shared/widgets/oracly_pressable.dart';
import '../animations/card_flip_animation.dart';
import '../animations/deck_shuffle_animation.dart';
import '../models/tarot_card.dart';
import '../models/tarot_select_phase.dart';
import 'tarot_card_shell.dart';
import 'tarot_fanned_deck.dart';
import 'tarot_typography.dart';

class TarotDeckStage extends StatefulWidget {
  const TarotDeckStage({
    super.key,
    required this.phase,
    required this.spread,
    required this.drawnCount,
    this.activeCard,
    this.alignAnimation,
    this.onShuffleComplete,
    this.onDeckTap,
    this.onFlipComplete,
  });

  final TarotSelectPhase phase;
  final int spread;
  final int drawnCount;
  final TarotCard? activeCard;
  final Animation<double>? alignAnimation;
  final VoidCallback? onShuffleComplete;
  final VoidCallback? onDeckTap;
  final VoidCallback? onFlipComplete;

  @override
  State<TarotDeckStage> createState() => _TarotDeckStageState();
}

class _TarotDeckStageState extends State<TarotDeckStage> {
  static const _cardW = 118.0;
  static const _cardH = 198.0;
  static const _radius = 28.0;

  Widget _deckContent() {
    final card = widget.activeCard;
    if (widget.phase == TarotSelectPhase.drawing && card != null) {
      return CardDrawAnimation(
        card: card,
        width: _cardW,
        height: _cardH,
        radius: _radius,
        onFlipComplete: widget.onFlipComplete ?? () {},
      );
    }
    if (widget.phase == TarotSelectPhase.holding && card != null) {
      return TarotRevealedCard(card: card, width: _cardW, height: _cardH, radius: _radius);
    }
    if (widget.phase == TarotSelectPhase.shuffling) {
      return DeckShuffleAnimation(
        onComplete: widget.onShuffleComplete ?? () {},
        cardBuilder: (_, i, c) => const TarotCardBackFace(width: _cardW, height: _cardH, radius: _radius),
      );
    }
    return TarotFannedDeck(opacity: widget.phase.isBusy ? 0.45 : 1);
  }

  Widget _caption() {
    if (widget.phase.canTapDeck || widget.phase == TarotSelectPhase.idle) {
      return Text(
        'Kartlarına odaklan, enerjini hisset ve kartları seç.',
        textAlign: TextAlign.center,
        style: TarotTypography.captionMuted(size: 13),
      );
    }
    final text = widget.phase.hintText(spread: widget.spread, drawnCount: widget.drawnCount);
    final child = Text(text, key: ValueKey(text), textAlign: TextAlign.center, style: TarotTypography.captionMuted());
    if (widget.phase == TarotSelectPhase.aligning && widget.alignAnimation != null) {
      return FadeTransition(opacity: widget.alignAnimation!, child: child);
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    final canTap = widget.phase.canTapDeck;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OraclyPressable(
          onTap: canTap ? widget.onDeckTap : null,
          enabled: canTap,
          child: SizedBox(height: 210, child: Center(child: _deckContent())),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(duration: const Duration(milliseconds: 450), child: _caption()),
      ],
    );
  }
}
