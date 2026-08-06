/// OR-1160 — Domain-specific prompt builder input DTOs.
library;

class TarotPromptInput {
  const TarotPromptInput({
    required this.spreadType,
    required this.intention,
    required this.cardsSummary,
    this.reversedSummary,
    this.cardIds = const [],
  });

  final String spreadType;
  final String intention;
  final String cardsSummary;
  final String? reversedSummary;
  final List<int> cardIds;

  Map<String, dynamic> toVariables() => {
        'spreadType': spreadType,
        'intention': intention,
        'cardsSummary': cardsSummary,
        if (reversedSummary != null) 'reversedSummary': reversedSummary,
      };
}

class DreamPromptInput {
  const DreamPromptInput({
    required this.dreamText,
    this.emotions = const [],
    this.symbols = const [],
  });

  final String dreamText;
  final List<String> emotions;
  final List<String> symbols;

  Map<String, dynamic> toVariables() => {
        'dreamText': dreamText,
        if (emotions.isNotEmpty) 'emotions': emotions,
        if (symbols.isNotEmpty) 'symbols': symbols,
      };
}

class AstrologyPromptInput {
  const AstrologyPromptInput({
    required this.zodiacSign,
    required this.question,
    this.birthDate,
    this.birthTime,
    this.birthPlace,
  });

  final String zodiacSign;
  final String question;
  final String? birthDate;
  final String? birthTime;
  final String? birthPlace;

  Map<String, dynamic> toVariables() => {
        'zodiacSign': zodiacSign,
        'question': question,
        if (birthDate != null) 'birthDate': birthDate,
        if (birthTime != null) 'birthTime': birthTime,
        if (birthPlace != null) 'birthPlace': birthPlace,
      };
}

class DailyEnergyPromptInput {
  const DailyEnergyPromptInput({
    required this.date,
    required this.energyLevel,
    required this.moodLabel,
    this.zodiacSign,
    this.focusArea,
  });

  final String date;
  final num energyLevel;
  final String moodLabel;
  final String? zodiacSign;
  final String? focusArea;

  Map<String, dynamic> toVariables() => {
        'date': date,
        'energyLevel': energyLevel,
        'moodLabel': moodLabel,
        if (zodiacSign != null) 'zodiacSign': zodiacSign,
        if (focusArea != null) 'focusArea': focusArea,
      };
}

class CompatibilityPromptInput {
  const CompatibilityPromptInput({
    required this.subjectA,
    required this.subjectB,
    this.chartSummary,
  });

  final String subjectA;
  final String subjectB;
  final String? chartSummary;

  Map<String, dynamic> toVariables() => {
        'subjectA': subjectA,
        'subjectB': subjectB,
        if (chartSummary != null) 'chartSummary': chartSummary,
      };
}

class NumerologyPromptInput {
  const NumerologyPromptInput({
    required this.birthDate,
    required this.lifePathNumber,
    this.fullName,
    this.nameNumber,
  });

  final String birthDate;
  final int lifePathNumber;
  final String? fullName;
  final int? nameNumber;

  Map<String, dynamic> toVariables() => {
        'birthDate': birthDate,
        'lifePathNumber': lifePathNumber,
        if (fullName != null) 'fullName': fullName,
        if (nameNumber != null) 'nameNumber': nameNumber,
      };
}
