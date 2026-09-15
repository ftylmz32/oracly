/**
 * Deterministic structural / safety checks for Coffee & Palm human output.
 * Strengthened in E3G for grounding, specificity, and anti-boilerplate.
 */

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
  | 'evidence_reuse';

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
  /** Supplied recurring-theme labels — supporting context, not the subject. */
  relevantThemes?: string[];
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
function isBareObservationSection(text: string, obsVocab: RegExp[]): boolean {
  const t = foldTr(text.trim());
  if (!t) return false;
  const hasObsVocab = obsVocab.some((re) => re.test(t));
  if (!hasObsVocab) return false;
  return !MEANING_MARKER.test(t);
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
  if (wordCount(overall + ' ' + observation) < 70) return 'too_short';
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
  if (
    wordCount(
      [overall, takeaway, input.love, input.career, input.money, input.nearFuture].join(
        ' ',
      ),
    ) < 100
  ) {
    return 'too_short';
  }
  if (repeatKeyIdea(joinSections(input), ['bulusma', 'baslangic', 'bir araya'])) {
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
  const bareSections = interpretationSections.filter((s) => isBareObservationSection(s, obsVocab));
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
  if (coffeeInsightCollapse(overall, input.nearFuture, takeaway)) return 'section_redundancy';
  if (coffeeSemanticCollapse(overall, input.nearFuture, takeaway)) return 'insight_collapse';
  return localeMarkerFailure(blob, input.language);
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
 */
export function coffeeInsightCollapse(
  overall: string,
  nearFuture: string,
  takeaway: string,
): boolean {
  const trio = [overall, nearFuture, takeaway].map((s) => s.trim());
  if (trio.some((s) => s.length === 0)) return false;
  const folded = trio.map(foldTr);
  const singleCenter =
    /karar|ana mesele|daginik|ozune|dugum|tek bir nokta|ayni mesele/;
  if (folded.filter((s) => singleCenter.test(s)).length >= 3) return true;
  const sets = trio.map(insightStems);
  const shared = [...sets[0]].filter((stem) => sets[1].has(stem) && sets[2].has(stem));
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
  { name: /zihin|kafa ciz|head line/, text: (i) => i.headLine },
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
