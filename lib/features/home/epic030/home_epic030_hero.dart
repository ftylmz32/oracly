/// EPIC-030 — Approved Home hero card (vertical focal composition).
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_layout.dart';
import '../../../core/design_system/app_radius.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/daily_energy/navigation/daily_energy_route.dart';
import '../../../features/daily_energy/widgets/daily_energy_moon_hero.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import 'home_epic030_spec.dart';
import 'home_epic030_surface.dart';

class HomeEpic030Hero extends StatelessWidget {
  const HomeEpic030Hero({
    super.key,
    this.energyPercent = 82,
    this.alignmentLabel = 'Yüksek Ruhsal Uyum',
    this.description =
        'Bugün sezgilerin güçleniyor. İç sesine güven ve adımlarını bilinçle at.',
    this.onActionPressed,
  });

  final int energyPercent;
  final String alignmentLabel;
  final String description;
  final VoidCallback? onActionPressed;

  static const String _label = 'BUGÜNÜN ENERJİSİ';

  @override
  Widget build(BuildContext context) {
    final moon = HomeEpic030Spec.moonSize(context);

    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: HomeEpic030Spec.heroWidth(context),
        child: HomeEpic030Surface(
          premium: true,
          borderRadius: HomeEpic030Spec.heroRadius,
          padding: HomeEpic030Spec.heroPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: DailyEnergyMoonHero(
                  width: moon,
                  height: moon,
                  enableHero: true,
                ),
              ),
              SizedBox(height: HomeEpic030Spec.heroMoonToLabel),
              Text(
                _label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.44),
                  letterSpacing: 1.6,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
              SizedBox(height: HomeEpic030Spec.heroLabelToPercent),
              _EnergyPercent(percent: energyPercent),
              SizedBox(height: HomeEpic030Spec.heroPercentToAlignment),
              Text(
                alignmentLabel,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.subtitle.copyWith(
                  fontSize: 14,
                  height: 1.55,
                  letterSpacing: 0.35,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.46),
                ),
              ),
              SizedBox(height: HomeEpic030Spec.heroAlignmentToBody),
              Text(
                description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.82),
                  height: 1.55,
                  letterSpacing: 0.15,
                ),
              ),
              SizedBox(height: HomeEpic030Spec.heroBodyToButton),
              Center(
                child: _DetailButton(
                  onPressed: onActionPressed ??
                      () => DailyEnergyDetailsRoute.open(
                            context,
                            summary: description,
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnergyPercent extends StatefulWidget {
  const _EnergyPercent({required this.percent});

  final int percent;

  @override
  State<_EnergyPercent> createState() => _EnergyPercentState();
}

class _EnergyPercentState extends State<_EnergyPercent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_breath.value);
        final glowAlpha = 0.18 + t * 0.14;
        final blur = 18.0 + t * 10;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Transform.scale(
              scale: 1.0 + t * 0.04,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.goldGlow.withValues(alpha: glowAlpha),
                      blurRadius: blur,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: AppColors.purpleGlow.withValues(alpha: 0.10 + t * 0.06),
                      blurRadius: blur * 1.4,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const SizedBox(width: 72, height: 72),
              ),
            ),
            Text(
              '${widget.percent}%',
              textAlign: TextAlign.center,
              style: AppTextStyles.hero.copyWith(
                fontSize: HomeEpic030Spec.heroPercentSize,
                height: 0.92,
                fontWeight: FontWeight.w200,
                letterSpacing: -2.4,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: AppColors.gold.withValues(alpha: 0.96),
                shadows: [
                  Shadow(
                    color: AppColors.goldGlow.withValues(alpha: 0.45),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DetailButton extends StatelessWidget {
  const _DetailButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onPressed,
      borderRadius: AppRadius.sm,
      glowShift: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: HomeEpic030Spec.heroButtonMinWidth,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.sm,
            color: AppColors.surface.withValues(alpha: 0.55),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldGlow.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: AppLayout.referencePrimaryButtonPadding,
            child: Text(
              'Detayını Gör',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.goldLight,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.45,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
