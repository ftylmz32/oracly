import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import 'tarot_card_back_painter.dart';

class TarotCardShell extends StatelessWidget {
  const TarotCardShell({
    super.key,
    required this.child,
    this.width = 110,
    this.height = 186,
    this.radius = 28,
    this.faceUp = false,
    this.glow = true,
    this.thickGold = false,
  });

  final Widget child;
  final double width;
  final double height;
  final double radius;
  final bool faceUp;
  final bool glow;
  final bool thickGold;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: glow
            ? [
                ...AppShadows.soft,
                BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: faceUp ? 0.28 : 0.18),
                  blurRadius: faceUp ? 44 : 32,
                  spreadRadius: faceUp ? 4 : 2,
                ),
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: thickGold ? 0.35 : 0.12),
                  blurRadius: thickGold ? 32 : 20,
                  spreadRadius: thickGold ? 2 : 0,
                ),
              ]
            : AppShadows.soft,
      ),
      child: Container(
        padding: EdgeInsets.all(thickGold ? 2.5 : 1.2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.card, AppColors.backgroundSecondary, const Color(0xFF0A1020)],
          ),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: thickGold ? 0.85 : (faceUp ? 0.65 : 0.45)),
            width: thickGold ? 2.0 : 0.9,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 2),
          child: child,
        ),
      ),
    );
  }
}

class TarotCardBackFace extends StatelessWidget {
  const TarotCardBackFace({super.key, this.width = 110, this.height = 186, this.radius = 28});

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return TarotCardShell(
      width: width,
      height: height,
      radius: radius,
      child: CustomPaint(
        painter: TarotCardBackPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class TarotCardFace extends StatelessWidget {
  const TarotCardFace({
    super.key,
    required this.label,
    this.image,
    this.width = 110,
    this.height = 186,
    this.radius = 28,
  });

  final String label;
  final String? image;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return TarotCardShell(
      width: width,
      height: height,
      radius: radius,
      faceUp: true,
      thickGold: image != null,
      child: image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(radius - 2),
              child: Image.asset(
                image!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _labelFallback(),
              ),
            )
          : _labelFallback(),
    );
  }

  Widget _labelFallback() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.title.copyWith(fontSize: 14, color: AppColors.goldLight, height: 1.25),
        ),
      ),
    );
  }
}
