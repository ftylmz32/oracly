/// Frozen TR/EN/RU stopwords for historical token overlap (Phase 4A).
library;

abstract final class TarotHistoricalStopwords {
  TarotHistoricalStopwords._();

  static const Set<String> all = {
    // TR
    'bir', 'bunu', 'bunun', 'için', 'ile', 'ama', 'gibi', 'olan', 'daha',
    'sonra', 'şimdi', 'acaba', 'miyim', 'misin', 'mısın', 'mu', 'mü', 'veya',
    'çünkü',
    // EN
    'this', 'that', 'with', 'from', 'have', 'will', 'would', 'could', 'should',
    'about', 'what', 'when', 'where', 'which', 'your', 'mine', 'ours', 'their',
    'them', 'then', 'than', 'into', 'just',
    // RU
    'этот', 'эта', 'это', 'что', 'как', 'когда', 'где', 'который', 'моя', 'мой',
    'твой', 'ваш', 'для', 'или', 'потом', 'сейчас', 'если', 'чтобы',
  };
}
