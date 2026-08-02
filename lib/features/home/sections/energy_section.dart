import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/glass_card.dart';
import '../services/spirit_pulse_service.dart';
import '../widgets/energy_orb.dart';

class EnergySection extends StatelessWidget {
  const EnergySection({super.key});

  @override
  Widget build(BuildContext context) {
    final pulse = const SpiritPulseService().getTodayPulse();

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Spirit Pulse',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.gold.withValues(alpha: .72),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bugünkü ruhsal durumun',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle.copyWith(
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: EnergyOrb(
              energy: pulse.energy,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _MetricsPanel(pulse: pulse),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Günün mesajı',
            style: AppTextStyles.bodyBold.copyWith(
              fontSize: 15,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            pulse.message,
            style: AppTextStyles.subtitle.copyWith(
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsPanel extends StatelessWidget {
  const _MetricsPanel({required this.pulse});

  final SpiritPulse pulse;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Aura', pulse.aura),
      ('Sezgi', pulse.intuition),
      ('Şans', pulse.luck),
      ('Ruh hali', pulse.mood),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.glass.withValues(alpha: .55),
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 0,
        runSpacing: 8,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _MetricCell(
              label: items[i].$1,
              value: items[i].$2,
            ),
            if (i < items.length - 1)
              Container(
                width: 1,
                height: 28,
                margin: const EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                color: AppColors.glassBorder,
              ),
          ],
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.small.copyWith(
            color: AppColors.textHint,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodyBold.copyWith(
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
