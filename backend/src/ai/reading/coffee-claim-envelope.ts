import type { HumanQualityFailure } from '../human-quality.js';
import type { CoffeeNarrative } from './types.js';
import type { CoffeePropositionKind } from './coffee-semantic-propositions.js';
import type { CoffeeStoryPlanV2 } from './coffee-story-plan.js';

function fold(value: string): string {
  return value.normalize('NFC').toLocaleLowerCase('tr-TR');
}

const ABSTRACT_RESTATEMENT: Record<CoffeePropositionKind, RegExp> = {
  exchange_emergence: /hayatında iletişim (önem kazan|öne çık|belirginleş)|iletişim hayatında belirleyici/,
  opening_availability: /fırsatlar? (öne çık|belirginleş)|hayatında .*fırsat (bulunuyor|doğuyor|beliriyor)/,
  connection_continuity: /hayatında .*bağ (öne çık|belirginleş)|ana (vurgu|sonuç).*bağ/,
  felt_significance: /duygusal (bir )?(konu|mesele) (gündeme|belirginleş)|duyguların .*belirleyici/,
  resolution_availability: /(çözüm|netlik) (öne çık|belirginleş)|ana sonuç.*çözüm/,
  directional_change: /(hareket|ilerleme|hareket alanı) (öne çık|belirginleş)|ana sonuç.*hareket/,
  alternative_distinction: /ana vurgu.*(seçim|tercih)|belirleyici bir seçim/,
  gradual_expansion: /(büyüme|gelişme|gelişim) (öne çık|belirginleş)|ana tema.*büyüme/,
  social_presence: /sosyal (alan|çevre|bağlar) (öne çık|belirginleş)/,
  proximate_context: /(ev ve yakın çevre|evin ve yakın çevren).*(öne çık|belirgin|ağırlık)|ana vurgu.*(ev|yakın çevre)/,
};

export function coffeeClaimEnvelopeFailure(
  narrative: CoffeeNarrative,
  plan: CoffeeStoryPlanV2,
): HumanQualityFailure | null {
  const texts = [
    narrative.visualObservation.text,
    narrative.overall.text,
    narrative.love.text,
    narrative.career.text,
    narrative.money.text,
    narrative.nearFuture.text,
    narrative.takeaway.text,
  ].map(fold);
  const text = texts.join(' ');
  const forbidden = new Set(plan.claimEnvelope.forbiddenAssumptions);

  if (forbidden.has('awaited_topic') && /beklediğin|beklemekte olduğun|önem verdiğin bir iletişim/.test(text)) {
    return 'presumed_user_state';
  }
  if (forbidden.has('prior_problem') && /uzun süredir.{0,45}(zor|çöz|uğraş|meşgul)|seni (zorlayan|uğraştıran)|zihnini meşgul eden/.test(text)) {
    return 'unsupported_existing_fact';
  }
  if (forbidden.has('existing_relationship') && /\b(partnerin|ilişkin|ilişkinizde|aranızdaki)\b/.test(text)) {
    return 'unsupported_existing_fact';
  }
  if (forbidden.has('reciprocal_feeling') && /karşılıklı (yakınlık|duygu|his|bağlılık)|birbirinizi|birbirinize/.test(text)) {
    return 'unsupported_other_agency';
  }
  if (forbidden.has('prior_stagnation') && /durgun(luk| giden)|bekleyen (konu|süreç)|aynı çerçevede kalan/.test(text)) {
    return 'unsupported_existing_fact';
  }
  if (forbidden.has('current_major_decision') && /bir seçimle karşı karşıya|vereceğin karar|kararını netleştir|doğru seçimi/.test(text)) {
    return 'presumed_user_state';
  }
  if (forbidden.has('options_assumption') && /seçenekler(in)? arasında|kararın|kuru bir hesap|ihtimallerden ayır/.test(text)) {
    return 'presumed_user_state';
  }
  if (forbidden.has('travel') && /yolculuk|seyahat/.test(text)) return 'unsupported_existing_fact';
  if (forbidden.has('relocation') && /taşın|yer değiştir/.test(text)) return 'unsupported_existing_fact';
  if (forbidden.has('family_event') && /ziyaretçi|misafir|aile içinde .*olacak|evde .*yaşanacak/.test(text)) {
    return 'context_event';
  }
  if (forbidden.has('causation') && /(?:iletişim|konuşma|haber).{0,35}(sağlayacak|yol açacak|neden olacak)|böylece/.test(text)) {
    return 'unsupported_source_causation';
  }
  if (forbidden.has('chronology') && /önce .{1,50} sonra|ardından|sonrasında/.test(text)) {
    return 'unsupported_source_causation';
  }
  if (forbidden.has('guaranteed_outcome') && /kesinlikle|mutlaka|olacak\b|yapacaksın\b|edeceksin\b/.test(text)) {
    return 'unsupported_certainty';
  }
  if (forbidden.has('advice') && /\b(malısın|melisin|dikkat et|gözünü açık|sana iyi gelir)\b/.test(text)) {
    return 'coaching_voice';
  }

  const kinds = [plan.lead.kind, ...plan.supporting.map((item) => item.kind)];
  if (kinds.some((kind) => ABSTRACT_RESTATEMENT[kind].test(text))) return 'abstract_reading';

  if (plan.synthesis.mode === 'unified_cooccurrence') {
    const sentences = fold(narrative.overall.text).split(/[.!?]+/u).filter((sentence) => sentence.trim());
    const independentlyLabelled = kinds.filter((kind) => sentences.some((sentence) => ABSTRACT_RESTATEMENT[kind].test(sentence)));
    if (independentlyLabelled.length >= 2) return 'abstract_reading';
  }
  return null;
}
