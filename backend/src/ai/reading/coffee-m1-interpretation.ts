import type { CoffeeForbiddenSpecific } from './coffee-fortune-beat.js';
import {
  coffeeIntentionIsCanonical,
  type CoffeeSubjectSection,
  type CoffeeTrustedIntentionContext,
  type CoffeeUserDeclaredFact,
} from './coffee-intention-context.js';
import { coffeeTermMatch } from './coffee-meaning-map.js';
import type { CoffeeV3MapMark, CoffeeV3MarkMap } from './coffee-v3-mark-map.js';
import type { CoffeeV3Band, CoffeeV3Form, CoffeeV3RelationKind } from './types.js';

/**
 * M1 — PRIVATE INTERPRETATION ENGINE. ADDITIVE AND DARK: no live path,
 * writer, worker or route imports this yet.
 *
 * Input is ONLY the normalized CoffeeV3MarkMap (never the raw observation):
 * no description, confidence, visibility or photo coordinate reaches here.
 * Output `meaning` is machine-only structured fortune meaning (development,
 * horizon, valence, modifiers, conjecture permissions, forbidden specifics),
 * never prose, and passes assertCoffeeV3MeaningOnly. Evidence provenance
 * lives only in `audit`, which a writer packet must drop.
 *
 * Fortune conjecture is allowed (kısmet, haber, yeni yön…); fabricated
 * biography is not (person, sender, employer, amount, date, guarantee,
 * relationship history, another person's thoughts/feelings/intent).
 */

// ---------------------------------------------------------------------------
// Private sign vocabulary
// ---------------------------------------------------------------------------

export type CoffeeM1Sign =
  | 'incoming_contact'
  | 'written_contact'
  | 'opportunity'
  | 'commitment'
  | 'emotion'
  | 'access'
  | 'direction'
  | 'growth'
  | 'choice'
  | 'social_presence';

/** Curated lexicon, matched only on token boundaries (coffeeTermMatch). */
const SIGN_LEXICON: ReadonlyArray<readonly [CoffeeM1Sign, readonly string[]]> = [
  ['incoming_contact', ['*bird', 'kus']],
  ['written_contact', ['letter', 'mektup', 'message', 'mesaj', 'envelope', 'zarf']],
  ['opportunity', ['fish', 'balik']],
  ['commitment', ['ring', 'yuzuk']],
  ['emotion', ['heart', 'kalp']],
  ['access', ['key', 'anahtar']],
  ['direction', ['road', 'path', 'route', 'yol', 'patika']],
  ['growth', ['tree', 'agac']],
  ['choice', ['diverg*', 'fork', 'forked', 'crossroad', 'ikiye ayr*', 'yol ayr*']],
  ['social_presence', ['person', 'figure', 'face', 'insan', 'kisi', 'siluet', 'yuz']],
];

/**
 * Inside ONE label, a more specific sign subsumes its carrier: "a fork in a
 * path" is a choice, "a bird carrying a letter" is written contact. Any other
 * multi-sign label is ambiguous.
 */
const LABEL_SUBSUMES: ReadonlyArray<readonly [CoffeeM1Sign, CoffeeM1Sign]> = [
  ['choice', 'direction'],
  ['written_contact', 'incoming_contact'],
];

export type CoffeeM1LabelSign = CoffeeM1Sign | 'ambiguous' | null;

export function coffeeM1LabelSign(label: string): CoffeeM1LabelSign {
  const hits = new Set(SIGN_LEXICON.filter(([, terms]) => coffeeTermMatch(label, terms)).map(([sign]) => sign));
  for (const [specific, carrier] of LABEL_SUBSUMES) if (hits.has(specific)) hits.delete(carrier);
  if (hits.size === 0) return null;
  return hits.size === 1 ? [...hits][0] : 'ambiguous';
}

/**
 * Mark sign from USABLE candidates only (weak / partial-only candidates are
 * never usable). Same sign from every usable candidate → that sign; different
 * signs → ambiguous; nothing recognized → unmapped. No first-wins precedence.
 */
export function coffeeM1MarkSign(mark: Pick<CoffeeV3MapMark, 'candidates'>): CoffeeM1LabelSign {
  const signs = mark.candidates.filter((c) => c.usable).map((c) => coffeeM1LabelSign(c.label));
  if (signs.includes('ambiguous')) return 'ambiguous';
  const known = new Set(signs.filter((s): s is CoffeeM1Sign => s !== null));
  if (known.size === 0) return null;
  return known.size === 1 ? [...known][0] : 'ambiguous';
}

// ---------------------------------------------------------------------------
// Meaning model
// ---------------------------------------------------------------------------

export type CoffeeM1Development =
  | 'contact'
  | 'written_contact'
  | 'opportunity'
  | 'commitment'
  | 'emotional_movement'
  | 'access_opening'
  | 'direction_change'
  | 'gradual_growth'
  | 'choice_clarification'
  | 'social_presence';

