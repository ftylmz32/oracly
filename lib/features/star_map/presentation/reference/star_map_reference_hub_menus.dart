/// Hub menu items for Yıldızname — extracted to keep the screen lean.
library;

import 'package:flutter/material.dart';

import '../../../../features/birth_chart/models/birth_profile.dart';
import '../../copy/star_map_polish_copy.dart';
import '../../models/star_map_reading.dart';
import 'star_map_reference_menu_cards.dart';
import 'star_map_reference_routes.dart';

abstract final class StarMapReferenceHubMenus {
  StarMapReferenceHubMenus._();

  static List<StarMapReferenceMenuItem> build({
    required BuildContext context,
    required StarMapReading reading,
    required BirthProfile? profile,
    required VoidCallback onRefresh,
  }) {
    return [
      StarMapReferenceMenuItem(
        title: StarMapPolishCopy.birthChartTitle,
        icon: Icons.brightness_5_rounded,
        subtitle: StarMapPolishCopy.birthChartHint,
        onTap: () => StarMapReferenceRoutes.openBirthChart(
          context,
          onReturn: onRefresh,
        ),
      ),
      StarMapReferenceMenuItem(
        title: StarMapPolishCopy.skyMessageTitle,
        icon: Icons.auto_awesome_rounded,
        subtitle: StarMapPolishCopy.skyMessageHint,
        onTap: () => StarMapReferenceRoutes.openSkyMessage(
          context,
          reading,
          profile: profile,
        ),
      ),
      StarMapReferenceMenuItem(
        title: StarMapPolishCopy.karmicTitle,
        icon: Icons.blur_circular_rounded,
        subtitle: StarMapPolishCopy.karmicHint,
        onTap: () => StarMapReferenceRoutes.openKarmic(
          context,
          reading,
          profile: profile,
        ),
      ),
      StarMapReferenceMenuItem(
        title: StarMapPolishCopy.planetsTitle,
        icon: Icons.public_rounded,
        subtitle: StarMapPolishCopy.planetsHint,
        onTap: () => StarMapReferenceRoutes.openPlanets(
          context,
          reading,
          profile: profile,
        ),
      ),
    ];
  }
}
