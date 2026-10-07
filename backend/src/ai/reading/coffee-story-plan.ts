import type { AppLanguage } from '../app-language.js';
import type { ReadingPersonalization } from './types.js';
import type { CoffeeMeaningFacet, CoffeeMeaningFamily } from './coffee-meaning-map.js';
import {
  coffeeSemanticCapacity,
  type CoffeeForbiddenAssumption,
  type CoffeePropositionKind,
  type CoffeeSemanticCapacity,
  type CoffeeSemanticProposition,
} from './coffee-semantic-propositions.js';
import {
  classifyCoffeeIntention,
  coffeePersonalizationSections,
  coffeeStorySubject,
  type CoffeeStorySubject,
} from './coffee-intention-context.js';
import type { CoffeeLengthRequirements } from './coffee-length-contract.js';

export type CoffeePublicSection =
  | 'visualObservation'
  | 'overall'
  | 'love'
  | 'career'
  | 'money'
  | 'nearFuture'
  | 'takeaway';

export type CoffeePlannedComponent = {
  family: CoffeeMeaningFamily;
  evidenceIds: string[];
  context: 'general' | 'home_close_circle';
  timing: 'unspecified' | 'nearer_term';
};

export type CoffeeStoryPlan = {
  specificity: 'single' | 'multi' | 'sparse';
  lead: CoffeePlannedComponent;
  supporting: Array<CoffeePlannedComponent & { relation: 'nuance' | 'co_occurring' }>;
  authorizedContexts: Array<'home_close_circle'>;
  authorizedTiming: 'unspecified' | 'nearer_term';
  authorizedSections: CoffeePublicSection[];
  depth: {
    overallWords: { min: number; max: number };
    takeawayWords: { min: number; max: number };
  };
};

export type CoffeeStoryPlanningResult =
  | { status: 'ready'; plan: CoffeeStoryPlan }
  | { status: 'insufficient_semantic_signal'; reason: 'no_safe_semantic_facets' };

export type CoffeeWriterPacket = {
  locale: AppLanguage;
  storyPlan: CoffeeStoryPlan;
  constraints: {
    oneRenderingPerComponent: true;
    noAliasMenus: true;
    noUnsupportedBackstory: true;
    noSourceMetaphorEcho: true;
    requiredSections: ['visualObservation', 'overall', 'takeaway'];
  };
  personalization?: ReadingPersonalization;
};

export type CoffeePlannedProposition = Omit<CoffeeSemanticProposition, 'forbiddenAssumptions'>;

export type CoffeeStoryPlanV2 = {
  version: 2;
  semanticCapacity: Exclude<CoffeeSemanticCapacity, 'insufficient'>;
  lead: CoffeePlannedProposition;
  supporting: Array<CoffeePlannedProposition & { relation: 'co_occurring' }>;
  synthesis: {
    mode: 'single_realization' | 'unified_cooccurrence';
    required: true;
    forbiddenRelations: Array<'causation' | 'chronology' | 'component_serialization'>;
  };
  authorizedContexts: Array<'home_close_circle'>;
  authorizedTiming: 'unspecified' | 'nearer_term';
  authorizedSections: CoffeePublicSection[];
  claimEnvelope: {
    allowedPropositionKinds: CoffeePropositionKind[];
    forbiddenAssumptions: CoffeeForbiddenAssumption[];
  };
  depth: {
    overallWords: { min: number; max: number };
    takeawayWords: { min: number; max: number };
  };
  /** C2.9: present only when a trusted intention exists — the user's reading subject. */
  subject?: CoffeeStorySubject;
};

export type CoffeeStoryPlanningResultV2 =
  | { status: 'ready'; plan: CoffeeStoryPlanV2 }
  | {
      status: 'insufficient_semantic_signal';
      reason: 'no_safe_semantic_facets' | 'insufficient_semantic_capacity';
    };

