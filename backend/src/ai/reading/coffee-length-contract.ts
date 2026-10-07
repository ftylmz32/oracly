import type { CoffeeNarrative } from './types.js';
import type { CoffeeAnyStoryPlan } from './coffee-story-plan.js';

export type CoffeeLengthDeficit = {
  target: 'visualObservation' | 'lead' | 'overall' | 'takeaway';
  unit: 'characters' | 'words';
  minimum: number;
  actual: number;
  additionalNeeded: number;
};

/**
 * C2.9 — the ONE authoritative Coffee length contract. The writer packet,
 * the repair plan, acceptance (`coffeeLengthDeficits`), and the plan-depth
 * gate all read these values; no other file may restate them.
 */
export type CoffeeLengthRequirements = {
  visualObservationMinChars: number;
  /** visualObservation + overall together. */
  combinedLeadMinWords: number;
  overallMinChars: number;
  overallMinWords: number;
  /** Plan guidance ceiling; null when no story plan applies. Not an acceptance gate. */
  overallMaxWords: number | null;
  takeawayMinWords: number;
  takeawayMaxWords: number | null;
};

/**
 * Story-first closure floors. Normal 42/22/10 were calibrated on all 133
 * saved non-sparse real stages (one word below the shortest clean real
 * reading). NARRATIVELY SPARSE cups (no sign or drawn form) use 35/20/8,
 * calibrated on all 34 saved sparse-cup stages. The plan's depth minimum
 * raises the section floors; it never lowers them.
 */
export function coffeeLengthRequirements(
  options: { narrativelySparse?: boolean; storyPlan?: CoffeeAnyStoryPlan } = {},
): CoffeeLengthRequirements {
  const sparse = options.narrativelySparse === true;
  const depth = options.storyPlan?.depth;
  return {
    visualObservationMinChars: 40,
    combinedLeadMinWords: sparse ? 35 : 42,
    overallMinChars: 80,
    overallMinWords: Math.max(sparse ? 20 : 22, depth?.overallWords.min ?? 0),
    overallMaxWords: depth?.overallWords.max ?? null,
    takeawayMinWords: Math.max(sparse ? 8 : 10, depth?.takeawayWords.min ?? 0),
    takeawayMaxWords: depth?.takeawayWords.max ?? null,
  };
}

const wordCount = (value: string): number =>
  value.trim().split(/\s+/u).filter(Boolean).length;

/** Acceptance and repair deficits from the authoritative requirements. */
export function coffeeLengthDeficits(
  narrative: Pick<CoffeeNarrative, 'visualObservation' | 'overall' | 'takeaway'>,
  options: { narrativelySparse?: boolean; storyPlan?: CoffeeAnyStoryPlan } | CoffeeLengthRequirements = {},
): CoffeeLengthDeficit[] {
  const req = 'combinedLeadMinWords' in options ? options : coffeeLengthRequirements(options);
  const observation = narrative.visualObservation.text.trim();
  const overall = narrative.overall.text.trim();
  const takeaway = narrative.takeaway.text.trim();
  const requirements: Omit<CoffeeLengthDeficit, 'additionalNeeded'>[] = [
    { target: 'visualObservation', unit: 'characters', minimum: req.visualObservationMinChars, actual: observation.length },
    { target: 'lead', unit: 'words', minimum: req.combinedLeadMinWords, actual: wordCount(`${observation} ${overall}`) },
    { target: 'overall', unit: 'characters', minimum: req.overallMinChars, actual: overall.length },
    { target: 'overall', unit: 'words', minimum: req.overallMinWords, actual: wordCount(overall) },
    { target: 'takeaway', unit: 'words', minimum: req.takeawayMinWords, actual: wordCount(takeaway) },
  ];
  return requirements
    .filter(({ target, actual, minimum }) => (target !== 'takeaway' || takeaway.length > 0) && actual < minimum)
    .map((requirement) => ({ ...requirement, additionalNeeded: requirement.minimum - requirement.actual }));
}
