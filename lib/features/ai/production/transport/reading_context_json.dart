/// Serialize structured OR contexts for the proxy — kinds stay isolated.
library;

import '../contexts/reading_ai_context.dart';

abstract final class ReadingContextJson {
  ReadingContextJson._();

  static Map<String, dynamic> toJson(ReadingAiContext context) {
    return switch (context) {
      TarotAiContext() => {
          'kind': context.kindId,
          'sessionId': context.sessionId,
          'spreadLabel': context.spreadLabel,
          'readingTitle': context.readingTitle,
          'cardsSummary': context.cardsSummary,
          'interpretationSummary': context.interpretationSummary,
          if (_has(context.fullInterpretation))
            'fullInterpretation': context.fullInterpretation,
          if (_has(context.userQuestion)) 'userQuestion': context.userQuestion,
          'cardNames': context.cardNames,
        },
      DreamAiContext() => {
          'kind': context.kindId,
          'narrative': context.narrative,
          'symbols': context.symbols,
          'emotions': context.emotions,
          if (_has(context.analysis)) 'analysis': context.analysis,
          if (_has(context.emotionalTheme))
            'emotionalTheme': context.emotionalTheme,
          if (_has(context.fullInterpretation))
            'fullInterpretation': context.fullInterpretation,
        },
      AstrologyAiContext() => {
          'kind': context.kindId,
          'signLabel': context.signLabel,
          'daily': context.daily,
          'readingType': context.readingType,
          if (_has(context.personality)) 'personality': context.personality,
          if (_has(context.love)) 'love': context.love,
          if (_has(context.career)) 'career': context.career,
          if (_has(context.money)) 'money': context.money,
          if (_has(context.energy)) 'energy': context.energy,
          if (_has(context.emotion)) 'emotion': context.emotion,
          if (_has(context.advice)) 'advice': context.advice,
          if (_has(context.fullInterpretation))
            'fullInterpretation': context.fullInterpretation,
        },
      BirthChartAiContext() => {
          'kind': context.kindId,
          'sunLabel': context.sunLabel,
          'interpretation': context.interpretation,
          if (_has(context.summary)) 'summary': context.summary,
          if (_has(context.strongThemes)) 'strongThemes': context.strongThemes,
          if (_has(context.notableThemes))
            'notableThemes': context.notableThemes,
          'placements': context.placements,
          if (_has(context.birthLine)) 'birthLine': context.birthLine,
          if (_has(context.fullInterpretation))
            'fullInterpretation': context.fullInterpretation,
        },
      CoffeeAiContext() => {
          'kind': context.kindId,
          'overall': context.overall,
          if (_has(context.visualObservation))
            'visualObservation': context.visualObservation,
          if (_has(context.love)) 'love': context.love,
          if (_has(context.career)) 'career': context.career,
          if (_has(context.money)) 'money': context.money,
          if (_has(context.nearFuture)) 'nearFuture': context.nearFuture,
          if (_has(context.takeaway)) 'takeaway': context.takeaway,
          'symbolNames': context.symbolNames,
          if (_has(context.fullInterpretation))
            'fullInterpretation': context.fullInterpretation,
        },
      PalmAiContext() => {
          'kind': context.kindId,
          'sessionId': context.sessionId,
          'overall': context.overall,
          if (_has(context.takeaway)) 'takeaway': context.takeaway,
          if (_has(context.handLabel)) 'handLabel': context.handLabel,
          if (_has(context.heartLine)) 'heartLine': context.heartLine,
          if (_has(context.headLine)) 'headLine': context.headLine,
          if (_has(context.lifeLine)) 'lifeLine': context.lifeLine,
          if (_has(context.fateLine)) 'fateLine': context.fateLine,
          'symbols': context.symbols,
          'themes': context.themes,
          if (_has(context.fullInterpretation))
            'fullInterpretation': context.fullInterpretation,
        },
    };
  }

  static bool _has(String? value) => (value ?? '').trim().isNotEmpty;
}
