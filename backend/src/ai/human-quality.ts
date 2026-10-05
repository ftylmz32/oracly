/**
 * Deterministic structural / safety checks for Coffee & Palm human output.
 * Strengthened in E3G for grounding, specificity, and anti-boilerplate.
 */

import { palmClaimFailure, palmVoiceFailure } from './palm-quality-guards.js';

export type HumanQualityFailure =
  | 'empty'
  | 'too_short'
  | 'duplicate_sections'
  | 'generic'
  | 'ai_disclosure'
  | 'unsupported_certainty'
  | 'prohibited_claim'
  | 'wrong_locale_marker'
  | 'weak_observation'
  | 'closing_question_habit'
  | 'repeated_stock'
  | 'locale_leak'
  | 'embedded_disclaimer'
  | 'generic_closing'
  | 'inferred_handedness'
  /**
   * BATCH 3A: the final prose reads as a visual/observation report (cup
   * position, residue, line-shape enumeration) rather than a life
   * interpretation. Replaces the old "insufficient_anchors" check, which
   * required a MINIMUM density of this exact vocabulary in the final
   * text — i.e. it forced the observation-heavy style this code now
   * rejects. Real grounding (every claim must cite a real evidence id)
   * is unaffected — see evidence-bind.ts's bindSections.
   */
  | 'observation_heavy'
  /** Internal pipeline/schema vocabulary leaked into user-facing prose. */
  | 'schema_jargon_leak'
  /**
   * BATCH 3A.1: the narrative implies continuity/memory of this person
   * ("like last time", "geçen seferinde") when no memorySummary was
   * actually supplied in personalization — a fabricated-memory claim,
   * the same fake-memory safety class already enforced for OR/Luna.
   */
  | 'fake_memory'
  /**
   * BATCH 3A.3: a supplied relevantTheme became the subject of nearly
   * every filled section instead of a quiet lens on independent evidence.
   */
  | 'theme_domination'
  /**
   * BATCH 3A.3: distinct headings restated the same idea, advice, or
   * evidence conclusion — synonym paraphrase, not additive synthesis.
   */
  | 'section_redundancy'
  /**
   * BATCH 3A.5: coffee overall, nearFuture, and takeaway repeat one
   * concept family (withheld speech, measured openness, boundary talk)
   * or the same evidence cluster. Distinct from grounding failures.
   */
  | 'insight_collapse'
  /**
   * BATCH 3A.3: generic coaching formula used as a takeaway (two-or-three
   * criteria, a small list, one small step) without feature-specific meaning.
   */
  | 'stock_advice'
  /**
   * BATCH 3A.3: a palm major-line's length/direction/depth/curve/continuity
   * is narrated again in overall and takeaway after its own line section.
   */
  | 'evidence_reuse'
  /** Palm: reference-book attribution ("ilişkilendirilir", "karşılık gelir"). */
  | 'dictionary_voice'
  /** Palm: an invented other person, or what someone else sees/thinks/feels. */
  | 'unsupported_other_person'
  /** Palm: an invented present or past circumstance (a decision, a wait, an attachment). */
  | 'presumed_user_state'
  | 'unsupported_existing_fact'
  | 'unsupported_source_causation'
  /** Palm: commands, advice, or homework instead of a reading. */
  | 'coaching_voice'
  /** Palm: a second-person reading that profiles the person in third person. */
  | 'person_switch'
  /** Coffee: therapist/coaching register instead of fortune-teller voice. */
  | 'abstract_reading'
  /** Coffee: one abstract theme family dominates distinct sections. */
  | 'abstract_soup'
  /** Coffee: predicted event domains exceed resemblance-bearing signs. */
  | 'event_pile'
  /** Coffee: generic wrapper carries the reading instead of cup evidence. */
  | 'generic_wrapper'
  /** Coffee: detached analyst/horoscope register. */
  | 'analyst_voice'
  /** Coffee: repeated contrast or hedge formula carries delivery. */
  | 'formulaic_voice'
  /** Coffee: most sentences negate developments and close on "not yet". */
  | 'caution_voice'
  | 'possibility_menu'
  | 'invented_plan'
  | 'repeated_sentence'
  | 'cup_meta_talk'
  | 'geometry_inference'
  | 'context_event'
  | 'context_sequence'
  | 'plain_line_relocation'
  | 'advice_voice'
  | 'unsupported_home_domain'
  | 'unsupported_other_agency';

export type CoffeeQualityInput = {
  visualObservation: string;
  overall: string;
  love: string;
  career: string;
  money: string;
  nearFuture: string;
  takeaway: string;
  language?: 'tr' | 'en' | 'ru';
  /** True only when personalization.memorySummary was actually supplied. */
  hasMemoryContext?: boolean;
  /**
   * Story-first closure (coffee): true when personalization supplied an
   * intention (the person's own question) — only then may the reading speak
   * of what the person is waiting for or wants.
   */
  hasIntention?: boolean;
  /** Supplied recurring-theme labels — supporting context, not the subject. */
  relevantThemes?: string[];
  /**
   * PHASE C1.1: observer evidence items carrying a resemblance. Caps how
   * many unrelated event domains a reading may stack; omitted = no cap.
   */
  groundedSigns?: number;
  /**
   * PHASE C1.3: whether any observer evidence affords communication (bird,
   * figure, dots...). When false, a talk-and-relief arc is a generic
   * wrapper; omitted = that rule is skipped.
   */
  communicationAffordance?: boolean;
  /**
   * Story-first closure: Turkish roots of the cup's ONE evidence-grounded
   * semantic sign (e.g. star -> yildiz), derived from observer evidence
   * only. A single-sign reading names its sign in every section; that
   * grounding anchor is not repetition. Omitted/empty = no exemption.
   */
  singleSemanticAnchorRoots?: string[];
  /**
   * Story-first closure: evidence has no sign or drawn form (dots, faint
   * marks, density, clean band, handle side only). Lowers only the lead
   * floor and stops the evidence's own name counting as a takeaway echo.
   */
  narrativelySparse?: boolean;
  /**
   * Story-first closure: a narratively sparse reading that names its own
   * cited context evidence (clean band, dots, faint marks, handle, base) is
   * grounded even without a semantic sign or a life event. Evidence-derived
   * (coffeeSparseContextAnchored); only relaxes abstract_reading.
   */
  sparseContextAnchored?: boolean;
};

export type PalmQualityInput = {
  visualObservation: string;
  overall: string;
  lifeLine: string;
  headLine: string;
  heartLine: string;
  fateLine: string;
  takeaway: string;
  language?: 'tr' | 'en' | 'ru';
  /** When false/undefined, narrative must not assert left/right hand. */
  trustedHandSide?: boolean;
  /** True only when personalization.memorySummary was actually supplied. */
  hasMemoryContext?: boolean;
  /** True when personalization supplied an intention or memorySummary. */
  hasStatedContext?: boolean;
  /** Supplied recurring-theme labels — supporting context, not the subject. */
  relevantThemes?: string[];
};

