import type { CoffeeObservation, ReadingEvidenceItem } from './types.js';
import {
  coffeeMeaningFamily,
  coffeeTermMatch,
  coffeeRegionState,
  type CoffeeMeaningFamily,
} from './coffee-meaning-map.js';

/**
 * C2.11 — PRIVATE SEMANTIC CUE. One step finer than the broad meaning family:
 * it keeps the distinctions the source already carries (an incoming contact is
 * not a written one) so the writer can realize a specific development instead
 * of restating a family. Machine tokens only: a cue name is the private
 * interpretation of the evidence, never the source label, and never prose.
 * Only the source classes production Coffee already recognizes are mapped.
 */
export type CoffeeSemanticCueKind =
  | 'incoming_contact'
  | 'written_contact'
  | 'available_opening'
  | 'commitment_bond'
  | 'emotional_weight'
  | 'access_answer'
  | 'directional_progress'
  | 'gradual_growth'
  | 'alternative_split'
  | 'people_presence'
  | 'proximate_context';

export type CoffeeSemanticCue = {
  kind: CoffeeSemanticCueKind;
  family: CoffeeMeaningFamily;
  evidenceIds: string[];
  context: 'general' | 'home_close_circle';
  timing: 'unspecified' | 'nearer_term';
  /** Repeated identical evidence adds support, never another cue. */
  support: 'single' | 'independent_repeat';
};

const CUE_BY_FAMILY: Record<Exclude<CoffeeMeaningFamily, 'communication'>, CoffeeSemanticCueKind> = {
  opportunity: 'available_opening',
  bond: 'commitment_bond',
  emotional_relevance: 'emotional_weight',
  solution: 'access_answer',
  movement: 'directional_progress',
  growth: 'gradual_growth',
  choice: 'alternative_split',
  social_relevance: 'people_presence',
  home_close_circle: 'proximate_context',
};

/** Written word (letter / message / envelope) vs. contact arriving (bird). Lexical terms, never substrings. */
const WRITTEN_TERMS = ['letter', 'mektup', 'message', 'mesaj', 'envelope', 'zarf'];

function cueKind(item: ReadingEvidenceItem, family: CoffeeMeaningFamily): CoffeeSemanticCueKind {
  if (family !== 'communication') return CUE_BY_FAMILY[family];
  return coffeeTermMatch(item.resemblance ?? '', WRITTEN_TERMS) ? 'written_contact' : 'incoming_contact';
}

/** Same acceptance rules as `mapCoffeeMeanings`; cues refine, never widen, the facets. */
export function mapCoffeeSemanticCues(obs: Pick<CoffeeObservation, 'evidence'>): CoffeeSemanticCue[] {
  const cues = new Map<CoffeeSemanticCueKind, CoffeeSemanticCue>();
  for (const item of obs.evidence) {
    if (item.confidence === 'low' || item.visibility === 'uncertain') continue;
    const state = coffeeRegionState(item);
    const family = coffeeMeaningFamily(item)
      ?? (state.context === 'home_close_circle' ? 'home_close_circle' : null);
    if (!family) continue;
    const kind = cueKind(item, family);
    const prior = cues.get(kind);
    if (prior) {
      prior.evidenceIds = [...new Set([...prior.evidenceIds, item.id])];
      prior.support = prior.evidenceIds.length > 1 ? 'independent_repeat' : 'single';
      if (state.context === 'home_close_circle') prior.context = 'home_close_circle';
      if (state.timing === 'nearer_term') prior.timing = 'nearer_term';
      continue;
    }
    cues.set(kind, { kind, family, evidenceIds: [item.id], ...state, support: 'single' });
  }
  return [...cues.values()];
}
