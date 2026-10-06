import type { AppLanguage } from '../app-language.js';
import type { ReadingPersonalization } from './types.js';
import type { CoffeeMeaningFacet, CoffeeMeaningFamily } from './coffee-meaning-map.js';

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
