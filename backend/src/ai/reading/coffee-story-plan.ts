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

function personalizationSections(personalization?: ReadingPersonalization): CoffeePublicSection[] {
  const supplied = [
    personalization?.intention,
    personalization?.memorySummary,
    ...(personalization?.relevantThemes ?? []),
  ].filter(Boolean).join(' ').toLocaleLowerCase('tr-TR');
  const sections: CoffeePublicSection[] = [];
  const words = new Set(supplied.match(/\p{L}+/gu) ?? []);
  const hasAny = (allowed: string[]) => allowed.some((word) => words.has(word));
  if (hasAny(['aşk', 'aşkım', 'aşkı', 'ilişki', 'ilişkim', 'ilişkimi', 'ilişkimde', 'partner', 'partnerim', 'love', 'relationship'])) sections.push('love');
  if (hasAny(['kariyer', 'kariyerim', 'kariyerimde', 'iş', 'işim', 'işimde', 'işimi', 'meslek', 'mesleğim', 'career', 'job', 'work'])) sections.push('career');
  if (hasAny(['para', 'param', 'parasal', 'kazanç', 'kazancım', 'maddi', 'money', 'finance'])) sections.push('money');
  return sections;
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
    ...personalizationSections(personalization),
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
    ...personalizationSections(personalization),
  ];
  if (planned.some((proposition) => proposition.timing === 'nearer_term')) {
    authorizedSections.push('nearFuture');
  }
  const forbiddenAssumptions = [
    ...new Set(ordered.flatMap((proposition) => proposition.forbiddenAssumptions)),
  ];
  const suppliedContext = [
    personalization?.intention,
    personalization?.memorySummary,
    ...(personalization?.relevantThemes ?? []),
  ].filter(Boolean).join(' ').toLocaleLowerCase('tr-TR');
  const authorizedForbiddenExceptions = new Set<CoffeeForbiddenAssumption>();
  if (/decision|choice|karar|seçim/.test(suppliedContext)) {
    authorizedForbiddenExceptions.add('current_major_decision');
    authorizedForbiddenExceptions.add('options_assumption');
  }
  if (/relationship|partner|ilişki|aşk/.test(suppliedContext)) {
    authorizedForbiddenExceptions.add('existing_relationship');
  }
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
        forbiddenAssumptions: forbiddenAssumptions.filter(
          (assumption) => !authorizedForbiddenExceptions.has(assumption),
        ),
      },
      depth: capacity === 'rich'
        ? { overallWords: { min: 40, max: 70 }, takeawayWords: { min: 10, max: 18 } }
        : { overallWords: { min: 26, max: 45 }, takeawayWords: { min: 9, max: 16 } },
    },
  };
}

export function buildCoffeeWriterPacketV2(
  locale: AppLanguage,
  plan: CoffeeStoryPlanV2,
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
    ...(personalization ? { personalization } : {}),
  };
}
