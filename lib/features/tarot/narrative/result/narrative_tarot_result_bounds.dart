/// Phase 6D — result text maxima (mirror backend contract).
library;

abstract final class NarrativeTarotResultBounds {
  NarrativeTarotResultBounds._();

  static const summary = 1200;
  static const cardReading = 900;
  static const synthesis = 1600;
  static const relationshipInsight = 700;
  static const recurringCardInsight = 650;
  static const recurringThemeInsight = 650;
  static const memoryInsight = 650;
  static const lifeArea = 700;
  static const advice = 900;
  static const reflectionPrompt = 400;
  static const dailyFocus = 500;
  static const closingMessage = 600;
  static const totalVisible = 9000;
  static const maxLifeAreas = 4;
  static const lifeAreaKinds = {'love', 'career', 'money', 'spiritual'};
  static const contractVersion = 2;
  static const locales = {'tr', 'en', 'ru'};
}
