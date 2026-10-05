/**
 * BATCH 3A.5 — Coffee evidence diversity and targeted repair focus.
 * Palm is frozen; this module is coffee-only.
 */

import { foldTr } from '../human-quality.js';
import type { NarrativeSection, ReadingEvidenceItem } from './types.js';

export type CoffeeMeaningSections = {
  overall: NarrativeSection;
  nearFuture: NarrativeSection;
  takeaway: NarrativeSection;
};

/**
 * Canonical region families, matched on whole TOKENS only. PHASE C1.5:
 * the previous substring test over region+description made English
 * "cl-ust-er" match Turkish "ust", and let "…up toward the rim" turn a
 * base/body item into "upper".
 */
const REGION_FAMILIES: ReadonlyArray<readonly [string, ReadonlySet<string>]> = [
  ['handle', new Set(['handle', 'kulp', 'kulb'])],
  ['upper', new Set(['upper', 'rim', 'lip', 'top', 'mouth', 'agiz', 'ust'])],
  ['base', new Set(['base', 'bottom', 'floor', 'dip', 'taban'])],
  ['body', new Set(['middle', 'mid', 'lower', 'wall', 'body', 'side', 'orta', 'alt'])],
];

function tokens(text: string): string[] {
  return foldTr(text).split(/[^a-z0-9]+/).filter(Boolean);
}

/** Region families from observer metadata — not Turkish prose. */
export function coffeeEvidenceCluster(item: ReadingEvidenceItem): string {
  // 1) The structured region is authoritative; family precedence decides
  //    compound regions (handle_side -> handle, upper_wall -> upper).
  const regionTokens = new Set(tokens(item.region));
  for (const [family, words] of REGION_FAMILIES) {
    if ([...regionTokens].some((t) => words.has(t))) return family;
  }
  // 2) Fallback only when the region is unusable: the EARLIEST region word
  //    in the description is the item's origin; a later "toward the rim"
  //    is a direction, not where the item sits.
  for (const t of tokens(item.description)) {
    for (const [family, words] of REGION_FAMILIES) {
      if (words.has(t)) return family;
    }
  }
  return foldTr(item.region) || item.id;
}

/**
 * PHASE C1.3: does any observer evidence afford communication / social
 * talk (news, messages, a conversation)? Derived from the observer's own
 * English description/resemblance — birds, figures, faces, letter-like
 * shapes, teapot/table (company). Internal only; never surfaces publicly.
 *
 * PHASE C1.5: dots / specks / speckles are NOT a communication sign on
 * their own. Real QA showed them used as an easy excuse for "short
 * messages in a row"; alone they afford multiplicity or scattered small
 * details, not news. A bird next to dots still affords news — because of
 * the bird.
 */
const COMMUNICATION_SIGN =
  /\b(birds?|letters?|envelopes?|phones?|persons?|figures?|faces?|people|crowds?|teapots?|kettles?|tables?)\b/;

/**
 * PHASE C1.7: mouth / lips / ears are also cup-part words ("the mouth of
 * the cup", "the ear of the cup"). They afford communication only as an
 * observed RESEMBLANCE (e.g. "may resemble human lips"), never from the
 * description text, and never when the phrase is about the cup itself.
 */
const HUMAN_MOUTH_RESEMBLANCE = /\b(mouths?|lips|ears?)\b/;
const CUP_PART_PHRASE = /\b(mouths?|lips|ears?) of the (cup|mug)\b/;

export function coffeeCommunicationAffordance(evidence: ReadingEvidenceItem[]): boolean {
  return evidence.some((item) => {
    const resemblance = (item.resemblance ?? '').toLowerCase();
    if (COMMUNICATION_SIGN.test(`${item.description} ${resemblance}`.toLowerCase())) return true;
    return HUMAN_MOUTH_RESEMBLANCE.test(resemblance) && !CUP_PART_PHRASE.test(resemblance);
  });
}

/**
 * Story-first repair semantics: does an evidence item carry a meaning of
 * its own, or is it only density / residue / position context?
 *
 * Semantic: an observed resemblance, a drawn form (line, loop, arch,
 * branch, path…), a clean / open area (traditional open kısmet), or the
 * handle side (home / close circle). Everything else — a dense or dark
 * base, an even layer, a patch, smears, scattering, faint marks, dots —
 * is context. Context is never mandatory new material: forcing a repair
 * to "use" a dark base is what turned it into invented backstory
 * (setbacks, serious effort, unfinished work).
 */
