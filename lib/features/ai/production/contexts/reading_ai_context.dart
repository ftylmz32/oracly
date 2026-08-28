/// Structured reading contexts — only real fields, never invented data.
library;

part 'palm_ai_context.dart';

sealed class ReadingAiContext {
  const ReadingAiContext();

  String get kindId;
}

final class TarotAiContext extends ReadingAiContext {
  const TarotAiContext({
    required this.sessionId,
    required this.spreadLabel,
    required this.readingTitle,
    required this.cardsSummary,
    required this.interpretationSummary,
    this.fullInterpretation,
    this.userQuestion,
    this.cardNames = const [],
    this.cardIds = const [],
  });

  final String sessionId;
  final String spreadLabel;
  final String readingTitle;
  final String cardsSummary;
  final String interpretationSummary;
  final String? fullInterpretation;
  final String? userQuestion;
  final List<String> cardNames;
  final List<int> cardIds;

  @override
  String get kindId => 'tarot';
}

final class DreamAiContext extends ReadingAiContext {
  const DreamAiContext({
    required this.narrative,
    this.symbols = const [],
    this.emotions = const [],
    this.analysis,
    this.emotionalTheme,
    this.fullInterpretation,
  });

  final String narrative;
  final List<String> symbols;
  final List<String> emotions;
  final String? analysis;
  final String? emotionalTheme;
  final String? fullInterpretation;

  @override
  String get kindId => 'dream';
}

final class AstrologyAiContext extends ReadingAiContext {
  const AstrologyAiContext({
    required this.signLabel,
    required this.daily,
    this.readingType = 'Günlük',
    this.personality,
    this.love,
    this.career,
    this.money,
    this.energy,
    this.emotion,
    this.advice,
    this.fullInterpretation,
  });

  final String signLabel;
  final String daily;
  final String readingType;
  final String? personality;
  final String? love;
  final String? career;
  final String? money;
  final String? energy;
  final String? emotion;
  final String? advice;
  final String? fullInterpretation;

  @override
  String get kindId => 'astrology';
}

final class BirthChartAiContext extends ReadingAiContext {
  const BirthChartAiContext({
    required this.sunLabel,
    required this.interpretation,
    this.summary,
    this.strongThemes,
    this.notableThemes,
    this.placements = const [],
    this.birthLine,
    this.fullInterpretation,
  });

  final String sunLabel;
  final String interpretation;
  final String? summary;
  final String? strongThemes;
  final String? notableThemes;
  final List<String> placements;
  final String? birthLine;
  final String? fullInterpretation;

  @override
  String get kindId => 'birthChart';
}

final class CoffeeAiContext extends ReadingAiContext {
  const CoffeeAiContext({
    required this.overall,
    this.visualObservation,
    this.love,
    this.career,
    this.money,
    this.nearFuture,
    this.takeaway,
    this.symbolNames = const [],
    this.fullInterpretation,
  });

  final String overall;
  final String? visualObservation;
  final String? love;
  final String? career;
  final String? money;
  final String? nearFuture;
  final String? takeaway;
  final List<String> symbolNames;
  final String? fullInterpretation;

  @override
  String get kindId => 'coffee';
}
