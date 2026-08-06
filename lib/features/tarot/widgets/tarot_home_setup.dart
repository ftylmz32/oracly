/// OR-030 / OR-1030 — Tarot home setup panel: spreads, intention field, CTA.

library;



import 'package:flutter/material.dart';



import '../../../core/theme/app_colors.dart';

import '../../../core/theme/app_radius.dart';

import '../../../core/theme/app_spacing.dart';

import '../../../core/theme/app_text_styles.dart';

import 'tarot_section_heading.dart';

import 'tarot_shuffle_button.dart';

import 'tarot_spread_tile.dart';



class _SpreadOption {

  const _SpreadOption(this.title, this.icon);



  final String title;

  final IconData icon;

}



const _spreads = [

  _SpreadOption('Tek Kart', Icons.style_outlined),

  _SpreadOption('Üç Kart Açılımı', Icons.filter_3_outlined),

  _SpreadOption('Aşk', Icons.favorite_outline_rounded),

  _SpreadOption('Haftalık', Icons.calendar_today_outlined),

  _SpreadOption('Karma', Icons.all_inclusive_rounded),

  _SpreadOption('Kelt Haçı', Icons.grid_view_rounded),

];



/// Spread grid, intention input, and shuffle CTA.

class TarotHomeSetup extends StatelessWidget {

  const TarotHomeSetup({

    super.key,

    required this.onShuffle,

  });



  final VoidCallback onShuffle;



  @override

  Widget build(BuildContext context) {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [

        const TarotSectionHeading(title: 'Açılım Türleri'),

        SizedBox(height: AppSpacing.md),

        LayoutBuilder(

          builder: (context, constraints) {

            final width = constraints.maxWidth;

            final aspectRatio = width < 340 ? 1.22 : 1.32;



            return GridView.builder(

              shrinkWrap: true,

              physics: const NeverScrollableScrollPhysics(),

              itemCount: _spreads.length,

              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(

                crossAxisCount: 3,

                crossAxisSpacing: AppSpacing.sm,

                mainAxisSpacing: AppSpacing.sm,

                childAspectRatio: aspectRatio,

              ),

              itemBuilder: (context, index) {

                final spread = _spreads[index];

                return TarotSpreadTile(

                  title: spread.title,

                  icon: spread.icon,

                  selected: index == 0,

                );

              },

            );

          },

        ),

        SizedBox(height: AppSpacing.lg),

        TextField(

          readOnly: true,

          maxLines: 1,

          style: AppTextStyles.bodyMedium.copyWith(

            color: AppColors.textPrimary,

          ),

          decoration: InputDecoration(

            hintText: 'Niyetini yaz (isteğe bağlı)',

            hintStyle: AppTextStyles.bodySmall.copyWith(

              color: AppColors.textHint,

            ),

            filled: true,

            fillColor: AppColors.surface.withValues(alpha: 0.72),

            contentPadding: EdgeInsets.symmetric(

              horizontal: AppSpacing.md,

              vertical: AppSpacing.sm + AppSpacing.xs,

            ),

            border: OutlineInputBorder(

              borderRadius: AppRadius.md,

              borderSide: BorderSide(

                color: AppColors.gold.withValues(alpha: 0.22),

                width: AppBorderWidth.hairline,

              ),

            ),

            enabledBorder: OutlineInputBorder(

              borderRadius: AppRadius.md,

              borderSide: BorderSide(

                color: AppColors.matteBorder,

                width: AppBorderWidth.hairline,

              ),

            ),

            focusedBorder: OutlineInputBorder(

              borderRadius: AppRadius.md,

              borderSide: BorderSide(

                color: AppColors.gold.withValues(alpha: 0.55),

                width: AppBorderWidth.thin,

              ),

            ),

          ),

        ),

        SizedBox(height: AppSpacing.md),

        TarotShuffleButton(onPressed: onShuffle),

      ],

    );

  }

}


