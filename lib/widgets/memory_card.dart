import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/memory_item.dart';


class MemoryCard extends StatelessWidget {

  final List<MemoryItem> memories;


  const MemoryCard({
    super.key,
    required this.memories,
  });



  @override
  Widget build(BuildContext context) {


    return Container(

      padding:
          const EdgeInsets.all(22),


      decoration:
          BoxDecoration(

        borderRadius:
            BorderRadius.circular(28),


        gradient:
            LinearGradient(

          colors: [

            AppColors.surface.withValues(
              alpha: .85,
            ),

            AppColors.primary.withValues(
              alpha: .12,
            ),

          ],

        ),


        border:
            Border.all(

          color:
              AppColors.glassBorder,

        ),


      ),


      child:
          Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,


        children: [


          Text(

            "🧠 Hafıza",

            style:
                AppTextStyles.heading,

          ),



          const SizedBox(
            height: 12,
          ),



          if (memories.isEmpty)

            Text(

              "Henüz seni tanımaya başlıyorum.",

              style:
                  AppTextStyles.subtitle,

            )

          else

            Text(

              memories.first.content,

              maxLines:
                  2,

              overflow:
                  TextOverflow.ellipsis,


              style:
                  AppTextStyles.body,

            ),



          const SizedBox(
            height: 12,
          ),



          Text(

            "${memories.length} bilgi hatırlanıyor",

            style:
                AppTextStyles.caption,

          ),


        ],

      ),

    );

  }

}