const DEVELOPMENT_BY_SIGN: Record<CoffeeM1Sign, CoffeeM1Development> = {
  incoming_contact: 'contact',
  written_contact: 'written_contact',
  opportunity: 'opportunity',
  commitment: 'commitment',
  emotion: 'emotional_movement',
  access: 'access_opening',
  direction: 'direction_change',
  growth: 'gradual_growth',
  choice: 'choice_clarification',
  social_presence: 'social_presence',
};

/** M1.2: every trusted subject class is kept explicitly (custom ones are no longer folded into general). */
export type CoffeeM1Subject =
  | 'general'
  | 'love_relationships'
  | 'career_work'
  | 'money_finance'
  | 'person_of_interest'
  | 'custom_decision'
  | 'custom_other';

export function coffeeM1Subject(intention: CoffeeTrustedIntentionContext | null | undefined): CoffeeM1Subject {
  return intention?.subjectKind ?? 'general';
}

/**
 * Safe intent reference. A canonical product choice is fully described by the
 * structured subject, so its string is not repeated. Free text is passed only
 * as USER-PROVIDED context: never observer evidence, and it authorizes nothing
 * beyond the classifier's declaredFacts.
 */
export type CoffeeM1IntentReference =
  | { kind: 'none' }
  | { kind: 'canonical_choice' }
  | { kind: 'user_provided'; userDeclaredIntention: string };

/** Where a declared fact attaches a thread. chosen_person = Contract B. */
export type CoffeeM1ContextBinding = 'user_decision' | 'awaited_topic' | 'current_relationship' | 'chosen_person';

/** Overreach a context binding may never authorize (beyond the common forbidden specifics). */
export type CoffeeM1ContextForbidden =
  | 'option_identity'
  | 'correct_option'
  | 'response_certainty'
  | 'positive_response'
  | 'response_content'
  | 'response_timing'
  | 'partner_feelings'
  | 'partner_action'
  | 'relationship_outcome'
  | 'infidelity'
  | 'marriage_fact';

export type CoffeeM1Domain = 'financial' | 'career' | 'love';

export type CoffeeM1Horizon = 'nearer_term' | 'coming_period' | 'further_out' | 'unspecified';
export type CoffeeM1Valence = 'positive' | 'neutral' | 'cautionary';

export type CoffeeM1Modifier =
  | 'active'
  | 'quiet'
  | 'direct'
  | 'not_yet_open'
  | 'reaching'
  | 'continuing'
  | 'intermittent'
  | 'gaining_momentum'
  | 'visible_opening'
  | 'multi_stream'
  | 'steady'
  | 'long_running'
  | 'turning'
  | 'continuing_course'
  | 'upward_progression'
  | 'whole_durable'
  | 'singular_focus'
  | 'leaning'
  | 'usable_opening'
  | 'gathering'
  | 'recurring'
  | 'close_circle';

/** Conjecture permissions: what kind of fortune a later writer MAY tell. Tokens, not prose. */
export type CoffeeM1Conjecture =
  | 'news'
  | 'communication_movement'
  | 'written_news'
  | 'communication_about_chosen_person'
  | 'kismet'
  | 'opportunity'
  | 'beautiful_kismet'
  | 'lasting_bond_possibility'
  | 'serious_heart_kismet_possibility'
  | 'feelings_deepen'
  | 'heart_inclines'
  | 'path_opening'
  | 'way_through'
  | 'new_direction'
  | 'new_beginning'
  | 'gradual_development'
  | 'abundance'
  | 'options_clarify'
  | 'people_around'
  | 'opportunity_with_news'
  | 'opportunity_with_written_news'
  | 'growing_kismet'
  | 'heartfelt_lasting_bond_possibility'
  | 'opening_through_new_direction'
  | 'developing_change'
  | 'options_shape_direction'
  | 'communication_in_relationship'
  // M1.2 context / domain permissions
  | 'decision_clarity'
  | 'decision_direction'
  | 'communication_on_awaited_topic'
  | 'written_news_on_awaited_topic'
  | 'current_relationship_theme'
  | 'communication_in_current_relationship'
  | 'financial_opening'
  | 'financial_growth'
  | 'career_opening'
  | 'career_direction'
  | 'career_growth'
  | 'love_development';

export type CoffeeM1Combination =
  | 'contact_with_opportunity'
  | 'written_contact_with_opportunity'
  | 'opportunity_with_gradual_growth'
  | 'commitment_with_emotion'
  | 'access_through_direction'
  | 'direction_with_growth'
  | 'choice_with_direction'
  | 'contact_in_relationship';

