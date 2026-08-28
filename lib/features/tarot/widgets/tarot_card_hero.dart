import 'package:flutter/material.dart';

import '../../../core/theme/oracly_quiet_motion.dart';
import '../../../core/theme/app_colors.dart';
import '../copy/tarot_l10n.dart';
import '../models/tarot_card.dart';
import 'tarot_result_card_art.dart';
import 'tarot_typography.dart';

/// Centered tarot card reveal with glowing aura — reading screen hero.
class TarotCardHero extends StatefulWidget {
  const TarotCardHero({
    super.key,
    required this.card,
    this.positionLabel,
  });

  final TarotCard card;
  final String? positionLabel;

  @override
  State<TarotCardHero> createState() => _TarotCardHeroState();
}

class _TarotCardHeroState extends State<TarotCardHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(
      context,
      _pulseController,
      reverse: true,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, reveal, child) {
        return Opacity(
          opacity: reveal,
          child: Transform.scale(
            scale: 0.92 + reveal * 0.08,
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.positionLabel != null) ...[
            Text(
              widget.positionLabel!.toUpperCase(),
              style: TarotTypography.captionMuted(size: 10),
            ),
            const SizedBox(height: 8),
          ],
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulse = 0.9 + _pulseController.value * 0.14;
              return SizedBox(
                height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Transform.scale(
                      scale: pulse,
                      child: _AuraLayer(
                        size: 220,
                        color: AppColors.primaryLight.withValues(alpha: 0.22),
                        blur: 48,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.94 + _pulseController.value * 0.08,
                      child: _AuraLayer(
                        size: 170,
                        color: AppColors.gold.withValues(alpha: 0.28),
                        blur: 36,
                      ),
                    ),
                    TarotCardArt(
                      image: widget.card.image,
                      height: 210,
                      width: 140,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Text(
            TarotL10n.cardNameOf(widget.card),
            textAlign: TextAlign.center,
            style: TarotTypography.cardTitleGold(size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            widget.card.summary.split('.').first,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TarotTypography.captionMuted(size: 12.5),
          ),
        ],
      ),
    );
  }
}

class _AuraLayer extends StatelessWidget {
  const _AuraLayer({
    required this.size,
    required this.color,
    required this.blur,
  });

  final double size;
  final Color color;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: blur, spreadRadius: 8),
        ],
      ),
    );
  }
}