const SEMANTIC_FORM =
  /\b(lines?|loops?|arch(?:ed|es)?|branch(?:es|ing)?|shapes?|paths?|roads?|rings?|circles?|letters?|figures?|diagonal)\b/;
const OPEN_AREA = /\b(clean|clear|empty|open)\b/;

export function coffeeSemanticEvidence(item: ReadingEvidenceItem): boolean {
  if ((item.resemblance ?? '').trim()) return true;
  if (coffeeEvidenceCluster(item) === 'handle') return true;
  const description = item.description.toLowerCase();
  return SEMANTIC_FORM.test(description) || OPEN_AREA.test(description);
}

/**
 * Story-first closure: life events a section may only state when it cites
 * a real sign or form. Dots, faint marks, plain patches, density, a clean
 * band or the handle side alone give place, layout or domain — never
 * meetings, errands, news, free time, routine or an established order.
 * A clean / open area may still carry its traditional open kısmet.
 */
const CONTEXT_EVENT =
  /karsilas|bulus|gorusme|ziyaret|misafir|haber|mesaj|telefon|davet|toplanti|sohbet|ugras|\bvakit|rutin|duzen|\bisler(i|in)?\b/;
const CONTEXT_KISMET = /kismet/;
/**
 * Life categories: dots / faint marks / a clean band may give "several small
 * details" — never separate topics or agenda headings in the person's life
 * (real targeted12 DOTS: "gündeminde … farklı başlıklara ait parçalar").
 * The handle side is exempt: it legitimately places a reading at home.
 */
const CONTEXT_CATEGORY =
  /\bgundem\w*|\bbaslik\w*|(farkli|ayri|cesitli|iki) (konu|mesele|alan|basli|hayat)\w*|hayatinin (farkli|ayri|cesitli|iki)\w*|\bkonu(lar|su|lari|ya|da|dan|nun)?\b|\bmesele\w*|hayat alan\w*/;

function itemCarriesSign(item: ReadingEvidenceItem): boolean {
  if ((item.resemblance ?? '').trim()) return true;
  return SEMANTIC_FORM.test(item.description.toLowerCase());
}

/**
 * Story-first closure: a cup is NARRATIVELY SPARSE when no evidence item
 * carries a sign or a drawn form (no resemblance; no line, path, loop,
 * arch, branch, ring, figure…) — only dots, faint marks, density, a clean
 * band, plain patches or the handle-side location. Such a cup cannot
 * support a full 70–120-word fortune without padding or invention.
 * ROAD, BRIDGE, BIRD, RING, TREE, STAR, LOW-SYMBOL (diagonal line) and
 * NO-SIGN (curved line) are never sparse.
 */
export function coffeeNarrativelySparse(evidence: ReadingEvidenceItem[]): boolean {
  return evidence.length > 0 && !evidence.some(itemCarriesSign);
}

/**
 * Story-first closure: on a NARRATIVELY SPARSE cup, is the reading grounded
 * by its real context evidence? True only when an interpretation section
 * cites a context item AND names that same item in its text (a clean band
 * as temiz / şerit / açık, dots as nokta / serpiş, faint marks as silik / iz,
 * the handle side as kulp, the base as dip). The anchor comes from the cited
 * evidence, not from the prose alone; these items are context, never
 * semantic signs. Used only to exempt such a reading from abstract_reading.
 */
const CONTEXT_ANCHOR_WORDS: ReadonlyArray<readonly [RegExp, RegExp]> = [
  [OPEN_AREA, /\btemiz\w*|\bacik\w*|\bserit\w*|\bbant\w*|\bbosluk\w*|\baralik\w*/],
  // "küçük / ufak ayrıntı" is the evidence-level rendering the context_event
  // repair itself asks for (full12_run10 DOTS repair lost its anchor by using
  // it). An anchor alias only for a section citing dots: never a semantic
  // sign, never permission for events or categories (checked separately).
  [/\b(dots?|specks?|speckles?|scatter\w*)\b/, /\bnokta\w*|\bbenek\w*|serpis\w*|serpil\w*|dagin\w*|dagil\w*|\b(kucuk|ufak) ayrinti\w*/],
  [/\b(faint|marks?|strokes?|smears?)\b/, /\bsilik\w*|\biz(ler|leri)?\b|\bisaret\w*|\bleke\w*/],
  [/\bhandle\b/, /\bkulp\w*|\bkulb\w*/],
  [/\b(base|bottom)\b/, /\bdip\w*|\bdib\w*/],
];

