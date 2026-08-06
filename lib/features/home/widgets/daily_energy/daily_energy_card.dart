/// OR-004.5 / OR-026 / OR-050 — Daily energy card assembly.

library;



import 'package:flutter/material.dart';



import '../../../../core/theme/app_radius.dart';

import '../../../../core/theme/app_spacing.dart';

import '../../../../shared/widgets/oracly_card.dart';

import '../../../daily_energy/daily_energy_constants.dart';

import '../../../daily_energy/navigation/daily_energy_route.dart';

import 'energy_action.dart';

import 'energy_constants.dart';

import 'energy_description.dart';

import 'energy_illustration.dart';

import 'energy_title.dart';

import '../../theme/home_architecture.dart';



/// Composes daily energy card sections — premium surface, same layout.

class DailyEnergyCard extends StatelessWidget {

  const DailyEnergyCard({

    super.key,

    required this.description,

    this.onActionPressed,

  });



  final String description;

  final VoidCallback? onActionPressed;



  /// Fixed illustration slot — card owns height, not the [Row].

  static const double _illustrationHeight =

      AppSpacing.xxl + AppSpacing.xxl + AppSpacing.xl + AppSpacing.md + 4;



  @override

  Widget build(BuildContext context) {

    return DecoratedBox(

      decoration: EnergyDecorations.shell,

      child: OraclyCard(

        showBorder: false,

        showShadow: false,

        clipBehavior: Clip.none,

        gradient: EnergyDecorations.cardSurface,

        padding: EdgeInsets.only(

          left: AppSpacing.insetCard + AppSpacing.xs,

          right: 0,

          top: AppSpacing.insetCard,

          bottom: AppSpacing.insetCard + 2,

        ),

        child: Stack(

          clipBehavior: Clip.none,

          children: [

            Positioned.fill(

              child: HomeArchitectureOverlay(

                borderRadius: AppRadius.lg,

                proximity: HomeOrbProximity.medium,

                detail: HomeSurfaceDetail.standard,

              ),

            ),

            Positioned.fill(

              child: ClipRRect(

                borderRadius: AppRadius.lg,

                child: Stack(

                  children: [

                    const Positioned.fill(

                      child: DecoratedBox(

                        decoration: BoxDecoration(

                          gradient: EnergyDecorations.innerVignette,

                        ),

                      ),

                    ),

                    const Positioned.fill(

                      child: DecoratedBox(

                        decoration: BoxDecoration(

                          gradient: EnergyDecorations.innerEdgeShadow,

                        ),

                      ),

                    ),

                  ],

                ),

              ),

            ),

            Row(

              crossAxisAlignment: CrossAxisAlignment.center,

              children: [

                Expanded(

                  flex: 6,

                  child: Padding(

                    padding: EdgeInsets.only(right: AppSpacing.xs),

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      mainAxisSize: MainAxisSize.min,

                      children: [

                        const EnergyTitle(),

                        SizedBox(height: EnergySpacing.titleToBody),

                        EnergyDescription(description: description),

                        SizedBox(height: EnergySpacing.bodyToAction),

                        EnergyAction(

                          onPressed: onActionPressed ??

                              () => DailyEnergyDetailsRoute.open(

                                    context,

                                    summary: description,

                                  ),

                        ),
                      ],

                    ),

                  ),

                ),

                Expanded(

                  flex: 4,

                  child: SizedBox(

                    height: _illustrationHeight,

                    child: Hero(

                      tag: DailyEnergyHeroTags.moonIllustration,

                      child: Material(

                        type: MaterialType.transparency,

                        child: const EnergyIllustration(),

                      ),

                    ),

                  ),

                ),

              ],

            ),

          ],

        ),

      ),

    );

  }

}

