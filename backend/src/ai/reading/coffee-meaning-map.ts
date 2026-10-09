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

/**
 * Token-boundary lexicon matcher. Folded text is split into letter/digit
 * tokens (whitespace, punctuation, hyphens and slashes all separate). A term
 * word matches one whole token, optionally followed by a plain plural
 * (English s/es, Turkish lar/ler) — never a verb ending, so "lettering" is
 * not "letter"; a word ending in `*` is an explicit stem and matches any token
 * that starts with it; a word starting with `*` is an explicit compound head
 * ("*bird" → "seabird"). A multi-word term must match consecutive tokens.
 * Otherwise compounds never match their parts ("roadside", "keyhole",
 * "fishbone"), and a term never matches inside another word ("string",
 * "monkey", "hearth").
 */
const TERM_INFLECTIONS = ['', 's', 'es', 'lar', 'ler'];

function coffeeTokens(folded: string): string[] {
  return folded.match(/[\p{L}\p{N}]+/gu) ?? [];
}

function tokenMatchesWord(token: string, word: string): boolean {
  if (word.endsWith('*')) return token.startsWith(word.slice(0, -1));
  if (word.startsWith('*')) return TERM_INFLECTIONS.some((suffix) => token.endsWith(word.slice(1) + suffix));
  return TERM_INFLECTIONS.some((suffix) => token === word + suffix);
}

function coffeeLexiconMatch(tokens: string[], terms: readonly string[]): boolean {
  return terms.some((term) => {
    const words = term.split(' ');
    for (let start = 0; start + words.length <= tokens.length; start += 1) {
      if (words.every((word, offset) => tokenMatchesWord(tokens[start + offset], word))) return true;
    }
    return false;
  });
}

/** True when `text` (folded here) contains one of `terms` as a lexical term. */
export function coffeeTermMatch(text: string, terms: readonly string[]): boolean {
  return coffeeLexiconMatch(coffeeTokens(coffeeFold(text)), terms);
}

/** Precedence is the array order. Terms are already coffeeFold-ed. */
const FAMILY_LEXICON: ReadonlyArray<readonly [CoffeeMeaningFamily, readonly string[]]> = [
  ['communication', ['*bird', 'kus', 'letter', 'mektup', 'message', 'mesaj', 'envelope', 'zarf']],
  ['opportunity', ['fish', 'balik']],
  ['bond', ['ring', 'yuzuk']],
  ['emotional_relevance', ['heart', 'kalp']],
  ['solution', ['key', 'anahtar']],
  ['movement', ['road', 'path', 'route', 'yol', 'patika']],
  ['growth', ['tree', 'agac']],
  ['social_relevance', ['person', 'figure', 'face', 'insan', 'kisi', 'siluet', 'yuz']],
];
const CHOICE_TERMS = ['diverg*', 'fork', 'forked', 'crossroad', 'ikiye ayr*', 'yol ayr*'];

/** Private source → broad family. Shared by the C2.11 semantic-cue layer. */
export function coffeeMeaningFamily(item: ReadingEvidenceItem): CoffeeMeaningFamily | null {
  const resemblance = coffeeTokens(coffeeFold(item.resemblance?.trim() ?? ''));
  const description = coffeeTokens(coffeeFold(item.description));
  // A choice signal counts in either field; the '|' token keeps a phrase
  // from spanning the two fields.
  if (coffeeLexiconMatch([...resemblance, '|', ...description], CHOICE_TERMS)) return 'choice';
  for (const [family, terms] of FAMILY_LEXICON) {
    if (coffeeLexiconMatch(resemblance, terms)) return family;
  }
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
