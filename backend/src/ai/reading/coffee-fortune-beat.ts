import type { CoffeePropositionKind } from './coffee-semantic-propositions.js';
import type { CoffeeIntentionSubjectKind } from './coffee-intention-context.js';
import type { CoffeeSemanticCue, CoffeeSemanticCueKind } from './coffee-semantic-cues.js';

/**
 * C2.11 — CONTROLLED FORTUNE BEAT. A deterministic, machine-oriented
 * permission for the TYPE of life development a private cue may carry. It is
 * deliberate, bounded fortune conjecture: the writer may tell that this kind of
 * development is coming for the trusted subject, never its external specifics.
 * Not prose, not a synonym list.
 */
export type CoffeeFortuneBeatKind =
  | 'contact_emergence'
  | 'written_exchange'
  | 'opening_emerges'
  | 'commitment_forms'
  | 'feeling_deepens'
  | 'way_through_appears'
  | 'direction_shifts'
  | 'gradual_accumulation'
  | 'alternatives_clarify'
  | 'people_gather';

/** External specifics a beat can never supply, whatever the subject. */
export type CoffeeForbiddenSpecific =
  | 'exact_person'
  | 'sender_identity'
  | 'employer_or_company'
  | 'monetary_amount'
  | 'salary_or_debt'
  /** C2.11A: an incoming payment / deposit / bonus EVENT (distinct from a salary or debt state and from a quantity). */
  | 'payment_event'
  | 'exact_event'
  | 'relationship_history'
  | 'other_person_feelings'
  | 'other_person_intent'
  | 'guaranteed_contact'
  | 'guaranteed_outcome'
  | 'date'
  | 'chronology'
  | 'unsupported_causation'
  | 'prior_problem'
  | 'travel_or_relocation'
  | 'invented_options';

export type CoffeeFortuneBeat = {
  kind: CoffeeFortuneBeatKind;
  cue: CoffeeSemanticCueKind;
  proposition: CoffeePropositionKind;
  /** Trusted subject the beat is realized FOR; null = no intention supplied. */
  subject: CoffeeIntentionSubjectKind | null;
  evidenceIds: string[];
  timing: 'unspecified' | 'nearer_term';
  support: 'single' | 'independent_repeat';
  /** Certainty is carried by the contract, not by repeated hedge words. */
  modality: 'probable';
  role: 'main_development' | 'second_angle';
  forbiddenSpecifics: CoffeeForbiddenSpecific[];
};

const BEAT_BY_CUE: Record<Exclude<CoffeeSemanticCueKind, 'proximate_context'>, CoffeeFortuneBeatKind> = {
  incoming_contact: 'contact_emergence',
  written_contact: 'written_exchange',
  available_opening: 'opening_emerges',
  commitment_bond: 'commitment_forms',
  emotional_weight: 'feeling_deepens',
  access_answer: 'way_through_appears',
  directional_progress: 'direction_shifts',
  gradual_growth: 'gradual_accumulation',
  alternative_split: 'alternatives_clarify',
  people_presence: 'people_gather',
};

const PROPOSITION_BY_CUE: Record<Exclude<CoffeeSemanticCueKind, 'proximate_context'>, CoffeePropositionKind> = {
  incoming_contact: 'exchange_emergence',
  written_contact: 'exchange_emergence',
  available_opening: 'opening_availability',
  commitment_bond: 'connection_continuity',
  emotional_weight: 'felt_significance',
  access_answer: 'resolution_availability',
  directional_progress: 'directional_change',
  gradual_growth: 'gradual_expansion',
  alternative_split: 'alternative_distinction',
  people_presence: 'social_presence',
};

const COMMON_SPECIFICS: CoffeeForbiddenSpecific[] = [
  'exact_person', 'employer_or_company', 'monetary_amount', 'salary_or_debt', 'payment_event', 'exact_event',
  'relationship_history', 'other_person_feelings', 'other_person_intent', 'guaranteed_outcome',
  'date', 'chronology', 'unsupported_causation',
];

const BEAT_SPECIFICS: Record<CoffeeFortuneBeatKind, CoffeeForbiddenSpecific[]> = {
  contact_emergence: ['sender_identity', 'guaranteed_contact'],
  written_exchange: ['sender_identity', 'guaranteed_contact'],
  opening_emerges: [],
  commitment_forms: ['guaranteed_contact'],
  feeling_deepens: [],
  way_through_appears: ['prior_problem'],
  direction_shifts: ['travel_or_relocation'],
  gradual_accumulation: [],
  alternatives_clarify: ['invented_options'],
  people_gather: ['sender_identity'],
};

/** Deterministic tie-break among beats of equal support. */
const BEAT_PRIORITY: CoffeeFortuneBeatKind[] = [
  'way_through_appears', 'written_exchange', 'contact_emergence', 'opening_emerges',
  'feeling_deepens', 'commitment_forms', 'alternatives_clarify', 'gradual_accumulation',
  'direction_shifts', 'people_gather',
];

/**
 * One beat per DISTINCT cue (repeated identical evidence only raises support).
 * The main development belongs to the lead proposition; every other beat adds
 * a second angle. Context-only cues never become beats.
 */
export function planCoffeeFortuneBeats(
  cues: CoffeeSemanticCue[],
  leadProposition: CoffeePropositionKind,
  subject: CoffeeIntentionSubjectKind | null,
): { lead: CoffeeFortuneBeat; supporting: CoffeeFortuneBeat[] } | null {
  const beats = cues
    .filter((cue): cue is CoffeeSemanticCue & { kind: Exclude<CoffeeSemanticCueKind, 'proximate_context'> } =>
      cue.kind !== 'proximate_context')
    .map((cue): CoffeeFortuneBeat => {
      const kind = BEAT_BY_CUE[cue.kind];
      return {
        kind,
        cue: cue.kind,
        proposition: PROPOSITION_BY_CUE[cue.kind],
        subject,
        evidenceIds: cue.evidenceIds,
        timing: cue.timing,
        support: cue.support,
        modality: 'probable',
        role: 'second_angle',
        forbiddenSpecifics: [...COMMON_SPECIFICS, ...BEAT_SPECIFICS[kind]],
      };
    })
    .sort((a, b) =>
      Number(b.proposition === leadProposition) - Number(a.proposition === leadProposition)
      || Number(b.support === 'independent_repeat') - Number(a.support === 'independent_repeat')
      || BEAT_PRIORITY.indexOf(a.kind) - BEAT_PRIORITY.indexOf(b.kind));
  if (beats.length === 0) return null;
  const [lead, ...supporting] = beats;
  return { lead: { ...lead, role: 'main_development' }, supporting };
}
