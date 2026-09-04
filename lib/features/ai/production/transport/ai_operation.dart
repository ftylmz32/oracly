/// Stable proxy operations — backend builds provider prompts.
library;

enum AiOperation {
  chat,
  oracle,
  tarotAnalysis,
  dreamAnalysis,
  coffeeAnalysis,
  palmAnalysis,
  soulmateDraw,
  tts,
}

extension AiOperationWire on AiOperation {
  String get wireName => switch (this) {
        AiOperation.chat => 'chat',
        AiOperation.oracle => 'oracle',
        AiOperation.tarotAnalysis => 'tarot_analysis',
        AiOperation.dreamAnalysis => 'dream_analysis',
        AiOperation.coffeeAnalysis => 'coffee_analysis',
        AiOperation.palmAnalysis => 'palm_analysis',
        AiOperation.soulmateDraw => 'soulmate_draw',
        AiOperation.tts => 'tts',
      };
}
