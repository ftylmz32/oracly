/// Applies a stored tarot summary onto live reading content.

library;



import '../../../features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';



AiReadingContent tarotContentWithSummary(

  AiReadingContent base,

  String summary,

) {

  return AiReadingContent(

    cardName: base.cardName,

    tagline: base.tagline,

    generalMeaning: base.generalMeaning,

    love: base.love,

    career: base.career,

    money: base.money,

    spiritualGuidance: base.spiritualGuidance,

    luckyEnergy: base.luckyEnergy,

    dailyAdvice: base.dailyAdvice,

    imageAsset: base.imageAsset,

    rarityColor: base.rarityColor,

    fullInterpretation: summary,

    drawnCards: base.drawnCards,

    spreadLabel: base.spreadLabel,

    closingMessage: base.closingMessage,

    cardReadings: base.cardReadings,

    readingTheme: base.readingTheme,

    promptQuestion: base.promptQuestion,

    userQuestion: base.userQuestion,

    interpretationSource: base.interpretationSource,

  );

}