export type CoffeeFortuneThread = {
  id: string;
  /** One development, or the two a curated combination joins. */
  developments: CoffeeM1Development[];
  combination: CoffeeM1Combination | null;
  /** 'linked' = a curated visual relation joins the pair; 'co_present' = same cup only. */
  linkage: 'single' | 'co_present' | 'linked';
  subject: CoffeeM1Subject;
  /** person_of_interest: the THEME is about the chosen person — never their state or action. */
  subjectBinding: 'person_of_interest' | null;
  /** M1.2: user-declared facts this thread is bound to (closed binding grammar). */
  contextBindings: CoffeeM1ContextBinding[];
  /** M1.2: domain wording permitted by the trusted subject (closed table); null = no domain. */
  domain: CoffeeM1Domain | null;
  /** M1.2: overreach the context bindings may never authorize. */
  contextForbidden: CoffeeM1ContextForbidden[];
  /**
   * Compatibility aggregate: the shared horizon when every development agrees,
   * otherwise the broad coming_period. Never the only timing signal.
   */
  horizon: CoffeeM1Horizon;
  /**
   * M1.1: timing PER DEVELOPMENT, in `developments` order. A combined thread
   * keeps each component's own horizon ("a nearer kısmet, growth over the
   * coming months"). Separate timings, never a sequence between them.
   */
  developmentHorizons: Array<{ development: CoffeeM1Development; horizon: CoffeeM1Horizon }>;
  valence: CoffeeM1Valence;
  modifiers: CoffeeM1Modifier[];
  conjecture: CoffeeM1Conjecture[];
  forbiddenSpecifics: CoffeeForbiddenSpecific[];
};

export type CoffeeM1Capacity = 'insufficient' | 'single_thread' | 'multi_thread' | 'rich';

/** Meaning-only: passes assertCoffeeV3MeaningOnly. This is all a writer may ever see. */
export type CoffeeM1Meaning = {
  subject: CoffeeM1Subject;
  /** USER DECLARATIONS from classifyCoffeeIntention only; never observer claims, never inferred. */
  declaredContext: CoffeeUserDeclaredFact[];
  intentReference: CoffeeM1IntentReference;
  capacity: CoffeeM1Capacity;
  threads: CoffeeFortuneThread[];
};

/** Private provenance; never part of a writer packet. */
export type CoffeeM1Audit = {
  threadEvidence: Record<string, { identityGroups: string[]; relationKinds: CoffeeV3RelationKind[] }>;
  ambiguousGroups: number;
  unmappedGroups: number;
  ignoredRelationKinds: CoffeeV3RelationKind[];
  saucerContext: 'none' | 'islands' | 'flow';
};

export type CoffeeM1Result = { meaning: CoffeeM1Meaning; audit: CoffeeM1Audit };

// ---------------------------------------------------------------------------
// Curated grammar tables
// ---------------------------------------------------------------------------

type FormRule = { field: keyof CoffeeV3Form; value: string; modifier: CoffeeM1Modifier };

/** Sign-specific form grammar. Closed: a form value with no row here means nothing. */
export const COFFEE_M1_FORM_GRAMMAR: Record<CoffeeM1Sign, readonly FormRule[]> = {
  incoming_contact: [
    { field: 'motion', value: 'moving', modifier: 'active' },
    { field: 'motion', value: 'still', modifier: 'quiet' },
    { field: 'openness', value: 'open', modifier: 'direct' },
    { field: 'openness', value: 'closed', modifier: 'not_yet_open' },
    { field: 'verticalDirection', value: 'descending', modifier: 'reaching' },
  ],
  written_contact: [
    { field: 'continuity', value: 'continuous', modifier: 'continuing' },
    { field: 'continuity', value: 'broken', modifier: 'intermittent' },
    { field: 'openness', value: 'open', modifier: 'direct' },
    { field: 'openness', value: 'closed', modifier: 'not_yet_open' },
  ],
  opportunity: [
    { field: 'motion', value: 'moving', modifier: 'active' },
    { field: 'verticalDirection', value: 'rising', modifier: 'gaining_momentum' },
    { field: 'openness', value: 'open', modifier: 'visible_opening' },
  ],
  growth: [
    { field: 'course', value: 'branching', modifier: 'multi_stream' },
    { field: 'posture', value: 'upright', modifier: 'steady' },
    { field: 'continuity', value: 'continuous', modifier: 'long_running' },
  ],
  direction: [
    { field: 'course', value: 'bending', modifier: 'turning' },
    { field: 'course', value: 'straight', modifier: 'continuing_course' },
    { field: 'verticalDirection', value: 'rising', modifier: 'upward_progression' },
    { field: 'continuity', value: 'continuous', modifier: 'long_running' },
  ],
  commitment: [
    { field: 'openness', value: 'closed', modifier: 'whole_durable' },
    { field: 'grouping', value: 'isolated', modifier: 'singular_focus' },
  ],
  emotion: [{ field: 'posture', value: 'tilted', modifier: 'leaning' }],
  access: [{ field: 'openness', value: 'open', modifier: 'usable_opening' }],
  choice: [],
  social_presence: [{ field: 'grouping', value: 'clustered', modifier: 'gathering' }],
};

/** Curated base valence per sign; only the rows below move it. Never from confidence/visibility/size. */
const BASE_VALENCE: Record<CoffeeM1Sign, CoffeeM1Valence> = {
  incoming_contact: 'neutral',
  written_contact: 'neutral',
  opportunity: 'positive',
  commitment: 'positive',
  emotion: 'neutral',
  access: 'positive',
  direction: 'neutral',
  growth: 'positive',
  choice: 'neutral',
  social_presence: 'neutral',
};
/** Fragmented written contact reads as "patience", not as good news. */
const CAUTIONARY_MODIFIERS: ReadonlyArray<readonly [CoffeeM1Sign, CoffeeM1Modifier]> = [
  ['written_contact', 'intermittent'],
];
const OPPORTUNITY_POSITIVE_FORM: CoffeeM1Modifier[] = ['active', 'gaining_momentum', 'visible_opening'];

