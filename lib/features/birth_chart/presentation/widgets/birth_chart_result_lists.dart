/// Compact planet and house lists from the existing natal chart.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_glass_card.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/birth_chart_copy.dart';
import '../../models/aspect.dart';
import '../../models/house.dart';
import '../../models/planet.dart';
import '../../services/chart_insight_locale.dart';

Widget _glassList({required String title, required List<Widget> children}) {
  return OraclyGlassCard(
    padding: OraclyChrome.cardPadding,
    borderRadius: OraclyChrome.cardRadius,
    premium: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: OraclyChrome.sectionLabel()),
        SizedBox(height: AppSpacing.s8),
        ...children,
      ],
    ),
  );
}

class BirthChartPlanetsList extends StatelessWidget {
  const BirthChartPlanetsList({super.key, required this.planets});

  final List<Planet> planets;

  @override
  Widget build(BuildContext context) {
    if (planets.isEmpty) return const SizedBox.shrink();
    return _glassList(
      title: BirthChartCopy.planetsTitle,
      children: [
        for (final planet in planets)
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.s4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    planet.id.labeled(OraclyL10n.code),
                    style: ReadingTypography.bodySmall(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${planet.degree.round()}° ${ChartInsightLocale.signName(planet.sign)}',
                  style: ReadingTypography.bodySmall(
                    color: OraclyChrome.goldLight,
                  ),
                ),
                SizedBox(width: AppSpacing.s8),
                Text(
                  ChartInsightLocale.fill('birth.house_of', {
                    'n': '${planet.house}',
                  }),
                  style: ReadingTypography.footnote(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class BirthChartHousesList extends StatelessWidget {
  const BirthChartHousesList({super.key, required this.houses});

  final List<House> houses;

  @override
  Widget build(BuildContext context) {
    if (houses.isEmpty) return const SizedBox.shrink();
    return _glassList(
      title: BirthChartCopy.housesTitle,
      children: [
        for (var i = 0; i < houses.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.s4),
            child: Row(
              children: [
                Expanded(child: _HouseLine(house: houses[i])),
                if (i + 1 < houses.length)
                  Expanded(child: _HouseLine(house: houses[i + 1])),
              ],
            ),
          ),
      ],
    );
  }
}

class BirthChartAspectsList extends StatelessWidget {
  const BirthChartAspectsList({super.key, required this.aspects});

  final List<Aspect> aspects;

  @override
  Widget build(BuildContext context) {
    if (aspects.isEmpty) return const SizedBox.shrink();
    return _glassList(
      title: BirthChartCopy.aspectsTitle,
      children: [
        for (final aspect in aspects.take(8))
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.s4),
            child: Text(
              '${aspect.planetA.labeled(OraclyL10n.code)} · '
              '${aspect.type.labeled(OraclyL10n.code)} · '
              '${aspect.planetB.labeled(OraclyL10n.code)}',
              style: ReadingTypography.bodySmall(color: AppColors.textPrimary),
            ),
          ),
      ],
    );
  }
}

class _HouseLine extends StatelessWidget {
  const _HouseLine({required this.house});

  final House house;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${house.number}. ${ChartInsightLocale.signName(house.sign)}',
      style: ReadingTypography.bodySmall(color: AppColors.textPrimary),
    );
  }
}
