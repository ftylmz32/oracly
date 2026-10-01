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
  if (union.size < 2) return true;
  return shared.length > 0 && union.size === shared.length;
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
 * grounded clusters. No final prose.
 */
export function coffeeRepairFocus(
  sections: CoffeeMeaningSections,
  evidence: ReadingEvidenceItem[],
): string {
  const byId = new Map(evidence.map((item) => [item.id, coffeeEvidenceCluster(item)]));
  const usedByOverall = clustersCitedBy(sections.overall, byId);
  const unused = [...new Set(evidence.map(coffeeEvidenceCluster))].filter(
    (cluster) => !usedByOverall.has(cluster),
  );
  const unusedLine = unused.length
    ? ` Rewrite nearFuture and takeaway using other grounded evidence clusters not already carrying overall: ${unused.join(', ')}.`
    : ' If no distinct grounded evidence remains, leave nearFuture empty rather than adding another paraphrase.';
  return [
    'Overall already covers the collapsed pattern.',
    unusedLine.trim(),
    'Do not return to speaking, withheld sentences, measured openness, or boundary-protection advice.',
    'Each rewritten section must add a materially new claim from unused grounded evidence.',
    'Do not invent visuals. Do not insert a name to look personalized.',
  ].join(' ');
}
