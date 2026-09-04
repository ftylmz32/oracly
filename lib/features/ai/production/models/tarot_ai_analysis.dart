/// Typed contract for grounded initial Tarot analysis.
library;

class TarotAiCardEvidence {
  const TarotAiCardEvidence({
    required this.cardId,
    required this.cardName,
    required this.positionLabel,
    required this.positionKey,
    required this.isReversed,
    required this.meaning,
    this.keywords = const [],
  });

  final int cardId;
  final String cardName;
  final String positionLabel;
  final String positionKey;
  final bool isReversed;
  final String meaning;
  final List<String> keywords;

  Map<String, dynamic> toJson() => {
        'cardId': cardId,
        'cardName': cardName,
        'positionLabel': positionLabel,
        'positionKey': positionKey,
        'isReversed': isReversed,
        'meaning': meaning,
        'keywords': keywords,
      };
}

class TarotAiJourneyEvidence {
  const TarotAiJourneyEvidence({
    this.recurringThemes = const [],
    this.priorReadingCount = 0,
    this.hasPriorNotes = false,
    this.priorOpenings = const [],
    this.revisitPriorExcerpt,
    this.revisitInstruction,
  });

  final List<String> recurringThemes;
  final int priorReadingCount;
  final bool hasPriorNotes;
  final List<String> priorOpenings;
  final String? revisitPriorExcerpt;
  final String? revisitInstruction;

  bool get hasEvidence =>
      recurringThemes.isNotEmpty ||
      priorReadingCount > 0 ||
      hasPriorNotes ||
      priorOpenings.isNotEmpty ||
      (revisitPriorExcerpt ?? '').trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'recurringThemes': recurringThemes,
        'priorReadingCount': priorReadingCount,
        'hasPriorNotes': hasPriorNotes,
        'priorOpenings': priorOpenings,
        if ((revisitPriorExcerpt ?? '').trim().isNotEmpty)
          'revisitPriorExcerpt': revisitPriorExcerpt,
        if ((revisitInstruction ?? '').trim().isNotEmpty)
          'revisitInstruction': revisitInstruction,
      };
}

class TarotAiAnalysisRequest {
  const TarotAiAnalysisRequest({
    required this.sessionId,
    required this.spreadLabel,
    required this.cards,
    this.readingTheme,
    this.userQuestion,
    this.journey,
  });

  final String sessionId;
  final String spreadLabel;
  final String? readingTheme;
  final String? userQuestion;
  final List<TarotAiCardEvidence> cards;
  final TarotAiJourneyEvidence? journey;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'spreadLabel': spreadLabel,
        if ((readingTheme ?? '').trim().isNotEmpty) 'readingTheme': readingTheme,
        if ((userQuestion ?? '').trim().isNotEmpty) 'userQuestion': userQuestion,
        'cards': cards.map((card) => card.toJson()).toList(growable: false),
        if (journey?.hasEvidence ?? false) 'journey': journey!.toJson(),
      };
}

class TarotAiAnalysis {
  const TarotAiAnalysis({
    required this.summary,
    required this.love,
    required this.career,
    required this.money,
    required this.health,
    required this.spiritualGuidance,
    required this.advice,
    required this.warnings,
    required this.luckyEnergy,
    required this.dailyFocus,
    required this.closingMessage,
  });

  final String summary;
  final String love;
  final String career;
  final String money;
  final String health;
  final String spiritualGuidance;
  final String advice;
  final String warnings;
  final String luckyEnergy;
  final String dailyFocus;
  final String closingMessage;

  static TarotAiAnalysis? tryFromMap(Map<String, dynamic> data) {
    String text(String key) => (data[key] as String? ?? '').trim();
    final summary = text('summary');
    final advice = text('advice');
    final closing = text('closingMessage');
    if (summary.isEmpty || advice.isEmpty || closing.isEmpty) return null;
    return TarotAiAnalysis(
      summary: summary,
      love: text('love'),
      career: text('career'),
      money: text('money'),
      health: text('health'),
      spiritualGuidance: text('spiritualGuidance'),
      advice: advice,
      warnings: text('warnings'),
      luckyEnergy: text('luckyEnergy'),
      dailyFocus: text('dailyFocus'),
      closingMessage: closing,
    );
  }
}
