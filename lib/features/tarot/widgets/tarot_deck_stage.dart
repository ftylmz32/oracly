import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../animations/deck_shuffle_animation.dart';
import '../models/tarot_select_phase.dart';

class TarotDeckStage extends StatefulWidget {
  const TarotDeckStage({
    super.key,
    required this.phase,
    required this.spread,
    this.alignAnimation,
    this.onShuffleComplete,
  });

  final TarotSelectPhase phase;
  final int spread;
  final Animation<double>? alignAnimation;
  final VoidCallback? onShuffleComplete;

  @override
  State<TarotDeckStage> createState() => _TarotDeckStageState();
}

class _TarotDeckStageState extends State<TarotDeckStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idle;
  late final Animation<double> _float;
  late final Animation<double> _glow;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: -2.5, end: 2.5).animate(
      CurvedAnimation(parent: _idle, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: .12, end: .22).animate(
      CurvedAnimation(parent: _idle, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  Widget _back() => Container(
        width: 88,
        height: 152,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withValues(alpha: .5)),
        ),
        child: Icon(Icons.auto_awesome, color: AppColors.gold.withValues(alpha: .72), size: 28),
      );

  Widget _stack() => AnimatedBuilder(
        animation: _idle,
        builder: (_, _) => Transform.translate(
          offset: Offset(0, _float.value),
          child: DecoratedBox(
            decoration: BoxDecoration(boxShadow: [
              BoxShadow(color: AppColors.gold.withValues(alpha: _glow.value), blurRadius: 28),
            ]),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < 7; i++)
                  Transform.translate(offset: Offset(i * 3.0, -i * 2.0), child: _back()),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final canTap = widget.phase.canTapDeck;
    final style = AppTextStyles.caption.copyWith(
      color: AppColors.textSecondary.withValues(alpha: widget.phase.isBusy ? .95 : .78),
      letterSpacing: 0.3,
      height: 1.45,
    );
    Widget hint = Text(
      widget.phase.hintText(spread: widget.spread),
      textAlign: TextAlign.center,
      style: style,
    );
    if (widget.phase == TarotSelectPhase.aligning && widget.alignAnimation != null) {
      hint = FadeTransition(opacity: widget.alignAnimation!, child: hint);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 210,
          child: Center(
            child: RepaintBoundary(
              child: GestureDetector(
                onTapDown: canTap ? (_) => setState(() => _pressed = true) : null,
                onTapUp: canTap ? (_) => setState(() => _pressed = false) : null,
                onTapCancel: canTap ? () => setState(() => _pressed = false) : null,
                onTap: canTap ? () {} : null,
                child: AnimatedScale(
                  scale: canTap ? (_pressed ? 0.97 : 1) : 0.98,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: widget.phase == TarotSelectPhase.shuffling
                      ? DeckShuffleAnimation(onComplete: widget.onShuffleComplete ?? () {})
                      : _stack(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: KeyedSubtree(key: ValueKey(widget.phase), child: hint),
        ),
      ],
    );
  }
}
