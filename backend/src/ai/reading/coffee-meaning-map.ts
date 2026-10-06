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

function fold(value: string): string {
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

function meaningFamily(item: ReadingEvidenceItem): CoffeeMeaningFamily | null {
  const resemblance = fold(item.resemblance?.trim() ?? '');
  const description = fold(item.description);
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

function regionState(item: ReadingEvidenceItem): Pick<CoffeeMeaningFacet, 'context' | 'timing'> {
  const region = fold(item.region.replace(/_/g, ' '));
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
    const family = meaningFamily(item);
    const state = regionState(item);
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
  const planned = planCoffeeStoryV2(propositions, personalization);
  if (planned.status !== 'ready') return planned;
  return buildStoryPacketV2(language, planned.plan, personalization);
}