const AI_DISCLOSURE =
  /\b(as an ai|i'?m an ai|i am an ai|bir yapay zeka|yapay zeka olarak|как ии|я ии)\b/i;

const CERTAINTY =
  /\b(kesin olacak|definitely will|you will die|olecek(sin|siniz)|ne zaman olecegini|olum tarihi|kac yasinda olecek|omrun|lifespan is|you will live exactly|date of death)\b/i;

const MEDICAL =
  /\b(hastalik teshis|diagnose cancer|medical diagnosis|yasam suresi|lifespan diagnosis|fertility diagnosis|hamile kalacaksin|you are pregnant|pregnant by|kac cocugun olacak|uzun (bir )?omur|omur (goster|iddia(?!si degil))|lifespan is)\b/i;

/** English technical cup terms that must not appear in Turkish narrative. */
const TR_LOCALE_LEAK =
  /\brim\b|\bupper wall\b|\blower wall\b|\bmid(?:dle)? wall\b|\bhandle side\b|\bbase edge\b|\bcup interior\b|\bright hand\b|\bleft hand\b/i;

const EN_LOCALE_LEAK_CYR =
  /[\u0400-\u04FF]{8,}/;

const EMBEDDED_DISCLAIMER =
  /eglence (ve|\/) (kisisel )?dus|yalnizca eglence|tibbi (veya|ya da).{0,24}(teshis|tani)|saglik (ya da|veya) omur|omur hakkinda yorumlanmaz|kesin (bir )?ongoru|bu yalnizca|for entertainment only|not (a )?medical|symbolic reading only|entertainment purposes/i;

const GENERIC_CLOSING =
  /enerjini .{0,48}yonelt|kisisel (bir )?dus(u|ü)?nme aynasi|dusunme aynasi|kapilar ac|beklenmedik kapilar|yeni (bir )?baslangic/i;

const INFERRED_HAND =
  /\b(sag|sol) (el|avuc|avu[cç])\b|\b(right|left) (hand|palm)\b|\bsingle right hand\b|\bsingle left hand\b/i;


/**
 * Story-first closure: normal (non-sparse) floors 50/30 -> 42/22, calibrated
 * on all 133 saved non-sparse real stages. Only 5 had overall <= 30 or lead
 * <= 50: two clean sign-led BIRD writer passes (full12_run9 23/43, targeted16
 * 28/49) that were padded by unnecessary repairs, and three that other gates
 * reject at any floor (RING repair 25/46 and STAR repair 27/50: menu +
 * "yorulur"; TWO-SIGN repair 28/51: reading self-reference). The floors sit
 * one word below the shortest clean real reading. Takeaway (10) unchanged.
 */
const COFFEE_MIN_LEAD_WORDS = 42;
/** PHASE C1.5: per-section substance (replaces the aggregate word quota). */
const COFFEE_MIN_OVERALL_WORDS = 22;
const COFFEE_MIN_TAKEAWAY_WORDS = 10;
/**
 * Story-first closure: floors for a NARRATIVELY SPARSE cup (no sign or drawn
 * form) only. Calibrated on all 34 saved real sparse-cup stages (SPARSE,
 * HANDLE, DOTS; run1–6, run8, targeted9–14): the smallest grounded concise
 * outputs were overall 27 / lead 42 (targeted14 HANDLE) — but 4 of those
 * words were the advice clause "gözün kulağın yakınında olsun"; its grounded
 * content alone is overall 23 / lead 38 — and takeaway 9 (targeted14 HANDLE
 * repair, run1 DOTS). The floors sit just below those minima; trivial
 * filler (~10 words) still fails. The normal floors are unchanged.
 */
const COFFEE_MIN_LEAD_WORDS_SPARSE = 35;
const COFFEE_MIN_OVERALL_WORDS_SPARSE = 20;
const COFFEE_MIN_TAKEAWAY_WORDS_SPARSE = 8;

const GENERIC_COFFEE =
  /^(this cup (shows|reveals) (energy|potential)\.?|fincan enerji tasiyor\.?|analysis complete\.?)$/i;

const GENERIC_PALM =
  /^(your palm (shows|reveals) (energy|potential)\.?|avuc enerji tasiyor\.?|analysis complete\.?)$/i;

/** Stock fortune fillers — match against foldTr(). */
const COFFEE_STOCK =
  /geleneksel olarak[\s\S]{0,48}anlamina gelebilir|firsatlar dogabilir|duygusal bir hareketlilik|iletisim on plana|analiz tamamlandi|yeni bir baslangic|beklenmedik kapilar|bir araya gelmeyi sembolize/i;

const PALM_STOCK =
  /guclu (bir )?enerji|dengeli (bir )?yaklasim|dikkat cekici bir yapi|belirgin ana cizgiler mevcut|genel olarak acik ve net|avuc enerji/i;

const PALM_WEAK_OBS =
  /^(acik avuc[^.!]{0,40}(mevcut|gorunuyor|net)\.?|open palm[^.!]{0,40}(visible|clear)\.?)$/i;

const COFFEE_REGION =
  /(agiz|ust\s*duvar|orta\s*duvar|ic\s*duvar|dip|taban|kulp|rim|wall|base|handle|край|стенк|дно)/i;

const COFFEE_DENSITY =
  /(yogun|acik alan|acik bir alan|seyrek|kume|telve|birikinti|koyu|dense|open\s*space|dark\s*area|гущ|скоплен)/i;

const COFFEE_SHAPE =
  /(andiran|benziyor|bicim|sekil|egim|yon|cizgi|kume kenar|trail|shape|форм)/i;

/** Evidence-report verbs — "X is visible/seen here" framing, not meaning. */
const OBSERVATION_VERB =
  /gor(u|ü)l(u|ü)yor|gor(u|ü)n(u|ü)yor|goze carpiyor|is visible|can be seen|there is a|there'?s a|видно|виднеется/gi;

/**
 * Continuity/memory phrases — legitimate ONLY when personalization
 * actually supplied a memorySummary for this reading. Otherwise this is
 * the writer fabricating a relationship history that was never given to
 * it, the same fake-memory failure mode already guarded against for
 * OR/Luna chat.
 */
const FAKE_MEMORY_CLAIM =
  /gecen (seferinde|okumanda|falinda|defasinda)|onceki (okumanda|falinda|seferinde)|hatirliyorum ki|yine ayni sekilde|daha once (soylemistim|demistim|gormustuk)|last time (you|we)|as (i mentioned|we discussed) (before|last time)|previously you (told|said|mentioned)|i remember (when|you (telling|saying))|в прошлый раз|как (я говорил|ты говорил)|помню, (ты|как)/i;

/**
 * Life-meaning / interpretive-connective vocabulary. A section that
 * mentions cup/line vocabulary AND at least one of these is read as
 * evidence-supporting-interpretation (acceptable); a section with the
 * former and none of the latter reads as a bare observation report
 * (rejected). Deliberately broad/generous so this never penalizes
 * genuinely interpretive prose — see BATCH 3A fixtures.
 */
const MEANING_MARKER =
  /gibi|olabilir|olasi|cagristir|isaret ed|hissettir|hisset|dusundur|donem|karar|iliski|firsat|konusma|adim|yon(elik|el)|degisim|izlenim|gundem|nefes|tempo|ritim|yaklasim|tarz|egilim|ihtimal|anlam|yansima|kiyisina|netlesmemis|means|suggests that|points toward|reflects|likely|chapter|season|decision|relationship|opportunity|shift|означает|подсказывает|отраж/i;

/** Internal pipeline/schema vocabulary that must never reach user prose. */
const SCHEMA_JARGON =
  /\bjson\b|\bschema\b|evidence[\s_-]?id|\bobserver\b|\bconfidence\s*:\s*(high|medium|low)\b|\bvisibility\s*:\s*(clear|partial|uncertain)\b|\bregionlabel\b/i;

/**
 * A section reads as a bare visual/observation report — rather than
 * evidence supporting an interpretation — when it contains cup/line
 * description vocabulary but not a single life-meaning connective
 * anywhere in the section. Section-level (not sentence-level) on
 * purpose: real interpretive prose freely mixes a brief visual clause
 * into the same sentence or paragraph as its meaning, so this only
 * flags a section that is observation from end to end.
 */
function isBareObservationSection(
  text: string,
  obsVocab: RegExp[],
  isMeaningful: (folded: string) => boolean = (t) => MEANING_MARKER.test(t),
): boolean {
  const t = foldTr(text.trim());
  if (!t) return false;
  const hasObsVocab = obsVocab.some((re) => re.test(t));
  if (!hasObsVocab) return false;
  return !isMeaningful(t);
}

/**
 * PHASE C1: Coffee's own "this section means something" test. Abstract
 * nouns (karar, dönem, tempo, ritim, yön, ihtimal, yaklaşım...) no longer
 * qualify prose as interpretation on their own; a hedge/fortune connective
 * or a concrete human-life development does.
 */
const COFFEE_MEANING_CONNECTIVE =
  /gibi|olabilir|olasi|cagristir|isaret ed|hissettir|dusundur|soyluy|gosteriy|demektir|diye okunur|anlamina|means|suggests that|points toward|likely|означает|подсказывает/;

function coffeeSectionMeaningful(folded: string): boolean {
  return COFFEE_MEANING_CONNECTIVE.test(folded) || kindHits(folded, COFFEE_LIFE_KINDS) > 0;
}

const PALM_ATTR =
  /(yay|kivrim|egri|duz|derin|sig|koyu|kontrast|kesik|kopuk|surekli|devam|aralik|yakin|uzak|baslar|biter|uc|bilek|origin|curv|depth|contin|spacing|endpoint|изгиб|глубин|разрыв)/i;

export function evaluateCoffeeQuality(
  input: CoffeeQualityInput,
): HumanQualityFailure | null {
  const observation = input.visualObservation.trim();
  const overall = input.overall.trim();
  const takeaway = input.takeaway.trim();
  if (!observation || !overall) return 'empty';
  if (AI_DISCLOSURE.test(joinSections(input))) return 'ai_disclosure';
  if (GENERIC_COFFEE.test(foldTr(overall)) || GENERIC_COFFEE.test(foldTr(observation))) {
    return 'generic';
  }
  const earlyBlob = joinSections(input);
  if (input.language === 'tr' && TR_LOCALE_LEAK.test(earlyBlob)) return 'locale_leak';
  if (input.language === 'en' && EN_LOCALE_LEAK_CYR.test(earlyBlob)) return 'locale_leak';
  if (EMBEDDED_DISCLAIMER.test(foldTr(earlyBlob))) return 'embedded_disclaimer';
  if (GENERIC_CLOSING.test(foldTr(takeaway)) || GENERIC_CLOSING.test(foldTr(overall))) {
    return 'generic_closing';
  }
  if (observation.length < 40 || overall.length < 80) return 'too_short';
  // PHASE C1.1: 50, not 70 — the old floor forced a long overall even on a
  // thin cup, i.e. padding or invented content.
  const leadFloor = input.narrativelySparse ? COFFEE_MIN_LEAD_WORDS_SPARSE : COFFEE_MIN_LEAD_WORDS;
  if (wordCount(overall + ' ' + observation) < leadFloor) return 'too_short';
  if (
    crossSectionRepetition([
      observation,
      overall,
      input.love,
      input.career,
      input.money,
      input.nearFuture,
      takeaway,
    ])
  ) {
    return 'duplicate_sections';
  }
  if (COFFEE_STOCK.test(foldTr(overall)) || COFFEE_STOCK.test(foldTr(takeaway))) {
    return 'repeated_stock';
  }
  if (COFFEE_STOCK.test(foldTr(joinSections(input)))) {
    return 'repeated_stock';
  }
  if (closingQuestionHabit(overall, takeaway)) return 'closing_question_habit';
  if (boilerplateClosingQuestion(overall, takeaway)) {
    return 'closing_question_habit';
  }
  // PHASE C1.5: section substance, not an aggregate quota. The old total
  // (100 -> 70 words) rejected a concise, high-quality real reading at 62
  // words; a total only rewards padding. Each required interpretation
  // section must be substantive on its own instead.
  const overallFloor = input.narrativelySparse ? COFFEE_MIN_OVERALL_WORDS_SPARSE : COFFEE_MIN_OVERALL_WORDS;
  const takeawayFloor = input.narrativelySparse ? COFFEE_MIN_TAKEAWAY_WORDS_SPARSE : COFFEE_MIN_TAKEAWAY_WORDS;
  if (wordCount(overall) < overallFloor) return 'too_short';
  if (takeaway && wordCount(takeaway) < takeawayFloor) return 'too_short';
  // PHASE C1.7: the stock idea is "yeni (bir) başlangıç" filler, not the
  // ordinary noun — a road reading legitimately says where the road starts
  // ("başlangıcı", "başlangıç noktası") several times.
  if (repeatKeyIdea(joinSections(input), ['bulusma', 'yeni (bir )?baslangic', 'bir araya'])) {
    return 'repeated_stock';
  }
  if (repeatKeyIdea(overall + ' ' + takeaway, ['bulusma', 'sicak'])) {
    return 'repeated_stock';
  }
  const blob = joinSections(input);
  if (SCHEMA_JARGON.test(blob)) return 'schema_jargon_leak';
  if (!input.hasMemoryContext && FAKE_MEMORY_CLAIM.test(foldTr(blob))) {
    return 'fake_memory';
  }
  // The interpretation sections (never visualObservation itself, which is
  // allowed to be a brief scene-setting paraphrase) must not read as a
  // cup-position/residue report — real interpretive prose may mention a
  // region or shape in passing, but always in service of a meaning.
  const interpretationSections = [overall, input.love, input.career, input.money, input.nearFuture, takeaway]
    .filter((s) => s.trim().length > 0);
  const obsVocab = [COFFEE_REGION, COFFEE_DENSITY, COFFEE_SHAPE, OBSERVATION_VERB];
  const bareSections = interpretationSections.filter((s) =>
    isBareObservationSection(s, obsVocab, coffeeSectionMeaningful),
  );
  if (bareSections.length >= 2) return 'observation_heavy';
  if (observation.length > 320 && bareSections.length >= 1) return 'observation_heavy';
  if (CERTAINTY.test(foldTr(blob))) return 'unsupported_certainty';
  if (MEDICAL.test(foldTr(blob))) return 'prohibited_claim';
  const interpretation = [
    overall,
    input.love,
    input.career,
    input.money,
    input.nearFuture,
    takeaway,
  ];
  if (hasStockAdvice(interpretation)) return 'stock_advice';
  if (themeDominates(input.relevantThemes, interpretation)) return 'theme_domination';
  if (ideaClusterRepeats(interpretation)) return 'section_redundancy';
  if (coffeeInsightCollapse(overall, input.nearFuture, takeaway, input.singleSemanticAnchorRoots)) {
    return 'section_redundancy';
  }
  if (coffeeSemanticCollapse(overall, input.nearFuture, takeaway)) return 'insight_collapse';
  if (
    input.narrativelySparse
      ? coffeeSparseTakeawayEcho(overall, takeaway)
      : coffeeTakeawayEcho(overall, takeaway)
  ) {
    return 'section_redundancy';
  }
  const locale = localeMarkerFailure(blob, input.language);
  if (locale) return locale;
  if (input.language === 'en' || input.language === 'ru') return null;
  const voice = coffeeVoiceFailure(
    interpretation,
    input.groundedSigns,
    input.communicationAffordance,
    input.sparseContextAnchored,
  );
  if (voice) return voice;
  if (coffeePossibilityMenu(interpretation)) return 'possibility_menu';
  if (coffeeInventedPlan(interpretation)) return 'invented_plan';
  if (coffeeRepeatedSentence(interpretation)) return 'repeated_sentence';
  if (coffeeCupMetaTalk(interpretation)) return 'cup_meta_talk';
  if (coffeeDictionaryVoice(interpretation)) return 'dictionary_voice';
  if (coffeeGeometryInference(interpretation)) return 'geometry_inference';
  if (coffeeContextSequence(interpretation)) return 'context_sequence';
  if (coffeeAdviceVoice(interpretation)) return 'advice_voice';
  return null;
}

// ---------------------------------------------------------------------------
// Story-first closure — interpretation menus and invented plans (Turkish,
// coffee only). Real QA: the prompt ban alone still let "kısa bir yolculuk,
// gidip gelmeli bir iş veya yer değişikliği" and "kazanç ya da maddi fayda"
// reach users. Narrow on purpose: "ya da / veya" is ordinary Turkish in
// idioms, number ranges and lists of what the cup does NOT show.
// ---------------------------------------------------------------------------

/**
 * Idioms / approximate counts that use the connector without offering
 * readings, and the handle side's traditional single domain (ev / yakın çevre).
 */
const MENU_IDIOM =
  /\b(er (ya da|veya) gec|az (ya da|veya) cok|su (ya da|veya) bu|(bir|iki|uc|dort|bes|birkac) (ya da|veya) (iki|uc|dort|bes|alti|birkac)|ev\w*( icinden| icinde)? (ya da|veya) (cok )?yakin\w*( cevre\w*)?)\b/g;

const MENU_CONNECTOR = /\b(ya da|veya)\b/g;

/** A negated clause lists what is absent — not a menu of readings. */
const MENU_NEGATED =
  /\w+(mamis|memis|madi|medi|miyor|muyor|maz|mez|mayacak|meyecek|mayan|meyen)\b|\bdegil\b|\byok\b/;

const MENU_RESEMBLANCE = /andir|benz|formun|seklin/;

const MENU_ISTER = /\bister\b(?! istemez)[^.!?]{1,80}\bister\b/;
const MENU_OLABILIR = /\bolabilir\b[^.!?]{1,80}\bolabilir\b/;

/** The first interpretation menu found (folded text), or null. Exposed for tests/QA. */
export function coffeePossibilityMenu(sections: string[]): string | null {
  for (const sentence of filled(sections).map(foldTr).flatMap(sentencesOf)) {
    const s = sentence.replace(MENU_IDIOM, ' ');
    const fixed = MENU_ISTER.exec(s) ?? MENU_OLABILIR.exec(s);
    if (fixed) return fixed[0];
    for (const m of s.matchAll(MENU_CONNECTOR)) {
      const clause = s.slice(m.index).split(/[,;:]/)[0];
      if (MENU_NEGATED.test(clause)) continue;
      // Naming what a shape resembles ("çaydanlık veya demlik formunu andırıyor")
      // is a visual hedge, not a menu of life readings.
      if (MENU_RESEMBLANCE.test(clause)) continue;
      return s.slice(Math.max(0, m.index - 48), m.index + 48).trim();
    }
  }
  return null;
}

/**
 * A definite / possessed / resumed plan, or one "coming out of" a place —
 * the reading presupposes a plan the cup never showed.
 */
const COFFEE_PRIOR_PLAN =
  /\b(elindeki|mevcut|yarim (kalmis|kalan)|yarida kalan|eski|ertelenmis|bekleyen)( bir)? plan|\bplan(in|ini|inin|inda|indan|i|lar(in|ini|inin))\b|\bplan\w* (devam|yeniden|tekrar)|\b(evinden|evden|cevrenden|yakinindan|icinden) (cikan|gelen|dogan)( bir)? plan/;

export function coffeeInventedPlan(sections: string[]): boolean {
  return filled(sections).some((s) => COFFEE_PRIOR_PLAN.test(foldTr(s)));
}

/**
 * Two interpretation sentences of one reading carrying nearly the same
 * content words. Stems, not phrases: catches a restated sentence whatever
 * its wording, never ordinary shared words (needs >= 5 shared stems and
 * most of the shorter sentence).
 */
export function coffeeRepeatedSentence(sections: string[]): string | null {
  const sentences = filled(sections).map(foldTr).flatMap((t) => t.split(/(?<=[.!?])\s+/));
  const stems = sentences.map((x) => new Set(x.split(/[^a-z0-9]+/).filter((w) => w.length >= 5).map((w) => w.slice(0, 6))));
  for (let i = 0; i < stems.length; i++) {
    for (let j = i + 1; j < stems.length; j++) {
      const shared = [...stems[i]].filter((stem) => stems[j].has(stem)).length;
      const smaller = Math.min(stems[i].size, stems[j].size);
      if (shared >= 5 && shared / smaller >= 0.6) return sentences[j];
    }
  }
  return null;
}

/**
 * The cup as the subject of a negated telling / detail-giving verb, or
 * personified as speaking quietly — meta commentary on how much the cup
 * says, used to pad a sparse reading.
 */
const CUP_META_NEGATED =
  /\bfincan\w*\b[^.!?;]{0,40}\b(fazla|pek|cok|buyuk|belirgin|net|kesin|ayrintili|guclu|tek bir)\b[^.!?;]{0,25}\b(ayrinti|detay|soz|isaret|olay|yon|sonuc)\w*\b[^.!?;]{0,30}\b(vermiyor|vermemis|vermez|gostermemis|gostermiyor|soylemiyor|soylememis|anlatmiyor|anlatmamis)\b/;

const CUP_META_SPEAKS = /\bfincan\w* (sakin|sessiz|az|pek|fazla|cok|yavas)\w* (konus|anlat|soyl)/;

/**
 * Absence as content: the cup LACKING a figure / shape / sign used as the
 * reading's material ("fincanda belirgin bir figür olmadığı için …").
 * Structure, not wording: cup + sign noun + absence predicate. An honest
 * single-point limit ("ne zaman olacağını fincan göstermiyor") has no sign
 * noun and is not caught.
 */
const CUP_META_ABSENCE =
  /\bfincan\w*\b[^.!?;]{0,40}\b(figur|sekil|isaret|sembol|imge)\w*\b[^.!?;]{0,20}\b(yok|olmadig|olmamas|cikmadig|cikmamis|gorunmedig|bulunmadig|belirmedig|belirmemis)/;

/**
 * Cup as narrator: "fincan" itself (not "fincanın / fincanda") is the
 * subject of a NEGATED telling verb — the reading commenting on its own
 * restraint ("bu fincan kalabalık bir hikâye anlatmıyor", "fincan burada
 * sonucu büyütmüyor", "fincan büyük bir olay vaat etmiyor").
 */
const CUP_AS_NARRATOR =
  /\bfincan\b[^.!?;:]{0,60}\b(anlat|soyle|buyut|ver|kur|vaat et|goster|sun|aci)(miyor|muyor|mez|maz|memis|mamis)\b/;
/**
 * …unless its object is ONE specific unresolved fact (a wh-clause):
 * "ne zaman olacağını fincan göstermiyor", "haberin ne yönde olduğunu".
 */
const CUP_SPECIFIC_LIMIT =
  /\b(ne zaman|nereye|nerede|nereden|kim(in|i|e|den)?|hangi\w*|ne yon\w*|nasil|ne oldug\w*|ne olacag\w*|kac)\b/;

/**
 * READING SELF-REFERENCE (concept, not phrases): the sentence's subject is
 * the reading itself — the story / fal / narrative / interpretation, or what
 * "here" in the reading contains or lacks — and it describes that reading's
 * structure instead of the person's life.
 *
 * (a) a reading noun + a "what it is about / how it is built" predicate:
 *     "fincandaki hikâye esas olarak … üzerine kurulmuş", "falın ana sözü".
 * (b) a reading noun + a size / complexity predicate: "hikâye sade",
 *     "kalabalık bir hikâye", "uzun bir anlatı".
 * (c) "here / in the cup" + an event-or-figure noun + absence:
 *     "burada belirgin bir olay şekli yok".
 * Ordinary falcı use of the cup as evidence ("kuş fincanın ağzına yakın",
 * "falında bir yol var", "fincanın dibi temiz") has no such predicate.
 */
// foldTr keeps "â": hikâye / hikaye. "anlatı" only as the noun, never the
// verb "anlatılan / anlatıyor".
const STORY = 'hik[aâ]ye\\w*|anlati(si|nin|yi|ya|da|daki)?\\b';
const READING_NOUN = new RegExp(`\\b(${STORY}|fal|falin|fali|falda|falinda|falinin|yorumun)\\b`);
const READING_ABOUT = new RegExp(
  `uzerine kurul\\w*|esas olarak|asil olarak|etrafinda (don|kur|sekillen|topla)\\w*|hakkinda|odaklan\\w*|yogunlas\\w*|merkezinde|\\bdayan\\w*|\\b(ana|asil|esas|temel) (${STORY}|soz|tema|mesaj|konu)`,
);
const READING_SIZE = new RegExp(
  `\\b(sade|basit|yalin|kalabalik|karmasik|kisa|uzun|buyuk|kucuk|dar|genis)( bir)? (${STORY}|fal\\b)|\\b(${STORY}|fal\\b)\\w* (sade|basit|yalin|kalabalik|karmasik|kisa|uzun|dallanmiyor|dagilmiyor)\\b`,
);
const HERE_ABSENCE = new RegExp(
  `\\b(burada|fincanda|bu fincanda)\\b[^.!?;]{0,40}\\b(olay|figur|sekil|isaret|${STORY}|gelisme|sembol)\\w*\\b[^.!?;]{0,20}\\b(yok|olmadig\\w*|olmamas\\w*|gorunmuyor|cikmamis|cikmamas\\w*|cikmadig\\w*|belirmemis)`,
);

/**
 * (d) the cup (bare subject) DOING or NOT DOING something to the story — it
 *     "does not invent / decorate / force / list promises / talk big", or
 *     "speaks quietly" with words in between ("fincan burada sakin konuşuyor").
 * (e) what the reading or the cup EMPHASIZES / is about: "bu fincanın sözü
 *     … üzerine", "falın sözü … toplanmış", "başrolünde", "burada asıl
 *     vurgu", "… bu falda / bu fincanda öne çıkıyor".
 * (f) the reading's own mood: "falın sessiz … bir havası var".
 */
const CUP_RESTRAINT =
  /\bfincan\b[^.!?;:]{0,50}\b(uydur|susle|sirala|zorla|abart|buyut|laf\w* et|vaat\w* et|soz et)(miyor|muyor|mez|maz|memis|mamis)\b|\bfincan\b[^.!?;:]{0,20}\b(sakin|sessiz|az|yavas)\w* (konus|anlat|soyl)\w*|\bfincan\b[^.!?;:]{0,40}\b(buyuk|sade)\w* (gosteri|laf|olay)\w*[^.!?;:]{0,30}\b(degil|anlatmis|anlatiyor)/;
const READING_EMPHASIS =
  /\b(fincanin|falin|bu fincanin)( ana| asil| esas| en \w+)? (sozu|hali|basrolunde|baskin tarafi)\b|\b(asil|esas|ana) vurgu\w*|\bbu (falda|fincanda)\b[^.!?;:]{0,30}\bone cik\w*|\b(falin|fali)\b[^.!?;:]{0,130}\b(uzerinde|cevresinde|etrafinda) (duruyor|kaliyor|toplaniyor|donuyor)/;
const READING_MOOD = /\b(falin|fincanin|hikayenin|hikâyenin)\b[^.!?;:]{0,50}\bhavasi (var|tasiyor)/;

export function coffeeReadingSelfReference(sentence: string): boolean {
  if (HERE_ABSENCE.test(sentence) || CUP_RESTRAINT.test(sentence)) return true;
  if (READING_EMPHASIS.test(sentence) || READING_MOOD.test(sentence)) return true;
  if (!READING_NOUN.test(sentence)) return false;
  return READING_ABOUT.test(sentence) || READING_SIZE.test(sentence);
}

export function coffeeCupMetaTalk(sections: string[]): string | null {
  for (const sentence of filled(sections).map(foldTr).flatMap(sentencesOf)) {
    if (CUP_META_NEGATED.test(sentence) || CUP_META_SPEAKS.test(sentence) || CUP_META_ABSENCE.test(sentence)) {
      return sentence;
    }
    if (CUP_AS_NARRATOR.test(sentence) && !CUP_SPECIFIC_LIMIT.test(sentence)) return sentence;
    if (coffeeReadingSelfReference(sentence)) return sentence;
  }
  return null;
}

/**
 * A topology shape (road, bridge, line, curve, crossing) given a cause, an
 * agent controlling another, or a relationship role. Geometry shows a
 * course or a link — never WHY it bends, who steers whom, or who carries
 * the bond. Only sentences that talk about a topology shape are checked.
 */
const TOPOLOGY_NOUN = /\b(yol|kopru|cizgi|kivrim|baglanti|gecis)\w*/;
const GEOMETRY_CAUSE =
  // Direction / control only as one side ACTING ON ANOTHER ("ötekinin
  // yönünü belirleyecek", "biri diğerini yönlendiriyor"); a road or a
  // development having a direction ("yönünü belirleyecek gelişme",
  // full12_run9 ROAD) is a normal course reading.
  /(sartlara|kosullara|duruma|ihtiyaca) gore|yuzunden|nedeniyle|sebebiyle|\bkontrol\w*|\byonlendir\w*|\b(otekinin|digerinin|oburunun|karsi tarafin|obur tarafin) (yonunu|gidisatini|kaderini) (de )?(belirle|tayin|degistir)\w*|\b(biri|birisi|bir taraf\w*)\b[^.!?;]{0,30}\b(digerini|otekini|oburunu|karsi tarafi)\b[^.!?;]{0,20}\b(yonlendir|etkile|belirle|cek)\w*|tek basina tasi\w*|yuku\w* (paylas|tasi)\w*|esit (emek|caba|pay)|ayni (emegi|cabayi)|iki tarafi da tutan/;

export function coffeeGeometryInference(sections: string[]): string | null {
  // Section-level: the claim often follows the shape in the next sentence
  // ("… ince bir bağlantı kuruluyor. … Birindeki hareket, ötekinin yönünü
  // de belirleyecek.").
  for (const section of filled(sections).map(foldTr)) {
    if (!TOPOLOGY_NOUN.test(section)) continue;
    const claim = sentencesOf(section).find((sentence) => GEOMETRY_CAUSE.test(sentence));
    if (claim) return claim;
  }
  return null;
}

/**
 * Context given chronology: a sentence about scattering / dots / faint
 * marks / the base that adds an order of events ("peş peşe", "ardından",
 * "sırayla", "önce … sonra", "art arda"). The real sign beside it may carry
 * the event; context may only qualify it. A sentence that talks about a
 * topology shape is left alone — a road may carry a sequence.
 */
// \bsilik: unbounded "silik" matched inside "karşılık" (targeted16 BIRD repair).
const CONTEXT_NOUN = /serpis|serpil|dagin|dagil|\bnokta\w*|benek|zerre|\bleke\w*|\bsilik|\bdip\w*|\bdib\w*|yogun/;
const CONTEXT_SEQUENCE_WORD = /pes pese|\bardindan\b|\bsirayla\b|art arda|birbiri ardina|\bonce\b|\bsonra(dan)?\b|\bzincir\w*/;

export function coffeeContextSequence(sections: string[]): string | null {
  for (const sentence of filled(sections).map(foldTr).flatMap(sentencesOf)) {
    if (TOPOLOGY_NOUN.test(sentence)) continue;
    if (CONTEXT_NOUN.test(sentence) && CONTEXT_SEQUENCE_WORD.test(sentence)) return sentence;
  }
  return null;
}

/**
 * Advice / imperative addressed to the person — a fortune tells what is
 * coming, it does not instruct (targeted14 HANDLE: "gözün kulağın yakınında
 * olsun"). Second-person imperatives and "-malısın" obligations only;
 * ordinary future statements and a falcı's "bak," interjection pass.
 */
const COFFEE_ADVICE =
  /goz\w* kulag\w*[^.!?;]{0,25}\bolsun\b|\bdikkat et\b|\bdikkatli ol\b|\bacele etme\b|\bkacirma\b|\bgozden kacirma\b|\bkucumseme\w*|\bhazir ol\b|\bihmal etme\b|\bunutma\b|\bsabirli ol\b|\bdegerlendir\b|\baklinda (tut|bulunsun)\b|\bkendine (iyi bak|zaman ayir)\b|\b\w+(meli|mali)(sin|siniz)\b/;

/**
 * The person's current expectation, wish or prior thought presumed without
 * personalization: "beklediğin", "merak ettiğin", "uzun zamandır
 * düşündüğün", "zaten bildiğin", "tahmin ettiğinden", "düşündüğünden",
 * "istediğin", "umduğun", "hayal ettiğin". Calibrated on all saved runs:
 * every hit was a presumption; no GOOD fixture uses one.
 */
const COFFEE_PRESUMED_STATE =
  /\b(bekledig\w*|beklerken|bekliyor(ken|sun|sunuz)?|beklemekte(sin|siniz)|merak ettig\w*|uzun (zamandir|suredir) dusundug\w*|zaten bildig\w*|tahmin ettig\w*|dusundugun\w*|istedigin\w*|umdugun\w*|hayal ettig\w*|san(abilirsin|iyorsun|irsin|digin\w*)|(ayri|farkli|uzak) tuttug\w*|(farkli|ayri|oyle) gordug\w*|oyle dusundug\w*|(sikisiklik|endise|huzursuzluk|yorgunluk|kaygi|gerginlik|bunalti|sikinti) hiss(in|i)?[^.!?;]{0,30}(azal\w*|hafifli\w*|gec\w*|dagil\w*|suruyor|devam ediyor))\b/;

/**
 * Story-first closure: home / close-circle language. Evidence-aware use only
 * (coffeeQualityFailure): allowed when the cup has a handle-side cue or the
 * personalization is about home / family; a TREE or a STAR does not
 * become family by itself (full12_run10 TREE: "ev ve yakın çevrene…").
 */
const COFFEE_HOME_DOMAIN =
  /\bev(in|ine|inde|inden|e|de|den|i|le|imiz)?\b|\bev hal\w*|\baile\w*|yakin cevre\w*|\byakinlar\w*|yakin oldugun\w*|en yakin\w* (insan|kisi|halka|cevre)\w*|yakin halka\w*/;

export function coffeeHomeDomainClaim(sections: string[]): string | null {
  for (const sentence of filled(sections).map(foldTr).flatMap(sentencesOf)) {
    if (COFFEE_HOME_DOMAIN.test(sentence)) return sentence;
  }
  return null;
}

/**
 * Story-first closure: a SPECIFIC other person's attitude, decision,
 * intention, initiative or reaction (full12_run10 RING: "karşındaki kişinin
 * tavrı, aranızdaki bağın yerini belirleyecek"). Mutuality ("karşılıklı
 * bağ", "iki tarafı birleştiren bağ") is not agency and passes.
 */
const COFFEE_OTHER_AGENCY =
  /karsi(ndaki)? (kisi|insan|taraf)\w* (tavri|tavrin\w*|karar\w*|niyet\w*|tepki\w*|adim\w*|tutum\w*)|karsindaki (kisi|insan)\w*[^.!?;]{0,40}\b(belirle|karar ver|adim at|niyet|tavr|tepki)\w*|karsi taraf\w*[^.!?;]{0,20}\b(belirleyecek|karar verecek|adim atacak|harekete gececek|ilk adimi)\w*|\bonun (niyeti|karari|tavri|tepkisi)\w*|\bo (adim atacak|karar verecek|ilk adimi atacak)\b/;

export function coffeeOtherAgency(sections: string[]): string | null {
  for (const sentence of filled(sections).map(foldTr).flatMap(sentencesOf)) {
    if (COFFEE_OTHER_AGENCY.test(sentence)) return sentence;
  }
  return null;
}

export function coffeePresumedUserState(sections: string[]): string | null {
  for (const sentence of filled(sections).map(foldTr).flatMap(sentencesOf)) {
    if (COFFEE_PRESUMED_STATE.test(sentence)) return sentence;
  }
  return null;
}

const COFFEE_EXISTING_FACT =
  /\b(bir suredir[^.!?;]{0,45}(sessiz|duran|bekleyen|sur(en|uyor)|devam eden)\w*|zaten (devam eden|suren|baslamis)\w*|uzun zamandir[^.!?;]{0,35}(suren|devam eden)\w*|basladigin (bir )?(ugras|is|calisma|proje)\w*|uzerinde calistigin\w*|yarim kalan\w*|gecmisten gelen\w*|daha once baslayan\w*)\b/;

export function coffeeUnsupportedExistingFact(sections: string[]): string | null {
  for (const sentence of filled(sections).map(foldTr).flatMap(sentencesOf)) {
    if (COFFEE_EXISTING_FACT.test(sentence)) return sentence;
  }
  return null;
}

const COFFEE_SOURCE_CAUSATION =
  /\b(yakinlar(in)?dan|aile(n|m|miz)?den|ev cevre(n|m|miz)?den|karsi taraftan)\b[^.!?;]{0,24}\b(kaynaklan|dogan|doguyor|baslayan|basliyor|gelen)\w*/;

export function coffeeUnsupportedSourceCausation(sections: string[]): string | null {
  for (const sentence of filled(sections).map(foldTr).flatMap(sentencesOf)) {
    if (COFFEE_SOURCE_CAUSATION.test(sentence)) return sentence;
  }
  return null;
}

export function coffeeAdviceVoice(sections: string[]): string | null {
  for (const sentence of filled(sections).map(foldTr).flatMap(sentencesOf)) {
    if (COFFEE_ADVICE.test(sentence)) return sentence;
  }
  return null;
}

/** "… -e yorulur" / "… olarak yorumlanır": the dictionary verb, not a falcı's "derler". */
const COFFEE_DICTIONARY_VERB = /\b(yorulur|yorumlanir|yorumlanabilir)\b/;

export function coffeeDictionaryVoice(sections: string[]): string | null {
  for (const sentence of filled(sections).map(foldTr).flatMap(sentencesOf)) {
    if (COFFEE_DICTIONARY_VERB.test(sentence)) return sentence;
  }
  return null;
}

export type CoffeeSecondaryDefect =
  | 'possibility_menu'
  | 'invented_plan'
  | 'repeated_sentence'
  | 'cup_meta_talk'
  | 'dictionary_voice'
  | 'geometry_inference'
  | 'context_event'
  | 'context_sequence'
  | 'plain_line_relocation'
  | 'advice_voice'
  | 'presumed_user_state'
  | 'unsupported_existing_fact'
  | 'unsupported_source_causation'
  | 'unsupported_home_domain'
  | 'unsupported_other_agency';

/**
 * Coffee repair preparation: the deterministic story-first defects present
 * in the interpretation sections, using the SAME detectors as the gate.
 * Internal repair guidance only — never a public BindFailure.
 */
export function coffeeSecondaryDefects(
  sections: string[],
): Array<{ defect: CoffeeSecondaryDefect; found: string | null }> {
  const out: Array<{ defect: CoffeeSecondaryDefect; found: string | null }> = [];
  const menu = coffeePossibilityMenu(sections);
  if (menu) out.push({ defect: 'possibility_menu', found: menu });
  if (coffeeInventedPlan(sections)) out.push({ defect: 'invented_plan', found: null });
  const repeated = coffeeRepeatedSentence(sections);
  if (repeated) out.push({ defect: 'repeated_sentence', found: repeated });
  const meta = coffeeCupMetaTalk(sections);
  if (meta) out.push({ defect: 'cup_meta_talk', found: meta });
  const dictionary = coffeeDictionaryVoice(sections);
  if (dictionary) out.push({ defect: 'dictionary_voice', found: dictionary });
  const geometry = coffeeGeometryInference(sections);
  if (geometry) out.push({ defect: 'geometry_inference', found: geometry });
  const sequence = coffeeContextSequence(sections);
  if (sequence) out.push({ defect: 'context_sequence', found: sequence });
  const advice = coffeeAdviceVoice(sections);
  if (advice) out.push({ defect: 'advice_voice', found: advice });
  return out;
}

// ---------------------------------------------------------------------------
// PHASE C1 — Coffee fortune-teller voice (Turkish). Coffee only; Palm never
// calls into this section. Category lexicons, not sentence blacklists: each
// entry is one *kind* of language, and a reading fails only when a kind
// dominates, never on a single word.
// ---------------------------------------------------------------------------

/**
 * Residue-physics / vision-report vocabulary. A fortune teller names what
 * she sees in plain words ("telve dibe çökmüş", "bir kuş var"); a report
 * talks about density, thinning, surfaces, curves and open areas.
 */
const COFFEE_LAB =
  /yogunlu[gk]|yogun (tortu|kume|telve|iz|alan|birikinti|kisim|bolge)|seyrel|seyrek|birikinti|tortu|\bkume|\bdoku|ic yuzey|yuzey(de|in|deki|e)\b|kavis|kivrim|\bbant|acik (bir )?(alan|hat|bolge)|koyu (bir )?(alan|bolge|leke)|\biz(ler|leri|lerin|ler)?\b|hizada|ayni hiza|egim/;

/** Therapy / coaching / mindfulness register — one regex per kind. */
const COFFEE_COACH_KINDS: RegExp[] = [
  /ic (agirlik|yuk|ses|dunya|huzur|denge)/,
  /zihn(in|inde|ini|inin)|zihinsel/,
  /sinir(ini|larini|ina|lar)? (koy|koru|cek|ciz|belirle)|sinirini|kendi sinirin/,
  /kisisel (bir )?alan|kendi alan|kendine (bir )?alan/,
  /ritm|ritim|tempo/,
  /oncelik/,
  /netlestir|netlik|berraklik|netles/,
  /sadelestir|sadeles/,
  /geride birak|akisina birak|akisa birak/,
  /olculu|dengele/,
  /farkindalik|fark etmek|farkina var|fark edebil/,
  /nefes al|nefesini|nefes alacag/,
  /kontrol (altinda|etme|arzu)/,
  /aitlik|ait oldug|baglilig/,
  /\besik/,
  /gerilim|sikisiklik|sikisma/,
  /kendi adim|kendi yerin|kendi gun|gundelik duzen|gun dilim/,
  /isine yarayabilir|somut ipucu|esas mesaj|asil mesaj|biraktigi (asil |esas )?mesaj|sundugu .{0,24}ipucu|hatirlatiyor|davet ediyor/,
  /yuk(un|unu|u)? (bosalt|tasi|hafiflet)|yukunu|agirlik yap|bir agirlik/,
  /kendini (dinle|koru|ifade)|kendine (iyi bak|zaman)/,
  /icsel|duygusal yuk/,
  /\bsurec/,
  /ayakta kal|yer degistir|ikinci planda/,
];

/** Concrete human-life developments — one regex per kind. */
const COFFEE_LIFE_KINDS: RegExp[] = [
  /\b(anne|baba|kardes|abla|abi|teyze|hala|dayi|amca|esin|sevgili|arkadas|komsu|akraba|misafir|kadin|erkek|tanidik|patron|mudur|cocug|kayinvalide|yenge|ev halk|aile)/,
  /\bbiri(si|nin|ni|ne|yle|nden|leri)?\b|birileri/,
  /haber|mesaj|telefon|arama|mujde|mektup|dedikodu|soz (ver|kes)/,
  /\byol(a|da|u|un|culuk|lar)?\b|seyahat|tasin|ziyaret|gelis|gidis|kapini cal/,
  /\bdugun|\bnisan|kutlama|toplanti|sofra|bulus|karsilas|gorusme|davet|kalabalik/,
  /\bpara|kazanc|odeme|alacak|borc|hediye|alisveris|maas|kira|evrak|imza|sinav|mulakat|teklif|\bis (yeri|degis|gorus)/,
  /\bev(in|e|de|den|le|iniz)?\b|evine|evinde|evden/,
  /kismet|nazar|kiskan|\bsirr?(in|i|ini)?\b|surpriz|sevin|yuzunu guldur|keyif/,
  /\bask|gonul|sevdig/,
  /\bplan/,
  /konusma|sohbet/,
];

/** Abstract theme families that turn into soup when they fill every section. */
const COFFEE_ABSTRACT_FAMILIES: RegExp[] = [
  /\byuk|agirlik/,
  /sinir|kendi alan|kisisel alan|koruma/,
  /netles|netlik|berrak|aciklik/,
  /ritm|ritim|tempo|nefes/,
  /karar|secim|tercih|secenek/,
  /degisim|donusum|\besik|kayma|yer degis/,
];

function sentencesOf(text: string): string[] {
  return text
    .split(/(?<=[.!?;])\s+/)
    .map((s) => s.trim())
    .filter((s) => s.length > 0);
}

function kindHits(text: string, kinds: RegExp[]): number {
  return kinds.filter((kind) => kind.test(text)).length;
}

/**
 * PHASE C1.1: the falcı's own anchors — the cup and its signs in plain
 * words. A sparse reading that stays with these is grounded even when it
 * names no life event at all; prose with neither these nor any life
 * content is floating abstraction.
 */
const COFFEE_SIGN =
  /telve|fincan|\bdib|\bagz|kulb|kulp|\bkus\b|kusu|\bkuslar|\byol(lar|u|un)?\b|balik|yuzuk|halka|kalp|agac|\bdag\b|anahtar|merdiven|\bgoz\b|yilan|\bat\b|kopek|kedi|kelebek|cicek|\bay\b|yildiz|gunes|harf|demlik|gemi|kopru|\btac\b|\bmum\b|cizgi|sekil/;

/**
 * PHASE C1.1: distinct predicted-event domains. Used only to stop a
 * reading from STACKING unrelated predictions on generic residue — never
 * as a minimum. Home/close circle is deliberately not a domain: it is the
 * traditional reading of the handle side, a place, not an extra event.
 */
const COFFEE_EVENT_DOMAINS: RegExp[] = [
  /misafir|ziyaret|cikagel|kapini cal|kapina gel/,
  /haber|mesaj|telefon|mujde|mektup/,
  /yolculuk|seyahat|tasin|yola cik/,
  /\bdugun|\bnisan|kutlama|sofra|davet|toplanti|kalabalik bir aksam/,
  /\bpara|kazanc|odeme|alacak|borc|maas|kira|hediye/,
  /teklif|mulakat|terfi|is degis|is gorus|yeni bir is/,
  /\bask\b|\bask(in|a|i|ta)\b|gonul|sevgili|evlilik/,
];

export type CoffeeVoiceProfile = {
  sentences: number;
  labSentences: number;
  labLedSections: number;
  coachKinds: number;
  lifeKinds: number;
  signKinds: number;
  eventDomains: number;
  soupFamilies: number;
};

/** Exposed for tests/QA: the raw counts behind coffeeVoiceFailure. */
export function coffeeVoiceProfile(sections: string[]): CoffeeVoiceProfile {
  const body = filled(sections).map(foldTr);
  const all = body.join(' ');
  const sentences = body.flatMap(sentencesOf);
  const labSentences = sentences.filter((s) => COFFEE_LAB.test(s)).length;
  const labLedSections = body.filter((s) => COFFEE_LAB.test(sentencesOf(s)[0] ?? '')).length;
  const soupFamilies = COFFEE_ABSTRACT_FAMILIES.filter(
    (family) => body.length >= 3 && body.filter((s) => family.test(s)).length >= 3,
  ).length;
  return {
    sentences: sentences.length,
    labSentences,
    labLedSections,
    coachKinds: kindHits(all, COFFEE_COACH_KINDS),
    lifeKinds: kindHits(all, COFFEE_LIFE_KINDS),
    signKinds: COFFEE_SIGN.test(all) ? 1 : 0,
    eventDomains: kindHits(all, COFFEE_EVENT_DOMAINS),
    soupFamilies,
  };
}

/**
 * Structural fortune-teller voice gate for the Coffee interpretation
 * sections (never visualObservation, which is the caption).
 *
 * PHASE C1.1: every rule here judges STYLE. None of them can be escaped by
 * adding predicted events, and none of them requires a minimum number of
 * events — a sparse cup may give a short, quiet reading with one
 * development, or none beyond the sign itself.
 *
 * `groundedSigns` (optional) is the number of observer evidence items that
 * carry a resemblance. When supplied, a reading may not stack more
 * unrelated event domains than those signs can carry.
 */
export function coffeeVoiceFailure(
  sections: string[],
  groundedSigns?: number,
  communication?: boolean,
  sparseContextAnchored?: boolean,
): HumanQualityFailure | null {
  const p = coffeeVoiceProfile(sections);
  if (p.sentences === 0) return null;
  // Vision report: most sentences narrate residue physics, or several
  // sections open by describing residue before saying anything human.
  if (p.labSentences >= 3 && p.labSentences / p.sentences > 0.34) return 'observation_heavy';
  if (p.labLedSections >= 2) return 'observation_heavy';
  // Therapist / coach: three or more distinct self-help kinds. Independent
  // of how many events the reading predicts.
  if (p.coachKinds >= 3) return 'coaching_voice';
  if (p.soupFamilies >= 1) return 'abstract_soup';
  // Floating abstraction: neither the cup's signs nor anything in the
  // person's life — only moods and "this period" talk.
  // A narratively sparse reading anchored on its own cited context evidence
  // is grounded without a sign or a life event (evidence-derived flag).
  if (p.signKinds === 0 && p.lifeKinds === 0 && !sparseContextAnchored) return 'abstract_reading';
  // Event pile: generic residue turned into visitor + money + job + love.
  if (groundedSigns !== undefined && p.eventDomains > 2 + groundedSigns) return 'event_pile';
  // Generic wrapper: the reading's identity is carried by a vague issue
  // instead of this cup's signs (real C1.2 QA: 6/6 readings).
  if (coffeeGenericWrapper(sections, communication)) return 'generic_wrapper';
  return coffeeRegisterFailure(sections);
}

// ---------------------------------------------------------------------------
// PHASE C1.5 — delivery form. Real C1.4 QA: stories became evidence-specific
// but the DELIVERY templated — a meta-opener announcing the cup's "main
// word", "not X but Y" scaffolding, and a detached analyst register
// ("baskın görünüyor", "mevcut düzen", "şartları belli", "dışarıdan
// müdahale"). Every signal here is ordinary Turkish once; only an
// accumulation fails. Calibrated on the six real C1.4 outputs: the two
// product-WEAK readings score 8–10, the four product-PASS readings 3–4,
// every GOOD fixture ≤ 3.
// ---------------------------------------------------------------------------

/** Announcing the lane instead of reading: "Bu fincanın ana sözü …". */
const COFFEE_META_OPENER =
  /^(\w+, )?(bu )?fincanin (ana |asil |en belirgin |en baskin )?(sozu|hali|temasi|basrolunde|tarafi|meselesi|konusu)\b/;

/** "X'ten çok Y", "X'ten ziyade Y", "A yerine B", "X değil, Y". */
const COFFEE_CONTRAST = /\w+(dan|den|tan|ten) (cok|ziyade)\b|\w+ yerine\b|\bdegil[,;]/g;

/** Detached analyst / horoscope register — one regex per kind. */
const COFFEE_ANALYST_KINDS: RegExp[] = [
  /baskin (gorun|ol)/,
  /\bseyir/,
  /mevcut (duzen|durum)/,
  /sartlar(i)? (belli|belirle)/,
  /mudahale/,
  /\bduzen(i|in|e|de)?\b/,
  /yerlesik/,
  /\bdonem(de|i|in)?\b/,
  /\bdurum(u|un|da|a)?\b/,
  /yer degistir|kolay (kolay )?(oynama|degis)/,
  /\bgelisme/,
];

/** Interpretive hedge predicates (normal in moderation). */
const COFFEE_HEDGE =
  /(gosteriyor|dusunduruyor|isaret ediyor|soyluyor|anlatiyor|gorunuyor|cagristiriyor|isaret eder|gosterir)\b/;

/**
 * PHASE C1.7: a caution-led sentence says what is NOT happening — negation,
 * "rather than" contrasts, not-yet / not-immediate markers, negative verbs.
 * Normal once; the defect is a reading BUILT from them.
 */
const COFFEE_CAUTION =
  /\bdegil\b|\w+(dan|den|tan|ten) (cok|ziyade)\b|\byerine\b|\bhenuz\b|\bhemen\b|acele|\bsimdilik\b|\bbir sure daha\b|\w+(mi|mu)yor\b|\w+m(a|e)y(acak|ecek|abilir|ebilir)\w*|\bgorunmuyor|\byok\b/;

/** A "not yet / still waiting / not finished" close. */
const COFFEE_NOT_YET = /henuz|hemen|acele|bir sure daha|oldugu yerde|simdilik|sonuclanmay|kesinlesm|bekle/;

export type CoffeeRegisterProfile = {
  metaOpener: boolean;
  contrasts: number;
  analystKinds: number;
  hedgeSentences: number;
  sentences: number;
  /** analystKinds + contrast scaffolding + meta-opener + hedge narration */
  score: number;
  /** PHASE C1.7: sentences led by negation / not-yet / rather-than. */
  cautionSentences: number;
  /** PHASE C1.7: filled sections where caution leads at least half the sentences. */
  cautionSections: number;
  /** PHASE C1.7: filled interpretation sections. */
  sections: number;
  /** PHASE C1.7: the reading's last sentence is a not-yet / negated close. */
  notYetClose: boolean;
};

export function coffeeRegisterProfile(sections: string[]): CoffeeRegisterProfile {
  const body = filled(sections).map(foldTr);
  const all = body.join(' ');
  const sentences = body.flatMap(sentencesOf);
  const metaOpener = COFFEE_META_OPENER.test(sentencesOf(body[0] ?? '')[0] ?? '');
  const contrasts = (all.match(COFFEE_CONTRAST) ?? []).length;
  const analystKinds = kindHits(all, COFFEE_ANALYST_KINDS);
  const hedgeSentences = sentences.filter((s) => COFFEE_HEDGE.test(s)).length;
  const hedgeHeavy = sentences.length >= 5 && hedgeSentences / sentences.length >= 0.6;
  const cautionSections = body.filter((s) => {
    const ss = sentencesOf(s);
    return ss.length > 0 && ss.filter((x) => COFFEE_CAUTION.test(x)).length / ss.length >= 0.5;
  }).length;
  const last = sentencesOf(body[body.length - 1] ?? '').pop() ?? '';
  return {
    metaOpener,
    contrasts,
    analystKinds,
    hedgeSentences,
    sentences: sentences.length,
    score: analystKinds + (contrasts >= 3 ? 1 : 0) + (metaOpener ? 1 : 0) + (hedgeHeavy ? 1 : 0),
    cautionSentences: sentences.filter((s) => COFFEE_CAUTION.test(s)).length,
    cautionSections,
    sections: body.length,
    notYetClose: COFFEE_NOT_YET.test(last) || COFFEE_CAUTION.test(last),
  };
}

/** `sections[0]` must be overall. */
export function coffeeRegisterFailure(sections: string[]): HumanQualityFailure | null {
  const r = coffeeRegisterProfile(sections);
  if (r.sentences === 0) return null;
  // Analyst / horoscope register: several detached-register kinds stacked
  // with the formulaic devices around them.
  if (r.score >= 6) return 'analyst_voice';
  // Pure scaffolding: the reading is built on "not X but Y" turns, or a
  // hedge verb carries nearly every sentence.
  if (r.contrasts >= 5) return 'formulaic_voice';
  if (r.sentences >= 6 && r.hedgeSentences / r.sentences >= 0.75) return 'formulaic_voice';
  // PHASE C1.7: caution carries the structure — most sentences say what is
  // NOT happening, caution leads at least two-thirds of the sections, and
  // the reading closes on "not yet". All three together; any one is normal.
  if (
    r.sentences >= 5 &&
    r.cautionSentences / r.sentences >= 0.6 &&
    r.cautionSections * 3 >= r.sections * 2 &&
    r.notYetClose
  ) {
    return 'caution_voice';
  }
  return null;
}

// ---------------------------------------------------------------------------
// PHASE C1.7 — takeaway echo. On a low-evidence cup the takeaway may cite
// the same evidence as overall, but it must add a distinct nuance. Real C1.6
// HOLDOUT B restated overall's "tek başına kalan bir pürüz" as its takeaway.
// The existing collapse checks need three filled meaning sections or
// distinct clusters, so a two-section echo slipped through. Signal: the
// takeaway reuses two or more of overall's content-word pairs (i.e. the
// same multi-word description of the same thing), not merely shared nouns.
// ---------------------------------------------------------------------------

const ECHO_STOP = new Set([
  'bir', 'bu', 've', 'da', 'de', 'ile', 'cok', 'gibi', 'daha', 'icin', 'ama', 'ise',
  'the', 'and', 'of', 'a', 'to', 'in', 'is', 'that',
]);

function contentPairs(text: string): Set<string> {
  const words = foldTr(text)
    .split(/[^a-z]+/)
    .filter((w) => w.length >= 3 && !ECHO_STOP.has(w));
  const pairs = new Set<string>();
  for (let i = 0; i + 1 < words.length; i++) pairs.add(`${words[i].slice(0, 5)} ${words[i + 1].slice(0, 5)}`);
  return pairs;
}

export function coffeeTakeawayEchoPairs(overall: string, takeaway: string): string[] {
  if (!overall.trim() || !takeaway.trim()) return [];
  const fromOverall = contentPairs(overall);
  return [...contentPairs(takeaway)].filter((pair) => fromOverall.has(pair));
}

export function coffeeTakeawayEcho(overall: string, takeaway: string): boolean {
  return coffeeTakeawayEchoPairs(overall, takeaway).length >= 2;
}

/**
 * Story-first closure — the takeaway echo on a NARRATIVELY SPARSE cup.
 * Real targeted11 DOTS: the only evidence is "the clean band at the rim",
 * so "ağız kenar(ı)" and "temiz bant" are shared by any overall and any
 * takeaway about it — the evidence's own name, not a repeated idea (the
 * same false-positive mode as a single sign's name in insight collapse).
 * Those cup-place pairs do not count; a real paraphrase still fails:
 * two meaning pairs, or one meaning pair plus three shared meaning stems.
 */
const CUP_PLACE_WORD =
  /^(fincan|agi?z|kenar|dip|dib|kulp|kulb|temiz|bant|band|serit|nokta|telve|ust|alt|taraf|orta|yuzey|kisim|kism|bolum)/;

function meaningStems(text: string): Set<string> {
  return new Set(
    foldTr(text)
      .split(/[^a-z]+/)
      .filter((w) => w.length >= 5 && !ECHO_STOP.has(w) && !CUP_PLACE_WORD.test(w))
      .map((w) => w.slice(0, 5)),
  );
}

export function coffeeSparseTakeawayEcho(overall: string, takeaway: string): boolean {
  // Strictly narrower than coffeeTakeawayEcho: only a case the old rule
  // flags can fail here, and it is cleared only when cup-place pairs pushed
  // it over the threshold without a real shared meaning.
  const pairs = coffeeTakeawayEchoPairs(overall, takeaway);
  if (pairs.length < 2) return false;
  const meaningPairs = pairs.filter((pair) => !pair.split(' ').every((w) => CUP_PLACE_WORD.test(w)));
  if (meaningPairs.length >= 2) return true;
  const fromOverall = meaningStems(overall);
  const shared = [...meaningStems(takeaway)].filter((stem) => fromOverall.has(stem));
  return shared.length >= 3;
}

// ---------------------------------------------------------------------------
// PHASE C1.3 — generic narrative wrapper. Real provider QA showed every cup
// narrated as "an unnamed long-standing matter → a conversation → relief",
// with the actual sign hung on that frame. Structural, not a phrase list:
// one "konu" or "mesele" is normal Turkish; the wrapper is a vague issue
// leading the reading, generic issue nouns carrying it, or a talk-and-relief
// arc on a cup whose evidence affords no communication at all.
// ---------------------------------------------------------------------------

/** Unnamed issue nouns ("konuşma" is deliberately excluded). */
const COFFEE_GENERIC_ISSUE = /\bmesele\w*|\bkonu(nun|yu|da|ya|dan|n|su|sunu|sunun)?\b/g;

/** A stalled / long-standing / still-pending framing. */
const COFFEE_STALL =
  /bir suredir|uzun suredir|epeydir|bir zamandir|kapanmayan|kapanmamis|ilerlemeyen|ilerlemiyor|oldugu yerde duran|ayni yerde duran|cozulmemis|yarim kal|bekleyen|beklenen/;

/** Talk as the vehicle of the story. */
const COFFEE_CONVERSATION = /konusma|konusul|sohbet|dillendir|cevap|yanit/;

/** The habitual "it will ease / work out" close. */
const COFFEE_RESOLUTION =
  /ferah|tatliya bagla|yoluna gir|cozul|rahatla|hafifle|havada kalmayacak|sonuca bagla/;

export type CoffeeWrapperProfile = {
  genericIssues: number;
  genericOpening: boolean;
  conversationSections: number;
  resolution: boolean;
};

export function coffeeWrapperProfile(sections: string[]): CoffeeWrapperProfile {
  const body = filled(sections).map(foldTr);
  const all = body.join(' ');
  const opening = sentencesOf(body[0] ?? '')[0] ?? '';
  return {
    genericIssues: (all.match(COFFEE_GENERIC_ISSUE) ?? []).length,
    genericOpening:
      new RegExp(COFFEE_GENERIC_ISSUE.source).test(opening) && COFFEE_STALL.test(opening),
    conversationSections: body.filter((s) => COFFEE_CONVERSATION.test(s)).length,
    resolution: COFFEE_RESOLUTION.test(all),
  };
}

/**
 * `sections[0]` must be overall. `communication` is the evidence-derived
 * affordance (undefined when evidence is not available: the arc rule is
 * then skipped, the text-only rules still apply).
 */
export function coffeeGenericWrapper(sections: string[], communication?: boolean): boolean {
  const w = coffeeWrapperProfile(sections);
  // The reading opens on an unnamed, stalled issue ("bir süredir … kapanmayan
  // bir mesele") instead of on what this cup shows.
  if (w.genericOpening) return true;
  // Generic issue nouns carry the reading rather than the cup's signs.
  if (w.genericIssues >= 4) return true;
  // Default talk-and-relief arc on a cup with nothing that affords talk.
  if (communication === false && w.conversationSections >= 1 && w.resolution) return true;
  if (communication === false && w.conversationSections >= 2) return true;
  return false;
}

export function evaluatePalmQuality(
  input: PalmQualityInput,
): HumanQualityFailure | null {
  const observation = input.visualObservation.trim();
  const overall = input.overall.trim();
  const takeaway = input.takeaway.trim();
  if (!observation || !overall) return 'empty';
  if (AI_DISCLOSURE.test(joinPalm(input))) return 'ai_disclosure';
  if (GENERIC_PALM.test(foldTr(overall)) || GENERIC_PALM.test(foldTr(observation))) {
    return 'generic';
  }
  const earlyPalm = joinPalm(input);
  if (input.language === 'tr' && TR_LOCALE_LEAK.test(earlyPalm)) return 'locale_leak';
  if (input.language === 'en' && EN_LOCALE_LEAK_CYR.test(earlyPalm)) return 'locale_leak';
  if (EMBEDDED_DISCLAIMER.test(foldTr(earlyPalm))) return 'embedded_disclaimer';
  if (GENERIC_CLOSING.test(foldTr(takeaway)) || GENERIC_CLOSING.test(foldTr(overall))) {
    return 'generic_closing';
  }
  if (!input.trustedHandSide && INFERRED_HAND.test(foldTr(earlyPalm))) {
    return 'inferred_handedness';
  }
  if (observation.length < 60 || overall.length < 40) return 'too_short';
  if (wordCount(joinPalm(input)) < 90) return 'too_short';
  if (
    crossSectionRepetition([
      observation,
      overall,
      input.lifeLine,
      input.headLine,
      input.heartLine,
      input.fateLine,
      takeaway,
    ])
  ) {
    return 'duplicate_sections';
  }
  if (PALM_WEAK_OBS.test(foldTr(observation)) || !PALM_ATTR.test(foldTr(observation))) {
    return 'weak_observation';
  }
  const blob = joinPalm(input);
  // Safety and stock-cliché checks take priority over the style-level
  // observation_heavy gate below, so a medical/certainty claim or a
  // stock-cliché fixture is never masked by a style verdict instead.
  if (CERTAINTY.test(foldTr(blob))) return 'unsupported_certainty';
  if (MEDICAL.test(foldTr(blob))) return 'prohibited_claim';
  const claim = palmClaimFailure(foldTr(blob));
  if (claim) return claim;
  if (!input.hasMemoryContext && FAKE_MEMORY_CLAIM.test(foldTr(blob))) {
    return 'fake_memory';
  }
  if (PALM_STOCK.test(foldTr(blob))) return 'repeated_stock';
  if (
    countMatches(foldTr(blob), /isaret ed(er|iyor)|gosterebilir|points to|suggests/gi) >= 3
  ) {
    return 'repeated_stock';
  }
  if (SCHEMA_JARGON.test(blob)) return 'schema_jargon_leak';
  // Synthesis sections only — overall/takeaway must translate the per-line
  // property notes into meaning. A bare visual report is a different
  // defect from restating the same attributes inside real interpretation.
  const obsVocab = [PALM_ATTR, OBSERVATION_VERB];
  const bareSynthesis = [overall, takeaway].filter((s) => isBareObservationSection(s, obsVocab));
  if (bareSynthesis.length >= 1) return 'observation_heavy';
  const palmLines = [input.lifeLine, input.headLine, input.heartLine, input.fateLine];
  const palmRead = [overall, ...palmLines, takeaway];
  if (hasStockAdvice(palmRead)) return 'stock_advice';
  if (themeDominates(input.relevantThemes, palmRead)) return 'theme_domination';
  if (palmLineAttributeReuse(input)) return 'evidence_reuse';
  if (ideaClusterRepeats(palmRead)) return 'section_redundancy';
  if (palmTakeawayRestatesGeometry(input)) return 'section_redundancy';
  const voice = palmVoiceFailure(
    {
      overall: foldTr(overall),
      lifeLine: foldTr(input.lifeLine),
      headLine: foldTr(input.headLine),
      heartLine: foldTr(input.heartLine),
      fateLine: foldTr(input.fateLine),
      takeaway: foldTr(takeaway),
    },
    Boolean(input.hasStatedContext || input.hasMemoryContext),
  );
  if (voice) return voice;
  return localeMarkerFailure(blob, input.language);
}


/**
 * Any two non-trivial sections that are identical, or where one embeds a
 * long run of another almost verbatim, signal copy-paste repetition across
 * headings — the same evidence sentence restated instead of adding new
 * information. Checked across ALL sections (not just overall/takeaway),
 * since the writer can just as easily restate visualObservation inside
 * love/career/money/nearFuture (or a palm line section) as connective
 * prose — the real defect observed in a live Coffee generation.
 */
function crossSectionRepetition(sections: string[]): boolean {
  const normalized = sections
    .map((s) => foldTr(s.trim()))
    .filter((s) => s.length >= 30);
  for (let i = 0; i < normalized.length; i++) {
    for (let j = i + 1; j < normalized.length; j++) {
      const a = normalized[i];
      const b = normalized[j];
      if (a === b) return true;
      const shorter = a.length <= b.length ? a : b;
      const longer = a.length <= b.length ? b : a;
      if (longer.includes(shorter)) return true;
    }
  }
  return false;
}

function closingQuestionHabit(overall: string, takeaway: string): boolean {
  const oQ = isQuestion(overall);
  const tQ = isQuestion(takeaway);
  if (!tQ) return false;
  if (oQ && tQ) {
    const a = questionCore(lastSentence(overall));
    const b = questionCore(takeaway);
    if (!a || !b) return true;
    if (a === b) return true;
    if (overlapRatio(a, b) >= 0.55) return true;
    if (
      /(bulusma|toplanti|meeting)/i.test(a) &&
      /(bulusma|toplanti|meeting)/i.test(b)
    ) {
      return true;
    }
  }
  return false;
}

/** Takeaway question that merely restates başlangıç/buluşma/kapı themes from the body. */
function boilerplateClosingQuestion(overall: string, takeaway: string): boolean {
  if (!isQuestion(takeaway)) return false;
  const t = foldTr(takeaway);
  const o = foldTr(overall);
  const theme =
    /(baslangic|bulusma|bir araya|kapilar|kapi arala)/i.test(t) &&
    /(baslangic|bulusma|bir araya|kapilar|kapi arala)/i.test(o);
  return theme;
}

function repeatKeyIdea(text: string, keys: string[]): boolean {
  const n = foldTr(text);
  for (const key of keys) {
    const re = new RegExp(key, 'gi');
    const m = n.match(re);
    if (m && m.length >= 3) return true;
  }
  return false;
}

function isQuestion(s: string): boolean {
  const t = s.trim();
  return /\?\s*$/.test(t) || /(m[ıiuü]s[ıiuü]n)\s*\?/i.test(t);
}

function lastSentence(s: string): string {
  const parts = s
    .split(/(?<=[.!?])\s+/)
    .map((p) => p.trim())
    .filter(Boolean);
  return parts[parts.length - 1] ?? s;
}

function questionCore(s: string): string {
  return foldTr(s)
    .replace(/[?!.,;:"""'']/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function overlapRatio(a: string, b: string): number {
  const wa = new Set(a.split(' ').filter((w) => w.length > 2));
  const wb = b.split(' ').filter((w) => w.length > 2);
  if (wa.size === 0 || wb.length === 0) return 0;
  let hit = 0;
  for (const w of wb) if (wa.has(w)) hit++;
  return hit / Math.max(wb.length, 1);
}

function wordCount(s: string): number {
  return s
    .trim()
    .split(/\s+/)
    .filter((w) => w.length > 0).length;
}

function countMatches(s: string, re: RegExp): number {
  return (s.match(re) ?? []).length;
}

/**
 * Generic productivity closings that make Coffee and Palm sound like the
 * same template. Not a single-sentence blacklist — formula shapes.
 */
const STOCK_ADVICE =
  /(iki|2)\s*(ya da|veya)\s*(uc|3)\s*(madde|kriter|olcut)|olcutlerini?\s+[^.]{0,48}(indir|sinirla|azalt)|kucuk bir (liste|adim)\b|seceneklerini sade|sade bir liste haline/i;

const IDEA_CLUSTERS: RegExp[] = [
  /karar|secenek|olcut|tercih|tart(iyor|mak)?/,
  /sadelest|elemek|maddeye|maddeyle|kucuk bir adim/,
  /surdurulebilir secenek|biriken dusunce|yuku ele/,
];

function filled(sections: string[]): string[] {
  return sections.map((s) => s.trim()).filter((s) => s.length > 0);
}

export function hasStockAdvice(sections: string[]): boolean {
  return filled(sections).some((s) => STOCK_ADVICE.test(foldTr(s)));
}

function themeStems(themes: string[] | undefined): string[] {
  const stems = new Set<string>();
  for (const theme of themes ?? []) {
    for (const word of foldTr(theme).split(/[^a-z0-9]+/)) {
      if (word.length >= 5) stems.add(word.slice(0, Math.min(word.length, 7)));
    }
  }
  if ([...stems].some((s) => s.startsWith('karar'))) {
    stems.add('secenek');
    stems.add('olcut');
    stems.add('tart');
  }
  return [...stems];
}

export function themeDominates(
  themes: string[] | undefined,
  sections: string[],
): boolean {
  const stems = themeStems(themes);
  if (stems.length === 0) return false;
  const body = filled(sections);
  if (body.length < 2) return false;
  const hits = body.filter((s) => {
    const n = foldTr(s);
    return stems.some((stem) => n.includes(stem));
  }).length;
  return hits / body.length >= 0.75 && hits >= 2;
}

/**
 * overall + nearFuture + takeaway restating one conceptual center.
 * Empty optional lanes are allowed; collapse only applies when all three
 * are filled and either share a single-center lexicon or the same stems.
 *
 * `anchorRoots` (evidence-derived, single-sign cups only) are the sign's
 * own name: they never count as one of the shared stems. Meaning stems
 * (sevindi-, firsat-, kismet-…) always count.
 */
export function coffeeInsightCollapse(
  overall: string,
  nearFuture: string,
  takeaway: string,
  anchorRoots: readonly string[] = [],
): boolean {
  const trio = [overall, nearFuture, takeaway].map((s) => s.trim());
  if (trio.some((s) => s.length === 0)) return false;
  const folded = trio.map(foldTr);
  const singleCenter =
    /karar|ana mesele|daginik|ozune|dugum|tek bir nokta|ayni mesele/;
  if (folded.filter((s) => singleCenter.test(s)).length >= 3) return true;
  const sets = trio.map(insightStems);
  const shared = [...sets[0]].filter(
    (stem) =>
      sets[1].has(stem) &&
      sets[2].has(stem) &&
      !anchorRoots.some((root) => stem.startsWith(root)),
  );
  return shared.length >= 2;
}

/**
 * Concept family, not a phrase blacklist. One incidental word is not
 * enough — a section belongs to the cluster only when several related
 * members appear. Collapse when all three meaning sections do that.
 */
const VOICE_BOUNDARY_MEMBERS: RegExp[] = [
  /konus|ifade|anlat/,
  /tuttuk|sakla|iceride|icinde tut/,
  /aciklik|olculu/,
  /cumle/,
  /sinir|koruy|kisisel bir alan/,
];

function voiceBoundaryHits(text: string): number {
  const folded = foldTr(text);
  return VOICE_BOUNDARY_MEMBERS.filter((member) => member.test(folded)).length;
}

export function coffeeSemanticCollapse(
  overall: string,
  nearFuture: string,
  takeaway: string,
): boolean {
  const trio = [overall, nearFuture, takeaway].map((s) => s.trim());
  if (trio.some((s) => s.length === 0)) return false;
  return trio.every((s) => voiceBoundaryHits(s) >= 2);
}

const INSIGHT_STOP = new Set([
  'fincan',
  'fincani',
  'olabil',
  'dusund',
  'soyluy',
  'isaret',
  'icinde',
  'uzerin',
  'tarafi',
  'boyunc',
]);

function insightStems(text: string): Set<string> {
  const out = new Set<string>();
  for (const word of foldTr(text).split(/[^a-z0-9]+/)) {
    if (word.length < 6) continue;
    const stem = word.slice(0, 7);
    if (INSIGHT_STOP.has(stem)) continue;
    out.add(stem);
  }
  return out;
}

export function ideaClusterRepeats(sections: string[]): boolean {
  const body = filled(sections);
  if (body.length < 3) return false;
  for (const cluster of IDEA_CLUSTERS) {
    const hits = body.filter((s) => cluster.test(foldTr(s))).length;
    if (hits >= 3) return true;
  }
  return false;
}

const PALM_LINE_SPECS: Array<{ name: RegExp; text: (input: PalmQualityInput) => string }> = [
  { name: /zihin|kafa ciz|bas ciz|head line/, text: (i) => i.headLine },
  { name: /yasam ciz|life line/, text: (i) => i.lifeLine },
  { name: /kalp ciz|heart line/, text: (i) => i.heartLine },
  { name: /kader ciz|fate line/, text: (i) => i.fateLine },
];

const MORPH: Array<[string, RegExp]> = [
  ['length', /\buzun\b|\bkisa\b/],
  ['direction', /\basagi\b|\byukari\b|\bduz\b/],
  ['depth', /\bderin\b|\bsig\b/],
  ['curve', /kivr|kavis|\begri\b/],
  ['continuity', /kesintisiz|kesiksiz|kesik|kopuk|surekli|devam/],
];

function morphSet(text: string): Set<string> {
  const n = foldTr(text);
  const out = new Set<string>();
  for (const [name, re] of MORPH) if (re.test(n)) out.add(name);
  return out;
}

export function palmLineAttributeReuse(input: PalmQualityInput): boolean {
  const synthesis = [input.overall, input.takeaway].map((s) => s.trim()).filter(Boolean);
  if (synthesis.length < 2) return false;
  for (const spec of PALM_LINE_SPECS) {
    const line = spec.text(input).trim();
    if (!line) continue;
    const lineMorph = morphSet(line);
    if (lineMorph.size === 0) continue;
    const restated = synthesis.filter((s) => {
      const n = foldTr(s);
      if (!spec.name.test(n)) return false;
      const shared = [...morphSet(s)].filter((m) => lineMorph.has(m));
      return shared.length >= 1;
    }).length;
    if (restated >= 2) return true;
  }
  return false;
}

/** The takeaway names a line and re-describes two or more of its own attributes. */
export function palmTakeawayRestatesGeometry(input: PalmQualityInput): boolean {
  const takeaway = foldTr(input.takeaway);
  if (!takeaway.trim()) return false;
  return PALM_LINE_SPECS.some((spec) => {
    const line = spec.text(input).trim();
    if (!line || !spec.name.test(takeaway)) return false;
    const lineMorph = morphSet(line);
    return [...morphSet(takeaway)].filter((m) => lineMorph.has(m)).length >= 2;
  });
}

/** Unicode-safe Turkish fold: diacritics → ASCII so patterns stay stable. */
export function foldTr(s: string): string {
  return s
    .normalize('NFC')
    .toLocaleLowerCase('tr-TR')
    .replace(/\u0131/g, 'i')
    .replace(/\u011f/g, 'g')
    .replace(/\u00fc/g, 'u')
    .replace(/\u015f/g, 's')
    .replace(/\u00f6/g, 'o')
    .replace(/\u00e7/g, 'c')
    .replace(/\u0130/g, 'i');
}

function joinSections(input: CoffeeQualityInput): string {
  return [
    input.visualObservation,
    input.overall,
    input.love,
    input.career,
    input.money,
    input.nearFuture,
    input.takeaway,
  ].join(' ');
}

function joinPalm(input: PalmQualityInput): string {
  return [
    input.visualObservation,
    input.overall,
    input.lifeLine,
    input.headLine,
    input.heartLine,
    input.fateLine,
    input.takeaway,
  ].join(' ');
}

function localeMarkerFailure(
  blob: string,
  language: 'tr' | 'en' | 'ru' | undefined,
): HumanQualityFailure | null {
  if (!language) return null;
  const cyrillic = (blob.match(/[\u0400-\u04FF]/g) ?? []).join('').length;
  const latin = (blob.match(/[A-Za-zÀ-ÿ]/g) ?? []).join('').length;
  if (language === 'ru' && cyrillic < 8 && latin > 40) {
    return 'wrong_locale_marker';
  }
  if ((language === 'tr' || language === 'en') && cyrillic > 40 && latin < 8) {
    return 'wrong_locale_marker';
  }
  return null;
}
