/// OR-1120 — Astrology feature entry.
library;

import 'package:flutter/material.dart';

import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/feature_hub_screen.dart';

class AstrologyScreen extends StatefulWidget {
  const AstrologyScreen({super.key});

  @override
  State<AstrologyScreen> createState() => _AstrologyScreenState();
}

class _AstrologyScreenState extends State<AstrologyScreen> {
  String _sign = 'Koç';

  static const _signs = [
    'Koç', 'Boğa', 'İkizler', 'Yengeç', 'Aslan', 'Başak',
    'Terazi', 'Akrep', 'Yay', 'Oğlak', 'Kova', 'Balık',
  ];

  String _horoscopeFor(String sign) {
    return '$sign burcu için bugün: İçsel denge ve net iletişim ön planda. '
        'Venüs enerjisi ilişkilerinde sıcak bir kapı aralıyor; '
        'kariyerde sabırlı adımlar seni hedefe yaklaştırıyor.';
  }

  @override
  Widget build(BuildContext context) {
    return FeatureHubScreen(
      title: 'Astroloji',
      headline: 'Gökyüzünün rehberliği',
      description:
          'Burç yorumları, transitler ve kişisel harita öngörüleri.',
      icon: Icons.auto_awesome,
      primaryLabel: 'Günlük Yorumu Oku',
      onPrimary: () {},
      secondaryLabel: 'AI Oracle ile Konuş',
      onSecondary: () {
        Navigator.of(context).pop();
        OraclyNavigationService.openChat(context);
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Burcunu Seç',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.goldLight,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _signs.map((sign) {
              final selected = sign == _sign;
              return ChoiceChip(
                label: Text(sign),
                selected: selected,
                onSelected: (_) => setState(() => _sign = sign),
                selectedColor: AppColors.gold.withValues(alpha: 0.35),
                backgroundColor: AppColors.surface.withValues(alpha: 0.65),
                labelStyle: AppTextStyles.labelMedium.copyWith(
                  color: selected ? AppColors.goldLight : AppColors.textSecondary,
                ),
                side: BorderSide(
                  color: AppColors.gold.withValues(alpha: selected ? 0.55 : 0.2),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: AppSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.lg,
              color: AppColors.surfaceElevated.withValues(alpha: 0.88),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.25),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text(
                _horoscopeFor(_sign),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
