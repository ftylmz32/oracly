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

const COMPONENT_MENTION: Record<CoffeePropositionKind, RegExp> = {
  exchange_emergence: /iletişim|konuşma|haber|mesaj/,
  opening_availability: /fırsat|açılım|imkân|imkan/,
  connection_continuity: /bağ|bağlantı|devamlılık/,
  felt_significance: /duygu|duygusal|his/,
  resolution_availability: /çözüm|netlik|açıklık/,
  directional_change: /hareket|ilerleme|yön değişimi/,
  alternative_distinction: /seçim|seçenek|alternatif|tercih/,
  gradual_expansion: /büyüme|gelişme|genişleme/,
  social_presence: /sosyal|çevre|kişi/,
  proximate_context: /ev|yakın çevre|yakın halka/,
};

/**
 * C2.7C.1 — internal-only realization vocabulary for the inter-proposition
 * causation gate (never sent to the writer). Word-initial stems, matched
 * against tr-TR folded words, so inflections ("paylaşımın", "doğrultuyu",
 * "yönünü", "netliği") resolve to their proposition kind.
 */
const REALIZATION_STEM: Record<CoffeePropositionKind, RegExp> = {
  exchange_emergence: /^(iletişim|konuşma|haber|mesaj|paylaşım|alışveriş)/,
  opening_availability: /^(fırsat|açılım|imkân|imkan)/,
  connection_continuity: /^(bağlantı|devamlılı)/,
  felt_significance: /^(duygu|duygusal)/,
  resolution_availability: /^(çözüm|netli[kğ]|açıklı[kğ])/,
  directional_change: /^(yön(?!elik|etim|etici)|doğrultu|hareket|ilerleme)/,
  alternative_distinction: /^(seçenek|seçim|alternatif|tercih)/,
  gradual_expansion: /^(büyüme|genişleme|gelişim)/,
  social_presence: /^(sosyal)/,
  proximate_context: /^ev(in|ine|de|den|i|e)?$/,
};

/** A acts on B: transitive / causative change predicates (word-initial). */
const CAUSATIVE_PREDICATE =
  /^(çevir|değiştir|döndür|yönlendir|dönüştür|netleştir|belirginleştir|aydınlat|hareketlendir|yarat|oluştur|doğur|getir|sağla|tetikle|kolaylaştır|genişlet|büyüt|güçlendir|it(er|ebil|ecek|iyor|ti|mesi)|aç(ar|abil|acak|ıyor|tı|ması|tığ|mış))/;
/** B changes because of A: intransitive change predicates (word-initial). */
const CHANGE_PREDICATE =
  /^(değiş|dönüş|netleş|belirginleş|açıl|hareketlen|genişle|büyü|güçlen|kolaylaş|şekillen|yönel)/;
/** "because of / through / by means of A". */
const CAUSAL_POSTPOSITION = /^(sayesinde|yüzünden|nedeniyle|sebebiyle|etkisiyle|aracılığıyla|sonucunda)$/;
/** Coordination makes two kinds co-subjects, never agent and patient. */
const COORDINATION = /^(ve|ile|veya|ya|hem|birlikte|beraber)$/;
const ACCUSATIVE = /(y[ıiuü]|n[ıiuü]|[^l][ıiuü])$/;
const INSTRUMENTAL = /(y?l[ae])$/;

function kindOf(word: string, planned: CoffeePropositionKind[]): CoffeePropositionKind | null {
  return planned.find((kind) => REALIZATION_STEM[kind].test(word)) ?? null;
}

/**
 * One planned proposition's realization grammatically acts on another
 * planned proposition's realization ("paylaşımın mevcut doğrultuyu başka
 * bir tarafa çevirebileceğini", "paylaşımla yönün değişebilir") while the
 * story plan relates them only as co-occurring. Plan-aware: needs two
 * DIFFERENT planned kinds in one sentence, so a single-proposition reading
 * and ordinary use of these verbs elsewhere are never affected.
 */
function unsupportedPropositionCausation(texts: string[], plan: CoffeeStoryPlanV2): boolean {
  const planned = [...new Set([plan.lead.kind, ...plan.supporting.map((item) => item.kind)])];
  if (planned.length < 2) return false;
  if (!plan.supporting.every((item) => item.relation === 'co_occurring')) return false;
  for (const sentence of texts.flatMap((text) => text.split(/[.!?;]+/u))) {
    const words = sentence.split(/[^\p{L}]+/u).filter(Boolean);
    for (let i = 0; i < words.length; i++) {
      const agent = kindOf(words[i], planned);
      if (!agent) continue;
      if (INSTRUMENTAL.test(words[i]) && /^(birlikte|beraber)$/.test(words[i + 1] ?? '')) continue;
      const agentIsInstrumental = INSTRUMENTAL.test(words[i]) || CAUSAL_POSTPOSITION.test(words[i + 1] ?? '');
      for (let j = i + 1; j < words.length; j++) {
        if (COORDINATION.test(words[j])) break;
        const patient = kindOf(words[j], planned);
        if (!patient || patient === agent) continue;
        const window = words.slice(j + 1, j + 7);
        // A + B-accusative (or its head noun, "çözüm alanını") + causative.
        const accusative = ACCUSATIVE.test(words[j]) || ACCUSATIVE.test(words[j + 1] ?? '');
        if (accusative && window.some((word, index) =>
          CAUSATIVE_PREDICATE.test(word) || (word === 'yol' && /^aç/.test(window[index + 1] ?? '')))) {
          return true;
        }
        // "A ile / A sayesinde" + B + intransitive change.
        if (agentIsInstrumental && window.some((word) => CHANGE_PREDICATE.test(word))) return true;
      }
    }
  }
  return false;
}

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
  if (forbidden.has('causation') && /(?:iletişim|konuşma|haber|mesaj|çözüm|netlik|hareket|fırsat).{0,45}(sağlayacak|yol açacak|neden olacak|tetikleyecek|doğuracak|beraberinde getirecek)|\b(böylece|bu nedenle|bu yüzden|dolayısıyla|sayesinde|sonucunda)\b/.test(text)) {
    return 'unsupported_source_causation';
  }
  if (forbidden.has('causation') && unsupportedPropositionCausation(texts, plan)) {
    return 'unsupported_source_causation';
  }
  if (forbidden.has('chronology') && /önce\b.{1,70}\bsonra|ilk olarak|ardından|akabinde|devamında|sonrasında|daha sonra|bir sonraki adımda/.test(text)) {
    return 'unsupported_chronology';
  }
  if (forbidden.has('guaranteed_outcome') && /kesinlikle|mutlaka|olacak\b|yapacaksın\b|edeceksin\b/.test(text)) {
    return 'unsupported_certainty';
  }
  if (forbidden.has('advice') && /\b(malısın|melisin|dikkat et|gözünü açık|sana iyi gelir)\b/.test(text)) {
    return 'coaching_voice';
  }

  const kinds = [plan.lead.kind, ...plan.supporting.map((item) => item.kind)];
  if (plan.synthesis.mode === 'unified_cooccurrence') {
    const sentences = fold(narrative.overall.text).split(/[.!?]+/u).filter((sentence) => sentence.trim());
    const singleComponentSentences = sentences
      .map((sentence) => kinds.filter((kind) => COMPONENT_MENTION[kind].test(sentence)))
      .filter((mentioned) => mentioned.length === 1)
      .map(([kind]) => kind);
    if (new Set(singleComponentSentences).size >= 2) return 'component_serialization';
  }
  if (kinds.some((kind) => ABSTRACT_RESTATEMENT[kind].test(text))) return 'abstract_reading';
  return null;
}