export function coffeeSparseContextAnchored(sections: NarrativeSection[], evidence: ReadingEvidenceItem[]): boolean {
  if (!coffeeNarrativelySparse(evidence)) return false;
  const byId = new Map(evidence.map((item) => [item.id, item]));
  return sections.some((section) => {
    if (!section.text.trim()) return false;
    const text = foldTr(section.text);
    return section.evidenceIds.some((id) => {
      const item = byId.get(id);
      if (!item) return false;
      const source = `${item.region} ${item.description}`.toLowerCase();
      return CONTEXT_ANCHOR_WORDS.some(([evidenceForm, proseWord]) => evidenceForm.test(source) && proseWord.test(text));
    });
  });
}

/** A road / path the observer actually reported (resemblance or description). */
const ROAD_FORM = /\b(roads?|paths?)\b/;

export function coffeeRoadBearing(evidence: ReadingEvidenceItem[]): boolean {
  return evidence.some((item) => ROAD_FORM.test(`${item.resemblance ?? ''} ${item.description}`.toLowerCase()));
}

/**
 * Relocation / travel language. A plain connecting line (LOW-SYMBOL), a
 * handle-side line (NO-SIGN) or a bridge is a link — not being carried to
 * another place. Only a reported road or path may say it.
 */
const RELOCATION =
  /bulundu(gu|gun) (yer|nokta)(dan|den)\b[^.;]{0,40}\b(tasi|gotur|kaldir|hareket ettir|ilerle)\w*|baska bir (yer|nokta|taraf)\w* (dogru )?(tasi|ilerle|git|gec|gotur|varac)\w*|yer degis\w*|\btasin(acak|ma|iyor|man)\w*|\byolculu\w*|\bseyahat\w*/;
/** "… haber, yolculuk ya da buluşma yok" lists what is absent; not a relocation claim. */
const RELOCATION_NEGATED = /\byok\b|\bdegil\b|\bne\b[^.!?;]{1,40}\bne\b|\w+(mamis|memis|miyor|muyor)\b/;

export function coffeePlainLineRelocation(sections: string[], evidence: ReadingEvidenceItem[]): string | null {
  if (coffeeRoadBearing(evidence)) return null;
  for (const sentence of sections.filter((s) => s.trim()).map(foldTr).flatMap((t) => t.split(/(?<=[.!?;])\s+/))) {
    if (RELOCATION.test(sentence) && !RELOCATION_NEGATED.test(sentence)) return sentence;
  }
  return null;
}

/** A sentence that lists what is NOT there is absence talk, not a promoted event. */
const CONTEXT_NEGATED = /\bne\b[^.!?;]{1,40}\bne\b|\byok\b|\bdegil\b|\w+(mamis|memis|miyor|muyor|mez|maz)\b/;

function eventHits(text: string): string[] {
  return [...foldTr(text).matchAll(new RegExp(CONTEXT_EVENT.source, 'g'))].map((m) => m[0]);
}

/**
 * The first section text promoting context-only evidence into a life event,
 * or null. An event a sign-grounded section already introduced (the bird's
 * news) may be referred to again from a context-cited section.
 */
export function coffeeContextEventPromotion(
  sections: NarrativeSection[],
  evidence: ReadingEvidenceItem[],
): string | null {
  const byId = new Map(evidence.map((item) => [item.id, item]));
  const citedBy = (section: NarrativeSection) =>
    section.evidenceIds.map((id) => byId.get(id)).filter((item) => item !== undefined);
  const established = new Set(
    sections.filter((s) => s.text.trim() && citedBy(s).some(itemCarriesSign)).flatMap((s) => eventHits(s.text)),
  );
  for (const section of sections) {
    if (!section.text.trim() || section.evidenceIds.length === 0) continue;
    const cited = citedBy(section);
    if (cited.length === 0) continue;
    // Life categories need a REAL sign (an observed resemblance). A plain
    // line or mark is a drawn form but low-capacity: it relates two visible
    // regions, it does not make them two topics of the person's life
    // (targeted14 LOW-SYMBOL: "… iki başlık …").
    const resemblance = cited.some((item) => Boolean(item.resemblance?.trim()));
    const handle = cited.some((item) => coffeeEvidenceCluster(item) === 'handle' || /\bhandle\b/i.test(item.description));
    const signOrForm = cited.some(itemCarriesSign);
    const open = cited.some((item) => OPEN_AREA.test(item.description.toLowerCase()));
    for (const sentence of foldTr(section.text).split(/(?<=[.!?;])\s+/)) {
      if (CONTEXT_NEGATED.test(sentence)) continue;
      if (!resemblance && !handle && CONTEXT_CATEGORY.test(sentence)) return section.text;
      if (signOrForm) continue;
      if (eventHits(sentence).some((hit) => !established.has(hit))) return section.text;
      if (!open && CONTEXT_KISMET.test(sentence)) return section.text;
    }
  }
  return null;
}

