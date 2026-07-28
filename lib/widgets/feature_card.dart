import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';


class FeatureCard extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;


  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });


  @override
  Widget build(BuildContext context) {

    return Padding(

      padding:
          const EdgeInsets.only(bottom: 16),

      child: Material(

        color:
            Colors.transparent,

        child: InkWell(

          borderRadius:
              BorderRadius.circular(26),

          onTap:
              onTap,


          child: Ink(

            decoration:
                BoxDecoration(

              borderRadius:
                  BorderRadius.circular(26),


              gradient:
                  LinearGradient(

                colors: [

                  Colors.white.withValues(
                    alpha: .10,
                  ),

                  AppColors.surface.withValues(
                    alpha: .75,
                  ),

                ],

              ),


              border:
                  Border.all(

                color:
                    AppColors.glassBorder,

              ),


              boxShadow: [

                BoxShadow(

                  color:
                      AppColors.primary.withValues(
                        alpha: .10,
                      ),

                  blurRadius:
                      25,

                  spreadRadius:
                      1,

                ),

              ],

            ),


            child: Padding(

              padding:
                  const EdgeInsets.all(18),


              child: Row(

                children: [


                  Container(

                    width:
                        58,

                    height:
                        58,


                    decoration:
                        BoxDecoration(

                      borderRadius:
                          BorderRadius.circular(18),


                      gradient:
                          const LinearGradient(

                        colors: [

                          AppColors.primary,

                          AppColors.primaryLight,

                        ],

                      ),

                      boxShadow: [

                        BoxShadow(

                          color:
                              AppColors.primary.withValues(
                                alpha: .35,
                              ),

                          blurRadius:
                              18,

                        ),

                      ],

                    ),


                    child:
                        Icon(

                      icon,

                      color:
                          AppColors.white,

                      size:
                          28,

                    ),

                  ),



                  const SizedBox(
                    width: 16,
                  ),



                  Expanded(

                    child: Column(

                      crossAxisAlignment:
                          CrossAxisAlignment.start,


                      children: [


                        Text(

                          title,

                          style:
                              AppTextStyles.title,

                        ),



                        const SizedBox(
                          height: 5,
                        ),



                        Text(

                          subtitle,

                          style:
                              AppTextStyles.subtitle,

                        ),


                      ],

                    ),

                  ),



                  Icon(

                    Icons.arrow_forward_ios_rounded,

                    color:
                        AppColors.textSecondary,

                    size:
                        18,

                  ),


                ],

              ),

            ),

          ),

        ),

      ),

    );

  }

}