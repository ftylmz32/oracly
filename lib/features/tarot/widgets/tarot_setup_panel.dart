import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/glass_card.dart';
import '../models/tarot_select_phase.dart';

class TarotSetupPanel extends StatelessWidget {
  const TarotSetupPanel({
    super.key,
    required this.intentionController,
    required this.spread,
    required this.phase,
    required this.onSpreadChanged,
    required this.onShuffle,
  });

  final TextEditingController intentionController;
  final int spread;
  final TarotSelectPhase phase;
  final ValueChanged<int> onSpreadChanged;
  final VoidCallback onShuffle;

  @override
  Widget build(BuildContext context) {
    final enabled = phase.canEditSetup;
    final busy = phase.isBusy;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Niyetin',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.gold.withValues(alpha: .72),
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: intentionController,
            enabled: enabled,
            maxLines: 3,
            style: AppTextStyles.body.copyWith(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Bugün neyi öğrenmek istiyorsun?',
              hintStyle: AppTextStyles.subtitle.copyWith(
                color: AppColors.textSecondary.withValues(alpha: .55),
              ),
              filled: true,
              fillColor: AppColors.background.withValues(alpha: .55),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Açılım',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.gold.withValues(alpha: .72),
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _spreadChip(1, '1 Kart', enabled),
              const SizedBox(width: 10),
              _spreadChip(3, '3 Kart', enabled),
              const SizedBox(width: 10),
              _spreadChip(10, '10 Kart', enabled),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: enabled && !busy ? onShuffle : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: enabled && !busy
                    ? AppColors.gold
                    : AppColors.surface,
                foregroundColor: enabled && !busy
                    ? Colors.black
                    : AppColors.textSecondary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                busy ? 'Karıştırılıyor...' : 'Kartları Karıştır',
                style: AppTextStyles.button.copyWith(
                  color: enabled && !busy
                      ? Colors.black
                      : AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _spreadChip(int value, String label, bool enabled) {
    final active = spread == value;

    return Expanded(
      child: GestureDetector(
        onTap: enabled ? () => onSpreadChanged(value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? AppColors.gold.withValues(alpha: .92)
                : AppColors.background.withValues(alpha: .45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active
                  ? AppColors.gold
                  : AppColors.glassBorder,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.small.copyWith(
              color: active ? Colors.black : AppColors.textSecondary,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
