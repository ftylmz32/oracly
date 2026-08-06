import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/memory_item.dart';
import '../widgets/luxury_glass_surface.dart';

class MemorySection extends StatelessWidget {
  const MemorySection({super.key, required this.memories});

  final List<MemoryItem> memories;

  @override
  Widget build(BuildContext context) {
    final content = memories.isNotEmpty
        ? memories.first.content
        : 'Your story has not yet been written here.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Memory',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.4),
              letterSpacing: 2.0,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          LuxuryGlassSurface(
            elevated: true,
            padding: const EdgeInsets.fromLTRB(32, 36, 32, 38),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'I remember\nwhat matters.',
                  style: AppTextStyles.hero.copyWith(
                    fontSize: 26,
                    height: 1.18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  content,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    height: 1.8,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.08,
                    color: Colors.white.withValues(alpha: 0.50),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '— Oracly',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    letterSpacing: 1.4,
                    color: AppColors.gold.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