/**
 * Story-first closure: Turkish name roots for an observed sign, keyed by
 * the observer's ENGLISH noun. Used only to recognise the cup's own sign
 * name in a single-sign reading (coffeeInsightCollapse) — never a global
 * stop list, never matched against generated prose to pick the sign.
 * Roots are folded and inflection-safe (yüzüğü -> yuzug); road roots skip
 * "yolculuk", which is a meaning, not the sign's name.
 */
const SIGN_NAME_ROOTS: Readonly<Record<string, readonly string[]>> = {
  star: ['yildiz'],
  ring: ['yuzuk', 'yuzug', 'halka'],
  circle: ['halka', 'daire'],
  bird: ['kus'],
  fish: ['balik', 'balig'],
  tree: ['agac'],
  heart: ['kalp', 'kalbi'],
  key: ['anahtar'],
  sun: ['gunes'],
  bridge: ['kopru'],
  ladder: ['merdiven'],
  snake: ['yilan'],
  flower: ['cicek', 'cicey'],
  butterfly: ['kelebek', 'kelebeg'],
  letter: ['harf', 'mektup'],
  envelope: ['zarf', 'mektup'],
  road: ['yolu', 'yoll', 'yola', 'yold'],
  path: ['yolu', 'yoll', 'yola', 'yold'],
};

/**
 * Name roots of the cup's ONE semantic sign, or [] when the observation
 * has zero or several semantic items. Derived from observer evidence only
 * (resemblance first, then description); density / residue context never
 * contributes, and a sign named only in generated prose cannot exempt
 * itself.
 */
export function coffeeSingleSemanticAnchorRoots(evidence: ReadingEvidenceItem[]): string[] {
  const semantic = evidence.filter(coffeeSemanticEvidence);
  if (semantic.length !== 1) return [];
  const [item] = semantic;
  const source = (item.resemblance ?? '').trim() || item.description;
  const roots = new Set<string>();
  for (const word of source.toLowerCase().split(/[^a-z]+/)) {
    const noun = word.endsWith('s') && !SIGN_NAME_ROOTS[word] ? word.slice(0, -1) : word;
    for (const root of SIGN_NAME_ROOTS[noun] ?? []) roots.add(root);
  }
  return [...roots];
}

/**
 * Story-first closure: the takeaway rests ONLY on context evidence (a
 * dense base, a plain patch, smears, dots) while the cup has a real
 * semantic sign. Real QA: BIRD closed on "the base means details stay
 * with you after the news" — context turned into a second-story engine.
 * A cup without any resemblance-bearing sign is exempt: it has nothing else.
 */
export function coffeeContextOnlyTakeaway(
  takeaway: NarrativeSection,
  evidence: ReadingEvidenceItem[],
): boolean {
  if (!takeaway.text.trim() || takeaway.evidenceIds.length === 0) return false;
  const byId = new Map(evidence.map((item) => [item.id, item]));
  // Only a cup whose story is carried by a real sign (an observed
  // resemblance); low-symbol cups may close on what little they hold.
  if (!evidence.some((item) => Boolean(item.resemblance?.trim()))) return false;
  return takeaway.evidenceIds.every((id) => {
    const item = byId.get(id);
    // A handle-directed item carries the traditional home / close-circle
    // meaning even when its region is a wall.
    return item !== undefined && !coffeeSemanticEvidence(item) && !/\bhandle\b/i.test(item.description);
  });
}

function filledMeaning(sections: CoffeeMeaningSections): NarrativeSection[] {
  return [sections.overall, sections.nearFuture, sections.takeaway].filter(
    (section) => section.text.trim().length > 0,
  );
}

/**
 * When enough distinct observer clusters exist, the three public meaning
 * sections must not all rest on one cluster. A shared anchor is allowed
 * if another cluster also contributes. Too little observer evidence must
 * not be stretched into three paraphrases.
 *
 * Story-first: a cup whose sections all rest on one MEANINGFUL sign is
 * not collapsed when no other semantic sign is left unused — a single
 * star may carry the fortune, its timing and a nuance. Paraphrase across
 * those sections is still caught by the quality gates (section_redundancy
 * / insight_collapse); density-only anchors and cups with unused semantic
 * signs are still concentration.
 */
