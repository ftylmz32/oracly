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

/** Region families from observer metadata — not Turkish prose. */
export function coffeeEvidenceCluster(item: ReadingEvidenceItem): string {
  const blob = foldTr(`${item.region} ${item.description}`);
  if (/handle|kulp/.test(blob)) return 'handle';
  if (/upper|rim|agiz|lip|ust/.test(blob)) return 'upper';
  if (/lower|mid|wall|orta|alt/.test(blob)) return 'body';
  if (/base|bottom|dip|floor/.test(blob)) return 'base';
  return foldTr(item.region) || item.id;
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
