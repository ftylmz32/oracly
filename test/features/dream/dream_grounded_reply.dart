/// Test-only provider reply that survives the client Dream guard for any
/// told narrative: every required section is written in the operation
/// language and stays attached to what was told. Tests that are not about
/// prose quality (owner switch, in-flight races, privacy) use it so the
/// Phase 4B premium delivery contract is met without scripting prose.
library;

import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';

DreamAiAnalysis groundedDreamReply(DreamAiContext context) {
  // The told Dream only — never the structured "[Context]" block after it.
  final told = context.narrative
      .split('\n')
      .first
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
  final bare = told.replaceAll(RegExp(r'[?？]'), '').replaceAll(RegExp(r'[.!…\s]+$'), '');
  switch (context.language) {
    case 'en':
      return DreamAiAnalysis(
        summary: 'The main feeling of this dream stays close to what was told: $told',
        symbols: context.symbols,
        emotionalTheme: 'The tone of the telling carries a quiet attention: $told',
        interpretation:
            'The told details lean on each other and can be read together: $told',
        dailyLifeReflection:
            'Today it may help to notice one small detail from this telling: $told',
        conclusion: 'Which detail from this telling stays with you most: $bare?',
      );
    case 'ru':
      return DreamAiAnalysis(
        summary: 'Главное чувство этого сна остаётся рядом с рассказом: $told',
        symbols: context.symbols,
        emotionalTheme: 'Тон рассказа несёт тихое внимание: $told',
        interpretation:
            'Рассказанные детали опираются друг на друга и читаются вместе: $told',
        dailyLifeReflection:
            'Сегодня можно заметить одну маленькую деталь из этого рассказа: $told',
        conclusion: 'Какая деталь из этого рассказа остаётся с тобой сильнее всего: $bare?',
      );
    default:
      return DreamAiAnalysis(
        summary: 'Rüyanın ana hissi anlatılana yakın duruyor: $told',
        symbols: context.symbols,
        emotionalTheme: 'Anlatının tonu sessiz bir dikkat taşıyor: $told',
        interpretation:
            'Anlatılan ayrıntılar birbirine yaslanıyor ve birlikte okunabilir: $told',
        dailyLifeReflection:
            'Bugün bu anlatıdan küçük bir ayrıntıyı fark etmek iyi gelebilir: $told',
        conclusion: 'Bu anlatıda en çok hangi ayrıntı seninle kalıyor: $bare?',
      );
  }
}