export function coffeeEvidenceConcentration(
  sections: CoffeeMeaningSections,
  evidence: ReadingEvidenceItem[],
): boolean {
  const meaning = filledMeaning(sections);
  if (meaning.length < 3) return false;

  const byId = new Map(evidence.map((item) => [item.id, coffeeEvidenceCluster(item)]));
  const observerClusters = new Set(evidence.map(coffeeEvidenceCluster));
  const cited = meaning.map((section) => {
    const clusters = new Set<string>();
    for (const id of section.evidenceIds) {
      const cluster = byId.get(id);
      if (cluster) clusters.add(cluster);
    }
    return clusters;
  });
  if (cited.some((set) => set.size === 0)) return true;
  if (observerClusters.size < 2) return true;

  const union = new Set(cited.flatMap((set) => [...set]));
  const shared = [...cited[0]].filter((cluster) => cited.every((set) => set.has(cluster)));
  const concentrated = union.size < 2 || (shared.length > 0 && union.size === shared.length);
  if (!concentrated) return false;
  return !singleSemanticAnchor(meaning, evidence, byId, union);
}

/**
 * True when the reading is anchored on a semantic sign (overall cites
 * one) and the observation has no other semantic cluster the reading
 * leaves unused. A clean rim and dots both live in the "upper" cluster:
 * a rim-led reading that adds the dots as small details is not collapsed.
 */
function singleSemanticAnchor(
  meaning: NarrativeSection[],
  evidence: ReadingEvidenceItem[],
  byId: Map<string, string>,
  union: Set<string>,
): boolean {
  const semanticIds = new Set(evidence.filter(coffeeSemanticEvidence).map((item) => item.id));
  const anchoredOnSign = meaning[0].evidenceIds.some((id) => semanticIds.has(id));
  if (!anchoredOnSign) return false;
  const unusedSemantic = evidence.some(
    (item) => semanticIds.has(item.id) && !union.has(byId.get(item.id) ?? ''),
  );
  return !unusedSemantic;
}

function clustersCitedBy(
  section: NarrativeSection,
  byId: Map<string, string>,
): Set<string> {
  const clusters = new Set<string>();
  for (const id of section.evidenceIds) {
    const cluster = byId.get(id);
    if (cluster) clusters.add(cluster);
  }
  return clusters;
}

/**
 * One bounded repair note: name the collapsed concept and unused
 * grounded SEMANTIC clusters. No final prose. Density-only context is
 * never offered as new material (it is what produced base backstory).
 */
export function coffeeRepairFocus(
  sections: CoffeeMeaningSections,
  evidence: ReadingEvidenceItem[],
): string {
  const byId = new Map(evidence.map((item) => [item.id, coffeeEvidenceCluster(item)]));
  const usedByOverall = clustersCitedBy(sections.overall, byId);
  const unused = [
    ...new Set(evidence.filter(coffeeSemanticEvidence).map(coffeeEvidenceCluster)),
  ].filter((cluster) => !usedByOverall.has(cluster));
  const context = evidence.filter((item) => !coffeeSemanticEvidence(item)).map((item) => item.id);
  const unusedLine = unused.length
    ? `Rewrite nearFuture and takeaway using unused grounded evidence with its own meaning, in clusters not already carrying overall: ${unused.join(', ')}.`
    : 'No unused grounded evidence with its own meaning remains. Leave nearFuture empty unless a region gives a genuine timing cue for the same sign, and let the takeaway deepen the same sign with a facet overall has not used — without paraphrasing overall. Keep the grounded substance of overall; rewrite only what repeats.';
  return [
    'Overall already covers the collapsed pattern.',
    unusedLine,
    context.length
      ? `Evidence ${context.join(', ')} is density/residue context only: it is not new material, and a dense or dark base never creates backstory (no setbacks, effort, unfinished work, responsibility, delay, history or something holding the person back).`
      : '',
    'Do not return to speaking, withheld sentences, measured openness, or boundary-protection advice.',
    'Each rewritten section must add a materially new facet of the same story; never invent a new event or backstory to make sections differ.',
    'Do not fix the repetition by swapping synonyms or keeping the same sentence skeleton in each section: overall tells the main fortune, nearFuture (only if grounded) the timing or approach, takeaway one final grounded nuance — not a summary, not advice. Do not copy the rejected nearFuture verbatim; rewrite robotic "X gösteriyor / söylüyor / anlatıyor / işaret ediyor" framing into direct fortune sentences.',
    'Do not invent visuals. Do not insert a name to look personalized.',
  ].filter(Boolean).join(' ');
}
