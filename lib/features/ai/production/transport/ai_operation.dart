/// Stable proxy operations — backend builds provider prompts.
library;

enum AiOperation {
  chat,
  oracle,
  dreamAnalysis,
  coffeeAnalysis,
  palmAnalysis,
  soulmateDraw,
  soulmateInterpretation,
  tarotReading,
  yildiznameReading,
  tts,
}

extension AiOperationWire on AiOperation {
  String get wireName => switch (this) {
        AiOperation.chat => 'chat',
        AiOperation.oracle => 'oracle',
        AiOperation.dreamAnalysis => 'dream_analysis',
        AiOperation.coffeeAnalysis => 'coffee_analysis',
        AiOperation.palmAnalysis => 'palm_analysis',
        AiOperation.soulmateDraw => 'soulmate_draw',
        AiOperation.soulmateInterpretation => 'soulmate_interpretation',
        AiOperation.tarotReading => 'tarot_reading',
        AiOperation.yildiznameReading => 'yildizname_reading',
        AiOperation.tts => 'tts',
      };
}