export type CoffeeWriterPacketV2 = {
  locale: AppLanguage;
  storyPlan: CoffeeStoryPlanV2;
  constraints: CoffeeWriterPacket['constraints'] & {
    realizePropositionsNotTaxonomy: true;
    unifiedSynthesis: true;
  };
  /** C2.9: the ONE authoritative length contract (same source as acceptance). */
  lengthRequirements: CoffeeLengthRequirements;
  personalization?: ReadingPersonalization;
};

export type CoffeeAnyStoryPlan = CoffeeStoryPlan | CoffeeStoryPlanV2;
export type CoffeeAnyWriterPacket = CoffeeWriterPacket | CoffeeWriterPacketV2;

const PRIORITY: CoffeeMeaningFamily[] = [
  'solution',
  'communication',
  'opportunity',
  'emotional_relevance',
  'bond',
  'choice',
  'growth',
  'movement',
  'home_close_circle',
  'social_relevance',
];

function mergeFacets(facets: CoffeeMeaningFacet[]): CoffeePlannedComponent[] {
  const merged = new Map<CoffeeMeaningFamily, CoffeePlannedComponent>();
  for (const facet of facets) {
    const prior = merged.get(facet.family);
    if (!prior) {
      merged.set(facet.family, {
        family: facet.family,
        evidenceIds: [...facet.evidenceIds],
        context: facet.context,
        timing: facet.timing,
      });
      continue;
    }
    prior.evidenceIds = [...new Set([...prior.evidenceIds, ...facet.evidenceIds])];
    if (facet.context === 'home_close_circle') prior.context = 'home_close_circle';
    if (facet.timing === 'nearer_term') prior.timing = 'nearer_term';
  }
  return [...merged.values()].sort(
    (a, b) => PRIORITY.indexOf(a.family) - PRIORITY.indexOf(b.family),
  );
}

export function planCoffeeStory(
  facets: CoffeeMeaningFacet[],
  personalization?: ReadingPersonalization,
): CoffeeStoryPlanningResult {
  const components = mergeFacets(facets);
  if (components.length === 0) {
    return { status: 'insufficient_semantic_signal', reason: 'no_safe_semantic_facets' };
  }
  const lead = components[0];
  const sparse = components.length === 1 && lead.family === 'home_close_circle';
  const authorizedSections: CoffeePublicSection[] = [
    'visualObservation',
    'overall',
    'takeaway',
    ...coffeePersonalizationSections(personalization),
  ];
  if (components.some((component) => component.timing === 'nearer_term')) {
    authorizedSections.push('nearFuture');
  }
  const specificity: CoffeeStoryPlan['specificity'] = sparse
    ? 'sparse'
    : components.length === 1
      ? 'single'
      : 'multi';
  return {
    status: 'ready',
    plan: {
      specificity,
      lead,
      supporting: components.slice(1).map((component) => ({
        ...component,
        relation: component.family === lead.family ? 'nuance' : 'co_occurring',
      })),
      authorizedContexts: components.some((component) => component.context === 'home_close_circle')
        ? ['home_close_circle']
        : [],
      authorizedTiming: components.some((component) => component.timing === 'nearer_term')
        ? 'nearer_term'
        : 'unspecified',
      authorizedSections: [...new Set(authorizedSections)],
      depth: specificity === 'multi'
        ? { overallWords: { min: 40, max: 70 }, takeawayWords: { min: 10, max: 18 } }
        : specificity === 'sparse'
          ? { overallWords: { min: 20, max: 35 }, takeawayWords: { min: 8, max: 14 } }
          : { overallWords: { min: 26, max: 45 }, takeawayWords: { min: 9, max: 16 } },
    },
  };
}

export function buildCoffeeWriterPacket(
  locale: AppLanguage,
  plan: CoffeeStoryPlan,
  personalization?: ReadingPersonalization,
): CoffeeWriterPacket {
  return {
    locale,
    storyPlan: plan,
    constraints: {
      oneRenderingPerComponent: true,
      noAliasMenus: true,
      noUnsupportedBackstory: true,
      noSourceMetaphorEcho: true,
      requiredSections: ['visualObservation', 'overall', 'takeaway'],
    },
    ...(personalization ? { personalization } : {}),
  };
}