const HORIZON_BY_BAND: Record<CoffeeV3Band, CoffeeM1Horizon> = {
  rim_upper: 'nearer_term',
  middle: 'coming_period',
  lower_base: 'further_out',
  unknown: 'unspecified',
};

const COMMON_FORBIDDEN: CoffeeForbiddenSpecific[] = [
  'exact_person', 'employer_or_company', 'monetary_amount', 'salary_or_debt', 'payment_event', 'exact_event',
  'relationship_history', 'other_person_feelings', 'other_person_intent', 'other_person_action',
  'guaranteed_outcome', 'date', 'chronology', 'unsupported_causation',
];
const FORBIDDEN_BY_DEVELOPMENT: Record<CoffeeM1Development, CoffeeForbiddenSpecific[]> = {
  contact: ['sender_identity', 'guaranteed_contact'],
  written_contact: ['sender_identity', 'guaranteed_contact'],
  opportunity: [],
  commitment: ['guaranteed_contact'],
  emotional_movement: [],
  access_opening: ['prior_problem'],
  direction_change: ['travel_or_relocation'],
  gradual_growth: [],
  choice_clarification: ['invented_options'],
  social_presence: ['sender_identity'],
};

const LOVE_SUBJECTS: ReadonlySet<CoffeeM1Subject> = new Set([
  'general', 'love_relationships', 'person_of_interest', 'custom_decision', 'custom_other',
]);
const ABUNDANCE_SUBJECTS: ReadonlySet<CoffeeM1Subject> = new Set([
  'general', 'money_finance', 'career_work', 'custom_decision', 'custom_other',
]);
const RELATIONSHIP_SUBJECTS: ReadonlySet<CoffeeM1Subject> = new Set(['love_relationships', 'person_of_interest']);

/**
 * Closed combination grammar, in precedence order. Each joins two sign
 * threads into one thread without causation or chronology. Any pair not
 * listed stays two co-occurring threads.
 */
const COMBINATIONS: ReadonlyArray<{
  id: CoffeeM1Combination;
  a: readonly CoffeeM1Sign[];
  b: readonly CoffeeM1Sign[];
  conjecture: CoffeeM1Conjecture;
  subjects?: ReadonlySet<CoffeeM1Subject>;
}> = [
  { id: 'opportunity_with_gradual_growth', a: ['opportunity'], b: ['growth'], conjecture: 'growing_kismet' },
  { id: 'commitment_with_emotion', a: ['commitment'], b: ['emotion'], conjecture: 'heartfelt_lasting_bond_possibility', subjects: LOVE_SUBJECTS },
  { id: 'access_through_direction', a: ['access'], b: ['direction'], conjecture: 'opening_through_new_direction' },
  { id: 'choice_with_direction', a: ['choice'], b: ['direction'], conjecture: 'options_shape_direction' },
  { id: 'direction_with_growth', a: ['direction'], b: ['growth'], conjecture: 'developing_change' },
  { id: 'contact_with_opportunity', a: ['incoming_contact'], b: ['opportunity'], conjecture: 'opportunity_with_news' },
  { id: 'written_contact_with_opportunity', a: ['written_contact'], b: ['opportunity'], conjecture: 'opportunity_with_written_news' },
  {
    id: 'contact_in_relationship',
    a: ['incoming_contact', 'written_contact'],
    b: ['commitment', 'emotion'],
    conjecture: 'communication_in_relationship',
    subjects: RELATIONSHIP_SUBJECTS,
  },
];

/**
 * M1.1 — curated combination valence. A combination is its own curated
 * meaning, so its tone is curated too (never "the more careful component
 * wins" for everything). A component's curated cautionary row (intermittent
 * written contact) still overrides. Positive here is a hopeful POSSIBILITY:
 * never a guarantee, an existing relationship, marriage, or another person's
 * feelings or intent.
 */
const COMBINATION_VALENCE: Record<CoffeeM1Combination, CoffeeM1Valence> = {
  // Both components are positive conventions; the opening's yield grows.
  opportunity_with_gradual_growth: 'positive',
  // Durable bond + deepening feeling as one hopeful heart kısmet (subject-gated to general/love/person).
  commitment_with_emotion: 'positive',
  // An opening that comes through a change of direction: an "önünü açan" convention.
  access_through_direction: 'positive',
  // Options shaping a direction carry no good or bad tone of their own.
  choice_with_direction: 'neutral',
  // A change that develops over time, carried by the positive growth convention.
  direction_with_growth: 'positive',
  // A kısmet that comes with news: the opportunity convention sets the tone.
  contact_with_opportunity: 'positive',
  // Same, with written news; intermittent writing still overrides to cautionary.
  written_contact_with_opportunity: 'positive',
  // Communication inside a love theme stays neutral: warmth would imply the other person's feelings.
  contact_in_relationship: 'neutral',
};

