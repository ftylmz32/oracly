import type { CoffeeNarrative } from './types.js';
import type {
  CoffeeForbiddenAssumption,
  CoffeePropositionKind,
} from './coffee-semantic-propositions.js';
import type { CoffeePublicSection, CoffeeStoryPlanV2 } from './coffee-story-plan.js';

export type CoffeeRepairDefect =
  | 'structural_deficit'
  | 'abstract_realization'
  | 'unsupported_concretization'
  | 'multiple_renderings'
  | 'privacy_or_contract';

export type CoffeeRepairPlan = {
  version: 2;
  violation: string;
  storyPlan: CoffeeStoryPlanV2;
  requiredSections: ['visualObservation', 'overall', 'takeaway'];
  sectionDeficits: Array<{
    section: 'overall' | 'takeaway';
    minimumWords: number;
    actualWords: number;
    additionalWordsNeeded: number;
    needsAdditionalGroundedDevelopment: boolean;
  }>;
  unauthorizedSectionsToClear: CoffeePublicSection[];
  forbiddenClaimCategoriesTriggered: CoffeeForbiddenAssumption[];
  defect: {
    kind: CoffeeRepairDefect;
    propositionKinds: CoffeePropositionKind[];
  };
  requiredPropositionCoverage: CoffeePropositionKind[];
  evidenceIds: string[];
};

const words = (value: string) => value.trim().split(/\s+/u).filter(Boolean).length;

function defectKind(violation: string): CoffeeRepairDefect {
  if (violation === 'too_short' || violation === 'empty_required') return 'structural_deficit';
  if (violation === 'abstract_reading' || violation === 'generic_wrapper' || violation === 'formulaic_voice') {
    return 'abstract_realization';
  }
  if (
    violation === 'presumed_user_state'
    || violation === 'unsupported_existing_fact'
    || violation === 'unsupported_other_agency'
    || violation === 'unsupported_source_causation'
    || violation === 'context_event'
  ) {
    return 'unsupported_concretization';
  }
  if (violation === 'possibility_menu') return 'multiple_renderings';
  return 'privacy_or_contract';
}

function triggeredClaims(
  violation: string,
  plan: CoffeeStoryPlanV2,
): CoffeeForbiddenAssumption[] {
  const candidates: CoffeeForbiddenAssumption[] = violation === 'presumed_user_state'
    ? ['awaited_topic', 'prior_problem', 'prior_stagnation', 'current_major_decision', 'options_assumption']
    : violation === 'unsupported_existing_fact'
      ? ['prior_problem', 'existing_relationship', 'current_job_issue', 'prior_stagnation']
      : violation === 'unsupported_other_agency'
        ? ['specific_other_person', 'reciprocal_feeling']
        : violation === 'unsupported_source_causation'
          ? ['causation']
          : violation === 'context_event'
            ? ['family_event', 'chronology']
            : violation === 'unsupported_certainty'
              ? ['guaranteed_outcome']
              : [];
  const forbidden = new Set(plan.claimEnvelope.forbiddenAssumptions);
  return candidates.filter((candidate) => forbidden.has(candidate));
}

export function buildCoffeeRepairPlan(
  narrative: CoffeeNarrative,
  violation: string,
  storyPlan: CoffeeStoryPlanV2,
): CoffeeRepairPlan {
  const overallWords = words(narrative.overall.text);
  const takeawayWords = words(narrative.takeaway.text);
  const sectionDeficits = [
    {
      section: 'overall' as const,
      minimumWords: storyPlan.depth.overallWords.min,
      actualWords: overallWords,
      additionalWordsNeeded: Math.max(0, storyPlan.depth.overallWords.min - overallWords),
      needsAdditionalGroundedDevelopment: overallWords < storyPlan.depth.overallWords.min,
    },
    {
      section: 'takeaway' as const,
      minimumWords: storyPlan.depth.takeawayWords.min,
      actualWords: takeawayWords,
      additionalWordsNeeded: Math.max(0, storyPlan.depth.takeawayWords.min - takeawayWords),
      needsAdditionalGroundedDevelopment: takeawayWords < storyPlan.depth.takeawayWords.min,
    },
  ].filter((deficit) => deficit.additionalWordsNeeded > 0);
  const authorized = new Set(storyPlan.authorizedSections);
  const unauthorizedSectionsToClear = (['love', 'career', 'money', 'nearFuture'] as const)
    .filter((section) => !authorized.has(section) && narrative[section].text.trim().length > 0);
  const propositions = [storyPlan.lead, ...storyPlan.supporting];
  return {
    version: 2,
    violation,
    storyPlan,
    requiredSections: ['visualObservation', 'overall', 'takeaway'],
    sectionDeficits,
    unauthorizedSectionsToClear,
    forbiddenClaimCategoriesTriggered: triggeredClaims(violation, storyPlan),
    defect: {
      kind: defectKind(violation),
      propositionKinds: violation === 'abstract_reading'
        ? propositions.map((proposition) => proposition.kind)
        : [],
    },
    requiredPropositionCoverage: propositions.map((proposition) => proposition.kind),
    evidenceIds: [...new Set(propositions.flatMap((proposition) => proposition.evidenceIds))],
  };
}
