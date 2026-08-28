/// OR-050 / EPIC-025 — Daily Energy Details navigation.
library;

import 'package:flutter/material.dart';

import '../../../core/navigation/oracly_page_transitions.dart';
import '../screens/daily_energy_details_screen.dart';

/// Legacy details screen — not on the live Home or Universe Map path.
abstract final class DailyEnergyDetailsRoute {
  DailyEnergyDetailsRoute._();

  static Future<void> open(
    BuildContext context, {
    String? summary,
  }) {
    return Navigator.of(context).push<void>(
      OraclyPageTransitions.enter(
        page: DailyEnergyDetailsScreen(summary: summary),
      ),
    );
  }
}