/**
 * Relation grammar. LINKING relations between the two signs of a curated
 * combination mark the thread as linked; `separated` keeps the pair as two
 * independent threads; `continuation_of` between two marks of ONE sign adds
 * `continuing`. near / crossing / contained_by carry no fortune meaning.
 */
const LINKING_RELATIONS: ReadonlySet<CoffeeV3RelationKind> = new Set(['connected', 'touching', 'continuation_of']);

/**
 * M1.2 — closed context-binding grammar. A declared fact binds a thread only
 * when the thread carries a compatible development; every other thread stays
 * ordinary (a decision is never forced onto a news thread).
 */
const CONTEXT_BINDINGS: ReadonlyArray<{
  fact: CoffeeUserDeclaredFact;
  binding: CoffeeM1ContextBinding;
  conjecture: Partial<Record<CoffeeM1Development, CoffeeM1Conjecture>>;
  forbidden: CoffeeM1ContextForbidden[];
}> = [
  {
    fact: 'decision_exists',
    binding: 'user_decision',
    conjecture: {
      choice_clarification: 'decision_clarity',
      access_opening: 'decision_clarity',
      direction_change: 'decision_direction',
    },
    forbidden: ['option_identity', 'correct_option'],
  },
  {
    fact: 'awaiting_response',
    binding: 'awaited_topic',
    conjecture: {
      contact: 'communication_on_awaited_topic',
      written_contact: 'written_news_on_awaited_topic',
    },
    forbidden: ['response_certainty', 'positive_response', 'response_content', 'response_timing'],
  },
  {
    fact: 'current_relationship',
    binding: 'current_relationship',
    conjecture: {
      commitment: 'current_relationship_theme',
      emotional_movement: 'current_relationship_theme',
      contact: 'communication_in_current_relationship',
      written_contact: 'communication_in_current_relationship',
    },
    forbidden: ['partner_feelings', 'partner_action', 'relationship_outcome', 'infidelity', 'marriage_fact'],
  },
  {
    // Contract B: the theme may attach to the chosen person; nothing about them may be invented.
    fact: 'person_in_mind',
    binding: 'chosen_person',
    conjecture: {
      contact: 'communication_about_chosen_person',
      written_contact: 'communication_about_chosen_person',
    },
    forbidden: [],
  },
];

/**
 * Closed development × domain compatibility table (unchanged since M1.2). A
 * trusted domain never pulls an incompatible sign into it.
 */
const DOMAIN_TABLE: Record<CoffeeSubjectSection, { domain: CoffeeM1Domain; conjecture: Partial<Record<CoffeeM1Development, CoffeeM1Conjecture>> }> = {
  money: {
    domain: 'financial',
    conjecture: { opportunity: 'financial_opening', gradual_growth: 'financial_growth' },
  },
  career: {
    domain: 'career',
    conjecture: {
      opportunity: 'career_opening',
      access_opening: 'career_opening',
      direction_change: 'career_direction',
      gradual_growth: 'career_growth',
    },
  },
  love: {
    domain: 'love',
    conjecture: {
      commitment: 'love_development',
      emotional_movement: 'love_development',
      contact: 'love_development',
      written_contact: 'love_development',
    },
  },
};

/**
 * M1.3 — trusted domain sections. The ONLY source is the classifier's
 * `authorizedSections` (canonical choices already carry their own section;
 * custom intentions carry the sections the user's words named). M1 never
 * parses text. person_of_interest stays domain-free under Contract B even
 * though its section is love: a chosen person is not assumed to be romantic.
 */
function trustedDomainSections(intention: CoffeeTrustedIntentionContext | null | undefined): CoffeeSubjectSection[] {
  if (!intention || intention.subjectKind === 'person_of_interest') return [];
  return [...new Set(intention.authorizedSections)];
}

/**
 * Domain resolution without fabricated priority: a thread binds a domain only
 * when EXACTLY ONE trusted section is compatible with its developments. Two
 * or more compatible sections (e.g. money + career for an opportunity) leave
 * the thread unbound rather than picking one.
 */
function resolveDomain(
  developments: CoffeeM1Development[],
  sections: CoffeeSubjectSection[],
): { domain: CoffeeM1Domain | null; conjecture: CoffeeM1Conjecture[] } {
  const compatible = sections.filter((section) => developments.some((d) => DOMAIN_TABLE[section].conjecture[d]));
  if (compatible.length !== 1) return { domain: null, conjecture: [] };
  const rule = DOMAIN_TABLE[compatible[0]];
  return {
    domain: rule.domain,
    conjecture: developments.map((d) => rule.conjecture[d]).filter((t): t is CoffeeM1Conjecture => !!t),
  };
}

