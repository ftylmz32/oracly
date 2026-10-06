import type { CoffeeMeaningFacet, CoffeeMeaningFamily } from './coffee-meaning-map.js';

export type CoffeePropositionKind =
  | 'exchange_emergence'
  | 'opening_availability'
  | 'connection_continuity'
  | 'felt_significance'
  | 'resolution_availability'
  | 'directional_change'
  | 'alternative_distinction'
  | 'gradual_expansion'
  | 'social_presence'
  | 'proximate_context';

export type CoffeeForbiddenAssumption =
  | 'prior_problem'
  | 'awaited_topic'
  | 'existing_relationship'
  | 'specific_other_person'
  | 'reciprocal_feeling'
  | 'prior_stagnation'
  | 'current_major_decision'
  | 'options_assumption'
  | 'current_job_issue'
  | 'money_event'
  | 'family_event'
  | 'travel'
  | 'relocation'
  | 'guaranteed_outcome'
  | 'chronology'
  | 'causation'
  | 'advice';

export type CoffeeSemanticProposition = {
  kind: CoffeePropositionKind;
  evidenceIds: string[];
  context: 'general' | 'home_close_circle';
  timing: 'unspecified' | 'nearer_term';
  support: 'single' | 'independent_repeat';
  forbiddenAssumptions: CoffeeForbiddenAssumption[];
};

export type CoffeeSemanticCapacity = 'insufficient' | 'modest' | 'rich';

const KIND_BY_FAMILY: Record<CoffeeMeaningFamily, CoffeePropositionKind> = {
  communication: 'exchange_emergence',
  opportunity: 'opening_availability',
  bond: 'connection_continuity',
  emotional_relevance: 'felt_significance',
  solution: 'resolution_availability',
  movement: 'directional_change',
  choice: 'alternative_distinction',
  growth: 'gradual_expansion',
  social_relevance: 'social_presence',
  home_close_circle: 'proximate_context',
};

const COMMON: CoffeeForbiddenAssumption[] = [
  'specific_other_person',
  'current_job_issue',
  'money_event',
  'family_event',
  'current_major_decision',
  'options_assumption',
  'guaranteed_outcome',
  'chronology',
  'causation',
  'advice',
];

const FAMILY_FORBIDDEN: Record<CoffeeMeaningFamily, CoffeeForbiddenAssumption[]> = {
  communication: ['awaited_topic'],
  opportunity: ['prior_stagnation'],
  bond: ['existing_relationship', 'reciprocal_feeling'],
  emotional_relevance: ['existing_relationship', 'reciprocal_feeling'],
  solution: ['prior_problem'],
  movement: ['prior_stagnation', 'travel', 'relocation'],
  choice: ['current_major_decision'],
  growth: ['prior_stagnation'],
  social_relevance: ['existing_relationship', 'reciprocal_feeling'],
  home_close_circle: ['existing_relationship', 'reciprocal_feeling'],
};

export function mapCoffeePropositions(facets: CoffeeMeaningFacet[]): CoffeeSemanticProposition[] {
  const propositions = new Map<CoffeePropositionKind, CoffeeSemanticProposition>();
  for (const facet of facets) {
    const kind = KIND_BY_FAMILY[facet.family];
    const prior = propositions.get(kind);
    if (prior) {
      prior.evidenceIds = [...new Set([...prior.evidenceIds, ...facet.evidenceIds])];
      prior.support = prior.evidenceIds.length > 1 ? 'independent_repeat' : 'single';
      if (facet.context === 'home_close_circle') prior.context = 'home_close_circle';
      if (facet.timing === 'nearer_term') prior.timing = 'nearer_term';
      continue;
    }
    propositions.set(kind, {
      kind,
      evidenceIds: [...facet.evidenceIds],
      context: facet.context,
      timing: facet.timing,
      support: facet.evidenceIds.length > 1 ? 'independent_repeat' : 'single',
      forbiddenAssumptions: [...new Set([...COMMON, ...FAMILY_FORBIDDEN[facet.family]])],
    });
  }
  return [...propositions.values()];
}

export function coffeeSemanticCapacity(
  propositions: CoffeeSemanticProposition[],
): CoffeeSemanticCapacity {
  if (propositions.length === 0) return 'insufficient';
  if (propositions.length >= 2) return 'rich';
  const only = propositions[0];
  if (only.kind === 'proximate_context') return 'insufficient';
  return only.support === 'independent_repeat' ? 'modest' : 'insufficient';
}
