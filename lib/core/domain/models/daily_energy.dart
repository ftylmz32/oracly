/// OR-1100 — Daily cosmic energy model.
library;

class DailyEnergyModel {
  const DailyEnergyModel({
    required this.title,
    required this.description,
    required this.moodLabel,
    required this.energyLevel,
    required this.date,
    this.illustrationAsset,
  });

  final String title;
  final String description;
  final String moodLabel;
  final double energyLevel;
  final DateTime date;
  final String? illustrationAsset;
}