/** Context and domain layers for one thread, from its developments and the trusted declarations. */
function contextLayer(
  developments: CoffeeM1Development[],
  sections: CoffeeSubjectSection[],
  declared: CoffeeUserDeclaredFact[],
): Pick<CoffeeFortuneThread, 'contextBindings' | 'domain' | 'contextForbidden'> & { conjecture: CoffeeM1Conjecture[] } {
  const contextBindings: CoffeeM1ContextBinding[] = [];
  const contextForbidden: CoffeeM1ContextForbidden[] = [];
  const conjecture: CoffeeM1Conjecture[] = [];
  for (const rule of CONTEXT_BINDINGS) {
    if (!declared.includes(rule.fact)) continue;
    const tokens = developments.map((d) => rule.conjecture[d]).filter((t): t is CoffeeM1Conjecture => !!t);
    if (tokens.length === 0) continue;
    contextBindings.push(rule.binding);
    contextForbidden.push(...rule.forbidden);
    conjecture.push(...tokens);
  }
  const domain = resolveDomain(developments, sections);
  conjecture.push(...domain.conjecture);
  return {
    contextBindings,
    domain: domain.domain,
    contextForbidden: [...new Set(contextForbidden)],
    conjecture,
  };
}

// ---------------------------------------------------------------------------
// Engine
// ---------------------------------------------------------------------------

type SignGroup = {
  sign: CoffeeM1Sign;
  /** Distinct identity groups (a possible-same group counts once). */
  groups: string[];
  marks: CoffeeV3MapMark[];
  extraModifiers: Set<CoffeeM1Modifier>;
  relationKinds: Set<CoffeeV3RelationKind>;
};

const uniq = <T>(values: T[]) => [...new Set(values)];

function horizonOf(marks: CoffeeV3MapMark[]): CoffeeM1Horizon {
  const known = uniq(marks.map((m) => m.band).filter((b): b is Exclude<CoffeeV3Band, 'unknown'> => !!b && b !== 'unknown'));
  if (known.length === 0) return 'unspecified';
  // Disagreeing placements give no special timing: the broad coming period.
  return known.length === 1 ? HORIZON_BY_BAND[known[0]] : 'coming_period';
}

/** One shared horizon when the developments agree; otherwise the broad coming period. */
function aggregateHorizon(horizons: CoffeeM1Horizon[]): CoffeeM1Horizon {
  const distinct = uniq(horizons);
  return distinct.length === 1 ? distinct[0] : 'coming_period';
}

function signModifiers(group: SignGroup): CoffeeM1Modifier[] {
  const modifiers = new Set<CoffeeM1Modifier>(group.extraModifiers);
  for (const rule of COFFEE_M1_FORM_GRAMMAR[group.sign]) {
    if (group.marks.some((mark) => mark.form[rule.field] === rule.value)) modifiers.add(rule.modifier);
  }
  // A form pair that contradicts itself across marks (moving + still) says nothing.
  for (const [x, y] of [
    ['active', 'quiet'],
    ['direct', 'not_yet_open'],
    ['continuing', 'intermittent'],
    ['turning', 'continuing_course'],
  ] as const) {
    if (modifiers.has(x) && modifiers.has(y)) {
      modifiers.delete(x);
      modifiers.delete(y);
    }
  }
  if (group.groups.length > 1) modifiers.add('recurring');
  if (group.marks.some((m) => m.handleRelation === 'handle_near')) modifiers.add('close_circle');
  return [...modifiers].sort();
}

function signValence(sign: CoffeeM1Sign, modifiers: CoffeeM1Modifier[]): CoffeeM1Valence {
  if (CAUTIONARY_MODIFIERS.some(([s, m]) => s === sign && modifiers.includes(m))) return 'cautionary';
  return BASE_VALENCE[sign];
}

function signConjecture(sign: CoffeeM1Sign, modifiers: CoffeeM1Modifier[], subject: CoffeeM1Subject): CoffeeM1Conjecture[] {
  switch (sign) {
    case 'incoming_contact':
      return subject === 'person_of_interest'
        ? ['news', 'communication_movement', 'communication_about_chosen_person']
        : ['news', 'communication_movement'];
    case 'written_contact':
      return subject === 'person_of_interest'
        ? ['written_news', 'communication_movement', 'communication_about_chosen_person']
        : ['written_news', 'communication_movement'];
    case 'opportunity':
      return modifiers.some((m) => OPPORTUNITY_POSITIVE_FORM.includes(m))
        ? ['kismet', 'opportunity', 'beautiful_kismet']
        : ['kismet', 'opportunity'];
    case 'commitment':
      return LOVE_SUBJECTS.has(subject)
        ? ['lasting_bond_possibility', 'serious_heart_kismet_possibility']
        : ['lasting_bond_possibility'];
    case 'emotion':
      return modifiers.includes('leaning') ? ['feelings_deepen', 'heart_inclines'] : ['feelings_deepen'];
    case 'access':
      return ['path_opening', 'way_through'];
    case 'direction':
      return modifiers.includes('turning') ? ['new_direction', 'new_beginning'] : ['new_direction'];
    case 'growth':
      return ABUNDANCE_SUBJECTS.has(subject) ? ['gradual_development', 'abundance'] : ['gradual_development'];
    case 'choice':
      return ['options_clarify'];
    case 'social_presence':
      return ['people_around'];
  }
}

function forbiddenFor(developments: CoffeeM1Development[]): CoffeeForbiddenSpecific[] {
  return uniq([...COMMON_FORBIDDEN, ...developments.flatMap((d) => FORBIDDEN_BY_DEVELOPMENT[d])]);
}

