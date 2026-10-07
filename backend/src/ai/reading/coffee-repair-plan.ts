import type { CoffeeNarrative } from './types.js';
import type { AppLanguage } from '../app-language.js';
import type {
  CoffeeForbiddenAssumption,
  CoffeePropositionKind,
} from './coffee-semantic-propositions.js';
import type { CoffeePublicSection, CoffeeStoryPlanV2 } from './coffee-story-plan.js';
import {
  coffeeLengthDeficits,
  coffeeLengthRequirements,
  type CoffeeLengthDeficit,
  type CoffeeLengthRequirements,
} from './coffee-length-contract.js';
import type { CoffeeStorySubject } from './coffee-intention-context.js';

export type CoffeeRepairDefect =
  | 'structural_deficit'
  | 'abstract_realization'
  | 'unsupported_concretization'
  | 'multiple_renderings'
  | 'synthesis_redundancy'
  /** C2.9: the trusted subject section is empty or the subject was dropped/denied. */
  | 'subject_alignment'
  /** C2.9: the prose described the reading or explained synthesis rules. */
  | 'natural_realization'
  /** C2.11: the request label carried the reading; realize the subject instead. */
  | 'subject_realization'
  /** C2.11: the prose defined the planned meaning; tell the fortune development. */
  | 'fortune_realization'
  | 'privacy_or_contract';

export type CoffeeRepairPlan = {
  version: 2;
  locale: AppLanguage;
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
  lengthDeficits?: CoffeeLengthDeficit[];
  /** C2.9: the same authoritative contract the writer received and acceptance uses. */
  lengthRequirements?: CoffeeLengthRequirements;
  /**
   * C2.9: the user's trusted reading subject (explicit user input, never
   * visual evidence). Repair must answer it; becoming generic is invalid.
   */
  subject?: CoffeeStorySubject & {
    issue: 'missing_subject_section' | 'subject_drift' | null;
  };
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
    || violation === 'unsupported_chronology'
    || violation === 'context_event'
  ) {
    return 'unsupported_concretization';
  }
  if (violation === 'possibility_menu') return 'multiple_renderings';
  if (violation === 'section_redundancy' || violation === 'insight_collapse' || violation === 'component_serialization') {
    return 'synthesis_redundancy';
  }
  if (violation === 'missing_intention_subject' || violation === 'intention_subject_drift') return 'subject_alignment';
  if (violation === 'meta_narration') return 'natural_realization';
  if (violation === 'intention_parroting') return 'subject_realization';
  if (violation === 'semantic_restatement') return 'fortune_realization';
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
          : violation === 'unsupported_chronology'
            ? ['chronology']
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
  locale: AppLanguage,
  lengthRequirements?: CoffeeLengthRequirements,
): CoffeeRepairPlan;
/** Frozen pre-C2.7B corpus compatibility; production must supply locale. */
export function buildCoffeeRepairPlan(
  narrative: CoffeeNarrative,
  violation: string,
  storyPlan: CoffeeStoryPlanV2,
): Omit<CoffeeRepairPlan, 'locale'>;
export function buildCoffeeRepairPlan(
  narrative: CoffeeNarrative,
  violation: string,
  storyPlan: CoffeeStoryPlanV2,
  locale?: AppLanguage,
  suppliedRequirements?: CoffeeLengthRequirements,
): CoffeeRepairPlan | Omit<CoffeeRepairPlan, 'locale'> {
  // One contract: the pipeline passes the writer packet's own requirements.
  const lengthRequirements = suppliedRequirements ?? coffeeLengthRequirements({ storyPlan });
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
    ...(locale ? { locale } : {}),
    violation,
    storyPlan,
    requiredSections: ['visualObservation', 'overall', 'takeaway'],
    sectionDeficits,
    ...(violation === 'too_short'
      ? { lengthDeficits: coffeeLengthDeficits(narrative, lengthRequirements) }
      : {}),
    lengthRequirements,
    ...(storyPlan.subject
      ? {
          subject: {
            ...storyPlan.subject,
            issue: violation === 'missing_intention_subject'
              ? 'missing_subject_section' as const
              : violation === 'intention_subject_drift'
                ? 'subject_drift' as const
                : null,
          },
        }
      : {}),
    unauthorizedSectionsToClear,
    forbiddenClaimCategoriesTriggered: triggeredClaims(violation, storyPlan),
    defect: {
      kind: defectKind(violation),
      propositionKinds: violation === 'abstract_reading'
        || violation === 'meta_narration'
        || violation === 'intention_parroting'
        || violation === 'semantic_restatement'
        ? propositions.map((proposition) => proposition.kind)
        : [],
    },
    requiredPropositionCoverage: propositions.map((proposition) => proposition.kind),
    evidenceIds: [...new Set(propositions.flatMap((proposition) => proposition.evidenceIds))],
  };
}