const PROPOSITION_PRIORITY: CoffeePropositionKind[] = [
  'resolution_availability',
  'exchange_emergence',
  'opening_availability',
  'felt_significance',
  'connection_continuity',
  'alternative_distinction',
  'gradual_expansion',
  'directional_change',
  'proximate_context',
  'social_presence',
];

export function planCoffeeStoryV2(
  propositions: CoffeeSemanticProposition[],
  personalization?: ReadingPersonalization,
): CoffeeStoryPlanningResultV2 {
  const capacity = coffeeSemanticCapacity(propositions);
  if (capacity === 'insufficient') {
    return {
      status: 'insufficient_semantic_signal',
      reason: propositions.length === 0 ? 'no_safe_semantic_facets' : 'insufficient_semantic_capacity',
    };
  }
  const ordered = [...propositions].sort(
    (a, b) => PROPOSITION_PRIORITY.indexOf(a.kind) - PROPOSITION_PRIORITY.indexOf(b.kind),
  );
  const planned = ordered.map(({ forbiddenAssumptions: _forbidden, ...proposition }) => proposition);
  const authorizedSections: CoffeePublicSection[] = [
    'visualObservation',
    'overall',
    'takeaway',
    ...coffeePersonalizationSections(personalization),
  ];
  if (planned.some((proposition) => proposition.timing === 'nearer_term')) {
    authorizedSections.push('nearFuture');
  }
  const forbiddenAssumptions = [
    ...new Set(ordered.flatMap((proposition) => proposition.forbiddenAssumptions)),
  ];
  // C2.9: intention effects come ONLY from the trusted-intention contract.
  const intention = classifyCoffeeIntention(personalization?.intention);
  const exceptions = new Set<CoffeeForbiddenAssumption>(intention?.allowedAssumptionExceptions ?? []);
  const envelopeForbidden = [
    ...new Set([...forbiddenAssumptions, ...(intention?.intentionForbiddenAssumptions ?? [])]),
  ].filter((assumption) => !exceptions.has(assumption));
  return {
    status: 'ready',
    plan: {
      version: 2,
      semanticCapacity: capacity,
      lead: planned[0],
      supporting: planned.slice(1).map((proposition) => ({ ...proposition, relation: 'co_occurring' })),
      synthesis: {
        mode: planned.length === 1 ? 'single_realization' : 'unified_cooccurrence',
        required: true,
        forbiddenRelations: ['causation', 'chronology', 'component_serialization'],
      },
      authorizedContexts: planned.some((proposition) => proposition.context === 'home_close_circle')
        ? ['home_close_circle']
        : [],
      authorizedTiming: planned.some((proposition) => proposition.timing === 'nearer_term')
        ? 'nearer_term'
        : 'unspecified',
      authorizedSections: [...new Set(authorizedSections)],
      claimEnvelope: {
        allowedPropositionKinds: planned.map((proposition) => proposition.kind),
        forbiddenAssumptions: envelopeForbidden,
      },
      depth: capacity === 'rich'
        ? { overallWords: { min: 40, max: 70 }, takeawayWords: { min: 10, max: 18 } }
        : { overallWords: { min: 26, max: 45 }, takeawayWords: { min: 9, max: 16 } },
      ...(intention ? { subject: coffeeStorySubject(intention) } : {}),
    },
  };
}

export function buildCoffeeWriterPacketV2(
  locale: AppLanguage,
  plan: CoffeeStoryPlanV2,
  lengthRequirements: CoffeeLengthRequirements,
  personalization?: ReadingPersonalization,
): CoffeeWriterPacketV2 {
  return {
    locale,
    storyPlan: plan,
    constraints: {
      oneRenderingPerComponent: true,
      noAliasMenus: true,
      noUnsupportedBackstory: true,
      noSourceMetaphorEcho: true,
      requiredSections: ['visualObservation', 'overall', 'takeaway'],
      realizePropositionsNotTaxonomy: true,
      unifiedSynthesis: true,
    },
    lengthRequirements,
    ...(personalization ? { personalization } : {}),
  };
}