function intentReference(intention: CoffeeTrustedIntentionContext | null | undefined): CoffeeM1IntentReference {
  if (!intention) return { kind: 'none' };
  return coffeeIntentionIsCanonical(intention.intention)
    ? { kind: 'canonical_choice' }
    : { kind: 'user_provided', userDeclaredIntention: intention.intention };
}

/**
 * M1.2: the trusted intention context comes ONLY from classifyCoffeeIntention.
 * M1 never parses text itself: declared facts are taken as typed, never
 * inferred, and the raw text is only carried as a user-provided reference.
 */
export function interpretCoffeeV3MarkMap(
  map: CoffeeV3MarkMap,
  intention?: CoffeeTrustedIntentionContext | null,
): CoffeeM1Result {
  const subject = coffeeM1Subject(intention);
  const declared: CoffeeUserDeclaredFact[] = [...(intention?.declaredFacts ?? [])];
  const domainSections = trustedDomainSections(intention);

  // 1) Classify each physical identity group by its usable candidates. Saucer
  //    marks carry no approved convention yet and never make a thread.
  const signByMark = new Map<string, CoffeeM1LabelSign>(map.cupMarks.map((m) => [m.id, coffeeM1MarkSign(m)]));
  const groupSigns = new Map<string, Set<CoffeeM1LabelSign>>();
  for (const mark of map.cupMarks) {
    const set = groupSigns.get(mark.identityGroup) ?? new Set();
    set.add(signByMark.get(mark.id) ?? null);
    groupSigns.set(mark.identityGroup, set);
  }
  let ambiguousGroups = 0;
  let unmappedGroups = 0;
  const groupSign = new Map<string, CoffeeM1Sign>();
  for (const [group, signs] of groupSigns) {
    const known = [...signs].filter((s): s is CoffeeM1Sign => s !== null && s !== 'ambiguous');
    if (signs.has('ambiguous') || new Set(known).size > 1) ambiguousGroups += 1;
    else if (known.length === 0) unmappedGroups += 1;
    else groupSign.set(group, known[0]);
  }

  // 2) One sign group per sign; repetition = distinct identity groups only.
  const signGroups = new Map<CoffeeM1Sign, SignGroup>();
  for (const mark of map.cupMarks) {
    const sign = groupSign.get(mark.identityGroup);
    if (!sign) continue;
    const entry = signGroups.get(sign) ?? { sign, groups: [], marks: [], extraModifiers: new Set(), relationKinds: new Set() };
    if (!entry.groups.includes(mark.identityGroup)) entry.groups.push(mark.identityGroup);
    entry.marks.push(mark);
    signGroups.set(sign, entry);
  }

  // 3) Relations through the closed relation grammar only.
  const markSign = (id: string) => {
    const mark = map.cupMarks.find((m) => m.id === id);
    return mark ? groupSign.get(mark.identityGroup) : undefined;
  };
  const linkedPairs = new Set<string>();
  const separatedPairs = new Set<string>();
  const ignoredRelationKinds = new Set<CoffeeV3RelationKind>();
  const pairKey = (x: CoffeeM1Sign, y: CoffeeM1Sign) => [x, y].sort().join('|');
  for (const relation of map.relations) {
    const [a, b] = [markSign(relation.a), markSign(relation.b)];
    if (!a || !b) {
      ignoredRelationKinds.add(relation.kind);
      continue;
    }
    if (a === b) {
      if (relation.kind === 'continuation_of') {
        signGroups.get(a)!.extraModifiers.add('continuing');
        signGroups.get(a)!.relationKinds.add(relation.kind);
      } else ignoredRelationKinds.add(relation.kind);
      continue;
    }
    const curated = COMBINATIONS.some((c) => (c.a.includes(a) && c.b.includes(b)) || (c.a.includes(b) && c.b.includes(a)));
    if (curated && LINKING_RELATIONS.has(relation.kind)) {
      linkedPairs.add(pairKey(a, b));
      signGroups.get(a)!.relationKinds.add(relation.kind);
      signGroups.get(b)!.relationKinds.add(relation.kind);
    } else if (relation.kind === 'separated') {
      separatedPairs.add(pairKey(a, b));
    } else {
      ignoredRelationKinds.add(relation.kind);
    }
  }

  // 4) Single-sign threads, then the closed combination grammar.
  const ordered = [...signGroups.values()].sort(
    (x, y) => SIGN_LEXICON.findIndex(([s]) => s === x.sign) - SIGN_LEXICON.findIndex(([s]) => s === y.sign),
  );
  const consumed = new Set<CoffeeM1Sign>();
  const threads: CoffeeFortuneThread[] = [];
  const threadEvidence: CoffeeM1Audit['threadEvidence'] = {};
  const binding = (signs: CoffeeM1Sign[]) =>
    subject === 'person_of_interest' && signs.some((s) => s === 'incoming_contact' || s === 'written_contact')
      ? ('person_of_interest' as const)
      : null;
  const push = (
    thread: Omit<CoffeeFortuneThread, 'id' | 'contextBindings' | 'domain' | 'contextForbidden'>,
    groups: SignGroup[],
  ) => {
    const id = `T${threads.length + 1}`;
    const layer = contextLayer(thread.developments, domainSections, declared);
    threads.push({
      id,
      ...thread,
      contextBindings: layer.contextBindings,
      domain: layer.domain,
      contextForbidden: layer.contextForbidden,
      conjecture: uniq([...thread.conjecture, ...layer.conjecture]),
    });
    threadEvidence[id] = {
      identityGroups: uniq(groups.flatMap((g) => g.groups)).sort(),
      relationKinds: uniq(groups.flatMap((g) => [...g.relationKinds])).sort(),
    };
  };

  for (const combo of COMBINATIONS) {
    if (combo.subjects && !combo.subjects.has(subject)) continue;
    const first = ordered.find((g) => combo.a.includes(g.sign) && !consumed.has(g.sign));
    const second = ordered.find((g) => combo.b.includes(g.sign) && !consumed.has(g.sign));
    if (!first || !second || first.sign === second.sign) continue;
    if (separatedPairs.has(pairKey(first.sign, second.sign))) continue;
    consumed.add(first.sign);
    consumed.add(second.sign);
    const pair = [first, second];
    const modifiers = uniq(pair.flatMap(signModifiers)).sort();
    const componentValences = pair.map((g) => signValence(g.sign, signModifiers(g)));
    const developmentHorizons = pair.map((g) => ({ development: DEVELOPMENT_BY_SIGN[g.sign], horizon: horizonOf(g.marks) }));
    push(
      {
        developments: pair.map((g) => DEVELOPMENT_BY_SIGN[g.sign]),
        combination: combo.id,
        linkage: linkedPairs.has(pairKey(first.sign, second.sign)) ? 'linked' : 'co_present',
        subject,
        subjectBinding: binding(pair.map((g) => g.sign)),
        horizon: aggregateHorizon(developmentHorizons.map((d) => d.horizon)),
        developmentHorizons,
        // Curated combination tone; a component's curated cautionary row still overrides.
        valence: componentValences.includes('cautionary') ? 'cautionary' : COMBINATION_VALENCE[combo.id],
        modifiers,
        conjecture: uniq([
          ...pair.flatMap((g) => signConjecture(g.sign, signModifiers(g), subject)),
          combo.conjecture,
        ]),
        forbiddenSpecifics: forbiddenFor(pair.map((g) => DEVELOPMENT_BY_SIGN[g.sign])),
      },
      pair,
    );
  }
  for (const group of ordered) {
    if (consumed.has(group.sign)) continue;
    const modifiers = signModifiers(group);
    push(
      {
        developments: [DEVELOPMENT_BY_SIGN[group.sign]],
        combination: null,
        linkage: 'single',
        subject,
        subjectBinding: binding([group.sign]),
        horizon: horizonOf(group.marks),
        developmentHorizons: [{ development: DEVELOPMENT_BY_SIGN[group.sign], horizon: horizonOf(group.marks) }],
        valence: signValence(group.sign, modifiers),
        modifiers,
        conjecture: signConjecture(group.sign, modifiers, subject),
        forbiddenSpecifics: forbiddenFor([DEVELOPMENT_BY_SIGN[group.sign]]),
      },
      [group],
    );
  }

  return {
    meaning: {
      subject,
      declaredContext: declared,
      intentReference: intentReference(intention),
      capacity: coffeeM1Capacity(threads, new Set([...signGroups.values()].flatMap((g) => g.groups)).size),
      threads,
    },
    audit: {
      threadEvidence,
      ambiguousGroups,
      unmappedGroups,
      ignoredRelationKinds: [...ignoredRelationKinds].sort(),
      saucerContext:
        map.saucer.surfaceState === 'islands' || map.saucer.surfaceState === 'flow' ? map.saucer.surfaceState : 'none',
    },
  };
}

/**
 * Capacity (exact rule):
 * - insufficient: no sign thread.
 * - single_thread: exactly one distinct development, however many views,
 *   repeats or modifiers it has.
 * - multi_thread: two distinct developments, or three+ without the rich bar.
 * - rich: three+ distinct developments from three+ distinct identity groups
 *   AND at least one thread with a placement horizon (nearer_term /
 *   further_out), a close-circle position, a sign-specific form modifier,
 *   or a curated combination. Repetition alone never counts.
 */
export function coffeeM1Capacity(threads: CoffeeFortuneThread[], distinctIdentityGroups: number): CoffeeM1Capacity {
  const developments = new Set(threads.flatMap((t) => t.developments));
  if (developments.size === 0) return 'insufficient';
  if (developments.size === 1) return 'single_thread';
  const useful = threads.some(
    (t) =>
      t.combination !== null ||
      t.developmentHorizons.some((d) => d.horizon === 'nearer_term' || d.horizon === 'further_out') ||
      t.modifiers.some((m) => m !== 'recurring'),
  );
  return developments.size >= 3 && distinctIdentityGroups >= 3 && useful ? 'rich' : 'multi_thread';
}
