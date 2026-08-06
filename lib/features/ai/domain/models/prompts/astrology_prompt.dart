/// OR-1110 — Astrology AI prompt model.
library;

class AstrologyPrompt {
  const AstrologyPrompt({
    required this.zodiacSign,
    required this.question,
    this.birthDate,
    this.birthTime,
    this.birthPlace,
    this.locale = 'tr',
    this.personality = 'mystical',
  });

  final String zodiacSign;
  final String question;
  final DateTime? birthDate;
  final String? birthTime;
  final String? birthPlace;
  final String locale;
  final String personality;

  Map<String, dynamic> toContext() => {
        'domain': 'astrology',
        'zodiacSign': zodiacSign,
        'question': question,
        if (birthDate != null) 'birthDate': birthDate!.toIso8601String(),
        if (birthTime != null) 'birthTime': birthTime,
        if (birthPlace != null) 'birthPlace': birthPlace,
        'locale': locale,
        'personality': personality,
      };
}
