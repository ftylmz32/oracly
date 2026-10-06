import type { CoffeeNarrative } from './types.js';
import type { CoffeeAnyStoryPlan } from './coffee-story-plan.js';

export type CoffeeLengthDeficit = {
  target: 'visualObservation' | 'lead' | 'overall' | 'takeaway';
  unit: 'characters' | 'words';
  minimum: number;
  actual: number;
  additionalNeeded: number;
};

const wordCount = (value: string): number =>
  value.trim().split(/\s+/u).filter(Boolean).length;

/** One authoritative length contract shared by acceptance and repair. */
export function coffeeLengthDeficits(
  narrative: Pick<CoffeeNarrative, 'visualObservation' | 'overall' | 'takeaway'>,
  options: { narrativelySparse?: boolean; storyPlan?: CoffeeAnyStoryPlan } = {},
): CoffeeLengthDeficit[] {
  const observation = narrative.visualObservation.text.trim();
  const overall = narrative.overall.text.trim();
  const takeaway = narrative.takeaway.text.trim();
  const sparse = options.narrativelySparse === true;
  const requirements: Omit<CoffeeLengthDeficit, 'additionalNeeded'>[] = [
    { target: 'visualObservation', unit: 'characters', minimum: 40, actual: observation.length },
    { target: 'lead', unit: 'words', minimum: sparse ? 35 : 42, actual: wordCount(`${observation} ${overall}`) },
    { target: 'overall', unit: 'characters', minimum: 80, actual: overall.length },
    {
      target: 'overall', unit: 'words',
      minimum: Math.max(sparse ? 20 : 22, options.storyPlan?.depth.overallWords.min ?? 0),
      actual: wordCount(overall),
    },
    {
      target: 'takeaway', unit: 'words',
      minimum: Math.max(sparse ? 8 : 10, options.storyPlan?.depth.takeawayWords.min ?? 0),
      actual: wordCount(takeaway),
    },
  ];
  return requirements
    .filter(({ target, actual, minimum }) => (target !== 'takeaway' || takeaway.length > 0) && actual < minimum)
    .map((requirement) => ({ ...requirement, additionalNeeded: requirement.minimum - requirement.actual }));
}
