import type { AppLanguage } from '../app-language.js';
import type {
  CoffeeObservation,
  ReadingPersonalization,
  ReadingEvidenceItem,
} from './types.js';
import {
  buildCoffeeWriterPacket as buildStoryPacket,
  buildCoffeeWriterPacketV2 as buildStoryPacketV2,
  planCoffeeStory,
  planCoffeeStoryV2,
  type CoffeeStoryPlanningResultV2,
  type CoffeeWriterPacketV2,
  type CoffeeStoryPlanningResult,
  type CoffeeWriterPacket,
} from './coffee-story-plan.js';
import { mapCoffeePropositions } from './coffee-semantic-propositions.js';
import { coffeeLengthRequirements } from './coffee-length-contract.js';
import { coffeeNarrativelySparse } from './coffee-diversity.js';
import { mapCoffeeSemanticCues } from './coffee-semantic-cues.js';

export type CoffeeMeaningFamily =
  | 'communication'
  | 'movement'
  | 'opportunity'
  | 'emotional_relevance'
  | 'bond'
  | 'solution'
  | 'growth'
  | 'social_relevance'
  | 'home_close_circle'
  | 'choice';

/** Private, machine-oriented semantic permission. Never contains output wording. */
export type CoffeeMeaningFacet = {
  family: CoffeeMeaningFamily;
  evidenceIds: string[];
  context: 'general' | 'home_close_circle';
  timing: 'unspecified' | 'nearer_term';
  specificity: 'direct' | 'contextual';
};

export function coffeeFold(value: string): string {
  return value
    .normalize('NFC')
    .toLocaleLowerCase('tr-TR')
    .replace(/ı/g, 'i')
    .replace(/ğ/g, 'g')
    .replace(/ü/g, 'u')
    .replace(/ş/g, 's')
    .replace(/ö/g, 'o')
    .replace(/ç/g, 'c');
}

/** Private source → broad family. Shared by the C2.11 semantic-cue layer. */
export function coffeeMeaningFamily(item: ReadingEvidenceItem): CoffeeMeaningFamily | null {
  const resemblance = coffeeFold(item.resemblance?.trim() ?? '');
  const description = coffeeFold(item.description);
  if (/diverg|fork|crossroad|ikiye ayr|yol ayr/.test(`${resemblance} ${description}`)) return 'choice';
  if (/bird|kus|letter|mektup|message|mesaj|zarf/.test(resemblance)) return 'communication';
  if (/fish|balik/.test(resemblance)) return 'opportunity';
  if (/ring|yuzuk/.test(resemblance)) return 'bond';
  if (/heart|kalp/.test(resemblance)) return 'emotional_relevance';
  if (/key|anahtar/.test(resemblance)) return 'solution';
  if (/road|path|route|yol|patika/.test(resemblance)) return 'movement';
  if (/tree|agac/.test(resemblance)) return 'growth';
  if (/person|figure|face|insan|kisi|sil[üu]et|yuz/.test(resemblance)) return 'social_relevance';
  return null;
}

export function coffeeRegionState(item: ReadingEvidenceItem): Pick<CoffeeMeaningFacet, 'context' | 'timing'> {
  const region = coffeeFold(item.region.replace(/_/g, ' '));
  return {
    context: /handle|kulp/.test(region) ? 'home_close_circle' : 'general',
    timing: /rim|upper|agiz|ust/.test(region) ? 'nearer_term' : 'unspecified',
  };
}

export function mapCoffeeMeanings(
  obs: CoffeeObservation,
  _language?: AppLanguage,
): CoffeeMeaningFacet[] {
  const facets: CoffeeMeaningFacet[] = [];
  for (const item of obs.evidence) {
    if (item.confidence === 'low' || item.visibility === 'uncertain') continue;
    const family = coffeeMeaningFamily(item);
    const state = coffeeRegionState(item);
    if (family) {
      facets.push({
        family,
        evidenceIds: [item.id],
        ...state,
        specificity: 'direct',
      });
    } else if (state.context === 'home_close_circle') {
      facets.push({
        family: 'home_close_circle',
        evidenceIds: [item.id],
        ...state,
        specificity: 'contextual',
      });
    }
  }
  return facets;
}

export function buildCoffeeWriterPacket(
  obs: CoffeeObservation,
  language: AppLanguage,
  personalization?: ReadingPersonalization,
): CoffeeWriterPacket | Exclude<CoffeeStoryPlanningResult, { status: 'ready' }> {
  const planned = planCoffeeStory(mapCoffeeMeanings(obs), personalization);
  if (planned.status !== 'ready') return planned;
  return buildStoryPacket(language, planned.plan, personalization);
}

/** Production C2.5 handoff. The legacy builder above remains for frozen corpus reproduction. */
export function buildCoffeeWriterPacketV2(
  obs: CoffeeObservation,
  language: AppLanguage,
  personalization?: ReadingPersonalization,
): CoffeeWriterPacketV2 | Exclude<CoffeeStoryPlanningResultV2, { status: 'ready' }> {
  const propositions = mapCoffeePropositions(mapCoffeeMeanings(obs, language));
  const planned = planCoffeeStoryV2(propositions, personalization, mapCoffeeSemanticCues(obs));
  if (planned.status !== 'ready') return planned;
  const lengthRequirements = coffeeLengthRequirements({
    narrativelySparse: coffeeNarrativelySparse(obs.evidence),
    storyPlan: planned.plan,
  });
  return buildStoryPacketV2(language, planned.plan, lengthRequirements, personalization);
}
