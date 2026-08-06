/// OR-1110 — Daily energy AI prompt model.
library;

class DailyEnergyPrompt {
  const DailyEnergyPrompt({
    required this.date,
    required this.energyLevel,
    required this.moodLabel,
    this.zodiacSign,
    this.focusArea,
    this.locale = 'tr',
    this.personality = 'mystical',
  });

  final DateTime date;
  final double energyLevel;
  final String moodLabel;
  final String? zodiacSign;
  final String? focusArea;
  final String locale;
  final String personality;

  Map<String, dynamic> toContext() => {
        'domain': 'daily_energy',
        'date': date.toIso8601String(),
        'energyLevel': energyLevel,
        'moodLabel': moodLabel,
        if (zodiacSign != null) 'zodiacSign': zodiacSign,
        if (focusArea != null) 'focusArea': focusArea,
        'locale': locale,
        'personality': personality,
      };
}
