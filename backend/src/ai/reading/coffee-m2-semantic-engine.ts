import type { CoffeeForbiddenSpecific } from './coffee-fortune-beat.js';
import type {
  CoffeeSubjectSection,
  CoffeeTrustedIntentionContext,
  CoffeeUserDeclaredFact,
} from './coffee-intention-context.js';
import {
  coffeeM1MarkSign,
  interpretCoffeeV3MarkMap,
  type CoffeeFortuneThread,
  type CoffeeM1Capacity,
  type CoffeeM1ContextBinding,
  type CoffeeM1ContextForbidden,
  type CoffeeM1Domain,
  type CoffeeM1Horizon,
  type CoffeeM1IntentReference,
  type CoffeeM1Subject,
  type CoffeeM1Valence,
} from './coffee-m1-interpretation.js';
import type { CoffeeV3MapMark, CoffeeV3MarkMap } from './coffee-v3-mark-map.js';
import type { CoffeeV3Band, CoffeeV3RelationKind } from './types.js';

/**
 * M2 — DARK SEMANTIC ENGINE. ADDITIVE AND DARK: no live path, writer, worker
 * or route imports this. Combines the M1 object-sign lane (unchanged) with
 *   - M1.4 structure-first lane (conservative, physics-aware),
 *   - M1.5 grounded thread facets / depth,
 *   - M1.6 controlled scenario PERMISSIONS (tokens, never prose).
 * The saucer lane is NOT implemented (frozen NO-GO): saucer marks are ignored.
 *
 * Input is ONLY the normalized CoffeeV3MarkMap plus the trusted intention
 * context from classifyCoffeeIntention. No observer prose, confidence,
 * visibility or photo coordinate is read.
 */

// ---------------------------------------------------------------------------
// Contract gaps (reported, never faked)
// ---------------------------------------------------------------------------

/**
 * V3 marks are RESIDUE marks with a single merged band. The current contract
 * therefore cannot deterministically represent:
 * - a clear / empty area (open or enclosed): opening_clarity and room_within
 *   have no source, so they are never derived from the mark map;
 * - a closed loop on the cup wall as distinct from a pool or blob:
 *   within_one_phase has no source;
 * - a line's cross-band span: span is only inferred from a vertical
 *   orientation of a middle-band line (see `structureMeaning`).
 */
export const COFFEE_M2_CONTRACT_GAPS = [
  'clear_area_not_representable',
  'wall_loop_not_distinguishable_from_pool_or_blob',
  'line_span_not_encoded',
] as const;

// ---------------------------------------------------------------------------
// Structure-first lane
// ---------------------------------------------------------------------------

export type CoffeeM2StructuralMeaning =
  | 'steady_course'
  | 'course_turn'
  | 'stop_start_course'
  | 'possibilities_branch'
  | 'opening_clarity';

export type CoffeeM2StructuralModifier = 'room_within' | 'within_one_phase' | 'many_small_details' | 'continuing' | 'stop_start';

type StructureFamily = 'course' | 'possibilities' | 'opening';

const FAMILY: Record<CoffeeM2StructuralMeaning, StructureFamily> = {
  steady_course: 'course',
  course_turn: 'course',
  stop_start_course: 'course',
  possibilities_branch: 'possibilities',
  opening_clarity: 'opening',
};

/**
 * Tier-1 structural meaning of ONE physical mark that no strong object sign
 * owns, or null (tier 3 context: pools, blobs, partial bands, rim stains).
 *
 * - branching course → possibilities_branch (a broken branching web keeps one
 *   meaning and gains the `stop_start` quality, never a second thread);
 * - continuous / broken line → a course meaning ONLY when it is not confined
 *   to the rim band (V3 cannot tell a rim stain from a rim-origin trail) AND
 *   either its course is known, or it is a middle-band line with a vertical
 *   orientation (the only available evidence that it spans bands).
 * The VALUE of a trail's vertical direction never changes the meaning:
 * rising and descending are treated identically (gravity makes drips).
 */
export function coffeeM2StructureMeaning(
  mark: Pick<CoffeeV3MapMark, 'band' | 'form'>,
): { meaning: CoffeeM2StructuralMeaning; modifiers: CoffeeM2StructuralModifier[] } | null {
  const { form, band } = mark;
  if (form.course === 'branching') {
    return { meaning: 'possibilities_branch', modifiers: form.continuity === 'broken' ? ['stop_start'] : [] };
  }
  if (form.continuity !== 'continuous' && form.continuity !== 'broken') return null;
  if (band === 'rim_upper') return null;
  const courseKnown = form.course === 'straight' || form.course === 'bending';
  const verticalSpan =
    band === 'middle' && (form.verticalDirection === 'rising' || form.verticalDirection === 'descending');
  if (!courseKnown && !verticalSpan) return null;
  if (form.continuity === 'broken') return { meaning: 'stop_start_course', modifiers: [] };
  return { meaning: form.course === 'bending' ? 'course_turn' : 'steady_course', modifiers: [] };
}

const STRUCTURE_VALENCE: Record<CoffeeM2StructuralMeaning, CoffeeM1Valence> = {
  steady_course: 'positive',
  course_turn: 'neutral',
  stop_start_course: 'cautionary',
  possibilities_branch: 'neutral',
  opening_clarity: 'positive',
};

export type CoffeeM2StructuralCombination =
  | 'stalled_course_finds_room'
  | 'opening_moves_forward'
  | 'possibilities_become_visible'
  | 'course_opens_into_alternatives';

/** Closed structural combination table, in precedence order. No causation. */
const STRUCTURAL_COMBINATIONS: ReadonlyArray<{
  id: CoffeeM2StructuralCombination;
  a: CoffeeM2StructuralMeaning[];
  b: CoffeeM2StructuralMeaning[];
  valence: CoffeeM1Valence;
  /** The combination is defined ON the cautionary component, so its curated tone already accounts for it. */
  absorbsCaution?: boolean;
}> = [
  { id: 'stalled_course_finds_room', a: ['stop_start_course'], b: ['opening_clarity'], valence: 'neutral', absorbsCaution: true },
  { id: 'opening_moves_forward', a: ['opening_clarity'], b: ['steady_course', 'course_turn'], valence: 'positive' },
  { id: 'possibilities_become_visible', a: ['opening_clarity'], b: ['possibilities_branch'], valence: 'neutral' },
  {
    id: 'course_opens_into_alternatives',
    a: ['steady_course', 'course_turn', 'stop_start_course'],
    b: ['possibilities_branch'],
    valence: 'neutral',
  },
];

/** One structural development per family (several lines are one course; several webs one possibilities). */
export type CoffeeM2StructuralUnit = {
  meaning: CoffeeM2StructuralMeaning;
  groups: string[];
  bands: Array<CoffeeV3Band | null>;
  modifiers: CoffeeM2StructuralModifier[];
  closeCircle: boolean;
};

/**
 * Closed structural combination resolver (exported for direct testing; the
 * opening entries are unreachable from the current V3 contract).
 */
export function coffeeM2CombineStructural(
  units: CoffeeM2StructuralUnit[],
  separatedFamilies: ReadonlySet<string> = new Set(),
): Array<{ units: CoffeeM2StructuralUnit[]; combination: CoffeeM2StructuralCombination | null; valence: CoffeeM1Valence }> {
  const remaining = [...units];
  const out: Array<{ units: CoffeeM2StructuralUnit[]; combination: CoffeeM2StructuralCombination | null; valence: CoffeeM1Valence }> = [];
  for (const combo of STRUCTURAL_COMBINATIONS) {
    const first = remaining.find((u) => combo.a.includes(u.meaning));
    const second = remaining.find((u) => u !== first && combo.b.includes(u.meaning));
    if (!first || !second) continue;
    if (separatedFamilies.has([FAMILY[first.meaning], FAMILY[second.meaning]].sort().join('|'))) continue;
    remaining.splice(remaining.indexOf(first), 1);
    remaining.splice(remaining.indexOf(second), 1);
    // A cautionary component overrides the curated tone unless the combination absorbs it.
    const cautious = !combo.absorbsCaution && [first, second].some((u) => STRUCTURE_VALENCE[u.meaning] === 'cautionary');
    out.push({ units: [first, second], combination: combo.id, valence: cautious ? 'cautionary' : combo.valence });
  }
  for (const unit of remaining) out.push({ units: [unit], combination: null, valence: STRUCTURE_VALENCE[unit.meaning] });
  return out;
}

// ---------------------------------------------------------------------------
// Domain / context binding for structural meanings
// ---------------------------------------------------------------------------

const STRUCTURE_DOMAIN: Record<CoffeeSubjectSection, Partial<Record<CoffeeM2StructuralMeaning, string>>> = {
  career: { steady_course: 'career_progression', course_turn: 'career_direction' },
  money: { opening_clarity: 'financial_opening', possibilities_branch: 'financial_possibilities' },
  love: { opening_clarity: 'love_clarity' },
};
const DOMAIN_NAME: Record<CoffeeSubjectSection, CoffeeM1Domain> = { career: 'career', money: 'financial', love: 'love' };
const STRUCTURE_DECISION: Partial<Record<CoffeeM2StructuralMeaning, string>> = {
  possibilities_branch: 'decision_options',
  course_turn: 'decision_direction',
};

/** Same trusted source as M1.3: the classifier's authorizedSections; person_of_interest stays domain-free. */
function trustedSections(intention: CoffeeTrustedIntentionContext | null | undefined): CoffeeSubjectSection[] {
  if (!intention || intention.subjectKind === 'person_of_interest') return [];
  return [...new Set(intention.authorizedSections)];
}

// ---------------------------------------------------------------------------
// Unified thread model, facets, depth
// ---------------------------------------------------------------------------

export type CoffeeM2Lane = 'object' | 'structure';
export type CoffeeM2Depth = 'thin' | 'developed' | 'deep';
export type CoffeeM2FacetCategory =
  | 'core_development'
  | 'trajectory'
  | 'horizon'
  | 'domain'
  | 'user_context'
  | 'persistence'
  | 'scope'
  | 'relational'
  | 'consequence';

/** A facet is one independent unit of meaning: its `cls` is the dedup key. */
export type CoffeeM2Facet = { category: CoffeeM2FacetCategory; cls: string };

export type CoffeeM2ScenarioContext =
  | 'career'
  | 'money'
  | 'love'
  | 'love_current_relationship'
  | 'decision'
  | 'awaited_topic'
  | 'chosen_person'
  | 'general';

/** Controlled scenario permission (S2 target, never S3). Tokens, not prose. */
export type CoffeeM2ScenarioPermission = {
  context: CoffeeM2ScenarioContext;
  specificity: 'S1' | 'S2';
  /** One cluster, 1–3 related manifestations. */
  manifestations: string[];
  forbidden: string[];
};

export type CoffeeM2Thread = {
  id: string;
  lane: CoffeeM2Lane;
  developments: string[];
  combination: string | null;
  horizon: CoffeeM1Horizon;
  developmentHorizons: Array<{ development: string; horizon: CoffeeM1Horizon }>;
  valence: CoffeeM1Valence;
  modifiers: string[];
  contextBindings: CoffeeM1ContextBinding[];
  domain: CoffeeM1Domain | null;
  conjecture: string[];
  forbiddenSpecifics: CoffeeForbiddenSpecific[];
  contextForbidden: CoffeeM1ContextForbidden[];
  facets: CoffeeM2Facet[];
  depth: CoffeeM2Depth;
  scenario: CoffeeM2ScenarioPermission | null;
};

export type CoffeeM2Diagnostics = {
  capacity: CoffeeM1Capacity;
  groundedDevelopmentCount: number;
  distinctFacetCount: number;
  maxDepth: CoffeeM2Depth | null;
  scenarioAvailable: boolean;
};

export type CoffeeM2Meaning = {
  subject: CoffeeM1Subject;
  declaredContext: CoffeeUserDeclaredFact[];
  intentReference: CoffeeM1IntentReference;
  threads: CoffeeM2Thread[];
  diagnostics: CoffeeM2Diagnostics;
};

export type CoffeeM2Audit = {
  objectOwnedGroups: string[];
  structureOwnedGroups: string[];
  contextGroups: string[];
  threadEvidence: Record<string, string[]>;
  contractGaps: readonly string[];
};

export type CoffeeM2Result = { meaning: CoffeeM2Meaning; audit: CoffeeM2Audit };

/** Core-development equivalence classes. */
const CORE_CLASS: Record<string, string> = {
  steady_course: 'FORWARD',
  course_turn: 'CHANGE',
  stop_start_course: 'UNEVEN',
  possibilities_branch: 'MULTIPLICITY',
  opening_clarity: 'OPENING',
  contact: 'COMMUNICATION',
  written_contact: 'WRITTEN_COMMUNICATION',
  opportunity: 'OPPORTUNITY',
  commitment: 'COMMITMENT',
  emotional_movement: 'FEELING',
  access_opening: 'OPENING',
  direction_change: 'CHANGE',
  gradual_growth: 'GROWTH',
  choice_clarification: 'MULTIPLICITY',
  social_presence: 'PEOPLE',
};

/** Modifier → (category, class). Unlisted modifiers carry no depth. */
const MODIFIER_FACET: Record<string, CoffeeM2Facet> = {
  active: { category: 'trajectory', cls: 'MOMENTUM' },
  gaining_momentum: { category: 'trajectory', cls: 'MOMENTUM' },
  quiet: { category: 'trajectory', cls: 'QUIET' },
  not_yet_open: { category: 'trajectory', cls: 'QUIET' },
  direct: { category: 'trajectory', cls: 'DIRECT' },
  reaching: { category: 'trajectory', cls: 'REACHING' },
  turning: { category: 'trajectory', cls: 'CHANGE' },
  continuing_course: { category: 'trajectory', cls: 'FORWARD' },
  upward_progression: { category: 'trajectory', cls: 'FORWARD' },
  steady: { category: 'trajectory', cls: 'FORWARD' },
  intermittent: { category: 'trajectory', cls: 'UNEVEN' },
  stop_start: { category: 'trajectory', cls: 'UNEVEN' },
  leaning: { category: 'trajectory', cls: 'LEANING' },
  usable_opening: { category: 'trajectory', cls: 'OPENING' },
  visible_opening: { category: 'trajectory', cls: 'OPENING' },
  continuing: { category: 'persistence', cls: 'FORWARD' },
  long_running: { category: 'persistence', cls: 'FORWARD' },
  recurring: { category: 'persistence', cls: 'RECURRENCE' },
  multi_stream: { category: 'scope', cls: 'MULTI_STREAM' },
  close_circle: { category: 'scope', cls: 'CLOSE_CIRCLE' },
  singular_focus: { category: 'scope', cls: 'SINGULAR' },
  whole_durable: { category: 'scope', cls: 'DURABLE' },
  gathering: { category: 'scope', cls: 'GATHERING' },
  many_small_details: { category: 'scope', cls: 'SMALL_DETAILS' },
  room_within: { category: 'scope', cls: 'OPENING' },
  within_one_phase: { category: 'scope', cls: 'PHASE' },
};

/** Conventional consequences that may add a facet (deduped against everything else). */
const CONSEQUENCE_FACET: Record<string, string> = {
  abundance: 'GROWTH',
  new_beginning: 'CHANGE',
  heart_inclines: 'LEANING',
};

function threadFacets(thread: Omit<CoffeeM2Thread, 'id' | 'facets' | 'depth' | 'scenario'>): CoffeeM2Facet[] {
  const raw: CoffeeM2Facet[] = [
    ...thread.developments.map((d): CoffeeM2Facet => ({ category: 'core_development', cls: CORE_CLASS[d] ?? d })),
    ...thread.modifiers.filter((m) => MODIFIER_FACET[m]?.category === 'trajectory').map((m) => MODIFIER_FACET[m]),
  ];
  const horizons = new Set(thread.developmentHorizons.map((d) => d.horizon));
  if ([...horizons].some((h) => h === 'nearer_term' || h === 'further_out') || horizons.size > 1) {
    raw.push({ category: 'horizon', cls: 'HORIZON' });
  }
  if (thread.domain) raw.push({ category: 'domain', cls: `DOMAIN_${thread.domain}` });
  for (const binding of thread.contextBindings) raw.push({ category: 'user_context', cls: `CONTEXT_${binding}` });
  raw.push(...thread.modifiers.filter((m) => MODIFIER_FACET[m]?.category === 'persistence').map((m) => MODIFIER_FACET[m]));
  raw.push(...thread.modifiers.filter((m) => MODIFIER_FACET[m]?.category === 'scope').map((m) => MODIFIER_FACET[m]));
  if (thread.combination) raw.push({ category: 'relational', cls: `RELATION_${thread.combination}` });
  for (const token of thread.conjecture) {
    if (CONSEQUENCE_FACET[token]) raw.push({ category: 'consequence', cls: CONSEQUENCE_FACET[token] });
  }
  // Dedup by equivalence class: the first occurrence keeps its category.
  const seen = new Set<string>();
  return raw.filter((facet) => (seen.has(facet.cls) ? false : (seen.add(facet.cls), true)));
}

/**
 * thin: <= 2 independent facets; developed: 3, or >= 4 without the deep
 * conditions; deep: >= 4 facets from >= 3 categories AND at least one
 * trusted domain, user-context binding or curated combination facet.
 * Valence is never a facet; scenarios never change depth.
 */
export function coffeeM2Depth(facets: CoffeeM2Facet[]): CoffeeM2Depth {
  if (facets.length <= 2) return 'thin';
  const categories = new Set(facets.map((f) => f.category));
  const anchored = facets.some((f) => f.category === 'domain' || f.category === 'user_context' || f.category === 'relational');
  return facets.length >= 4 && categories.size >= 3 && anchored ? 'deep' : 'developed';
}

// ---------------------------------------------------------------------------
// Controlled scenario permissions (closed palette)
// ---------------------------------------------------------------------------

const FORBIDDEN_BY_CONTEXT: Record<CoffeeM2ScenarioContext, string[]> = {
  career: ['job_offer_guaranteed', 'promotion_guaranteed', 'employer_action', 'salary', 'firing', 'company_identity'],
  money: ['payment', 'bonus', 'amount', 'lottery', 'inheritance', 'debt_cleared', 'salary_raise'],
  love: ['partner_exists_assumed', 'partner_feelings', 'partner_actions', 'guaranteed_outcome', 'marriage_fact', 'infidelity'],
  love_current_relationship: ['partner_feelings', 'partner_actions', 'guaranteed_outcome', 'marriage_fact', 'infidelity', 'shared_plan'],
  decision: ['option_identity', 'correct_option'],
  awaited_topic: ['reply_arrives', 'positive_reply', 'sender', 'timing', 'content'],
  chosen_person: ['they_message', 'they_call', 'they_return', 'they_miss_user', 'they_love_user', 'reconciliation', 'invented_history'],
  general: ['invented_career_theme', 'invented_money_theme', 'invented_love_theme', 'invented_person', 'invented_relationship'],
};

const PALETTE: Record<CoffeeM2ScenarioContext, Partial<Record<string, string[]>>> = {
  career: {
    access_opening: ['new_responsibility', 'different_role', 'different_way_of_working'],
    opportunity: ['new_responsibility', 'different_role', 'different_way_of_working'],
    course_turn: ['professional_direction_change', 'other_professional_route'],
    direction_change: ['professional_direction_change', 'other_professional_route'],
    possibilities_branch: ['multiple_professional_options'],
    choice_clarification: ['multiple_professional_options'],
    steady_course: ['steady_professional_progress'],
  },
  money: {
    opportunity: ['new_financial_opportunity', 'another_earning_channel', 'financial_side_strengthened'],
    access_opening: ['new_financial_opportunity', 'financial_side_strengthened'],
    opening_clarity: ['new_financial_opportunity', 'financial_side_strengthened'],
    gradual_growth: ['gradual_financial_improvement', 'multiple_supporting_channels'],
    possibilities_branch: ['additional_financial_possibility', 'option_affecting_money_setup'],
  },
  love: {
    commitment: ['new_connection_becoming_serious_or_existing_bond_clearer'],
    emotional_movement: ['new_connection_becoming_serious_or_existing_bond_clearer'],
  },
  love_current_relationship: {
    commitment: ['declared_relationship_more_serious', 'bond_more_visible'],
    emotional_movement: ['declared_relationship_more_serious', 'bond_more_visible'],
  },
  decision: {
    possibilities_branch: ['secondary_option_gaining_weight', 'another_option_relevant', 'options_separating'],
    choice_clarification: ['secondary_option_gaining_weight', 'another_option_relevant', 'options_separating'],
    course_turn: ['direction_change_worth_considering'],
    direction_change: ['direction_change_worth_considering'],
    access_opening: ['options_separating'],
  },
  awaited_topic: {
    contact: ['communication_around_awaited_matter'],
    written_contact: ['communication_around_awaited_matter', 'written_information_relevant'],
  },
  chosen_person: {
    contact: ['communication_around_chosen_person', 'conversation_about_person_relevant'],
    written_contact: ['communication_around_chosen_person', 'conversation_about_person_relevant'],
  },
  general: {
    course_turn: ['another_direction'],
    direction_change: ['another_direction'],
    possibilities_branch: ['another_option_visible', 'single_track_gaining_alternatives'],
    choice_clarification: ['another_option_visible', 'single_track_gaining_alternatives'],
    opening_clarity: ['matter_opening'],
    access_opening: ['matter_opening'],
    opportunity: ['matter_opening'],
  },
};

const DOMAIN_SCENARIO_CONTEXT: Record<CoffeeM1Domain, CoffeeM2ScenarioContext> = {
  career: 'career',
  financial: 'money',
  love: 'love',
};

/**
 * One cluster per thread. Context precedence: chosen person → awaited topic
 * → declared decision → declared current relationship → trusted domain →
 * general. Within a context, the first thread development with a palette row
 * wins. Never changes thread count, evidence, capacity, depth, horizon or
 * domain.
 */
export function coffeeM2Scenario(
  thread: Pick<CoffeeM2Thread, 'developments' | 'contextBindings' | 'domain'>,
): CoffeeM2ScenarioPermission | null {
  const contexts: CoffeeM2ScenarioContext[] = [];
  if (thread.contextBindings.includes('chosen_person')) contexts.push('chosen_person');
  if (thread.contextBindings.includes('awaited_topic')) contexts.push('awaited_topic');
  if (thread.contextBindings.includes('user_decision')) contexts.push('decision');
  if (thread.contextBindings.includes('current_relationship')) contexts.push('love_current_relationship');
  if (thread.domain) contexts.push(DOMAIN_SCENARIO_CONTEXT[thread.domain]);
  // A chosen-person or awaited-topic thread never falls back to a broader palette.
  const strict = thread.contextBindings.includes('chosen_person') || thread.contextBindings.includes('awaited_topic');
  if (!strict) contexts.push('general');
  for (const context of contexts) {
    for (const development of thread.developments) {
      const row = PALETTE[context][development];
      if (row) {
        return {
          context,
          specificity: context === 'general' ? 'S1' : 'S2',
          manifestations: row.slice(0, 3),
          forbidden: FORBIDDEN_BY_CONTEXT[context],
        };
      }
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// Engine
// ---------------------------------------------------------------------------

const HORIZON_BY_BAND: Record<CoffeeV3Band, CoffeeM1Horizon> = {
  rim_upper: 'nearer_term',
  middle: 'coming_period',
  lower_base: 'further_out',
  unknown: 'unspecified',
};
function horizonOf(bands: Array<CoffeeV3Band | null>): CoffeeM1Horizon {
  const known = [...new Set(bands.filter((b): b is Exclude<CoffeeV3Band, 'unknown'> => !!b && b !== 'unknown'))];
  if (known.length === 0) return 'unspecified';
  return known.length === 1 ? HORIZON_BY_BAND[known[0]] : 'coming_period';
}

const COMMON_FORBIDDEN: CoffeeForbiddenSpecific[] = [
  'exact_person', 'employer_or_company', 'monetary_amount', 'salary_or_debt', 'payment_event', 'exact_event',
  'relationship_history', 'other_person_feelings', 'other_person_intent', 'other_person_action',
  'guaranteed_outcome', 'date', 'chronology', 'unsupported_causation',
];
const STRUCTURE_FORBIDDEN: Record<StructureFamily, CoffeeForbiddenSpecific[]> = {
  course: ['travel_or_relocation'],
  possibilities: ['invented_options'],
  opening: ['prior_problem'],
};

const LINKING: ReadonlySet<CoffeeV3RelationKind> = new Set(['connected', 'continuation_of']);
const NEIGHBOUR: ReadonlySet<CoffeeV3RelationKind> = new Set(['near', 'touching', 'connected', 'continuation_of']);
const OBJECT_CONTINUITY_SIGNS = new Set(['incoming_contact', 'written_contact']);

/** Resolve several course units into ONE course family meaning (no duplicate course threads). */
function resolveCourse(meanings: CoffeeM2StructuralMeaning[]): CoffeeM2StructuralMeaning {
  if (meanings.includes('stop_start_course')) return 'stop_start_course';
  if (meanings.includes('course_turn')) return 'course_turn';
  return 'steady_course';
}

export function interpretCoffeeM2(
  map: CoffeeV3MarkMap,
  intention?: CoffeeTrustedIntentionContext | null,
): CoffeeM2Result {
  // 1) Object lane: M1, unchanged.
  const m1 = interpretCoffeeV3MarkMap(map, intention);
  const declared = m1.meaning.declaredContext;
  const sections = trustedSections(intention);

  // 2) Ownership: a group with a strong recognized object sign belongs to the
  //    object lane. Ambiguous or unmapped groups may use the structure lane.
  const marks = map.cupMarks; // saucer marks are ignored (saucer lane NO-GO)
  const groupMarks = new Map<string, CoffeeV3MapMark[]>();
  for (const mark of marks) groupMarks.set(mark.identityGroup, [...(groupMarks.get(mark.identityGroup) ?? []), mark]);
  const objectOwned = new Set<string>();
  for (const [group, members] of groupMarks) {
    const signs = new Set(members.map((m) => coffeeM1MarkSign(m)));
    if (signs.size === 1) {
      const sign = [...signs][0];
      if (sign !== null && sign !== 'ambiguous') objectOwned.add(group);
    }
  }

  // 3) Structure lane: one meaning per identity group (a possible-same group is one source).
  const groupMeaning = new Map<string, { meaning: CoffeeM2StructuralMeaning; modifiers: CoffeeM2StructuralModifier[] }>();
  for (const [group, members] of groupMarks) {
    if (objectOwned.has(group)) continue;
    const meaning = coffeeM2StructureMeaning(members[0]);
    if (meaning) groupMeaning.set(group, meaning);
  }
  const markById = new Map(marks.map((m) => [m.id, m]));
  const groupOf = (id: string) => markById.get(id)?.identityGroup;

  // Relation-derived modifiers (closed, only between already meaningful sources).
  const extra = new Map<string, Set<CoffeeM2StructuralModifier>>();
  const addExtra = (group: string, modifier: CoffeeM2StructuralModifier) =>
    extra.set(group, new Set([...(extra.get(group) ?? []), modifier]));
  const separatedFamilies = new Set<string>();
  for (const relation of map.relations) {
    const [ga, gb] = [groupOf(relation.a), groupOf(relation.b)];
    if (!ga || !gb || ga === gb) continue;
    const [ma, mb] = [groupMeaning.get(ga), groupMeaning.get(gb)];
    if (ma && mb && LINKING.has(relation.kind)) {
      addExtra(ga, 'continuing');
      addExtra(gb, 'continuing');
    }
    if (ma && mb && relation.kind === 'separated') {
      separatedFamilies.add([FAMILY[ma.meaning], FAMILY[mb.meaning]].sort().join('|'));
    }
    // A speckle cluster enriches a neighbouring meaningful structure; on its own it is context.
    for (const [host, other] of [[ga, gb], [gb, ga]] as const) {
      const otherMarks = groupMarks.get(other) ?? [];
      if (groupMeaning.has(host) && !groupMeaning.has(other) && !objectOwned.has(other)
        && NEIGHBOUR.has(relation.kind) && otherMarks.some((m) => m.form.grouping === 'clustered')) {
        addExtra(host, 'many_small_details');
      }
    }
  }

  // One unit per structural family.
  const byFamily = new Map<StructureFamily, string[]>();
  for (const [group, meaning] of groupMeaning) {
    const family = FAMILY[meaning.meaning];
    byFamily.set(family, [...(byFamily.get(family) ?? []), group]);
  }
  const units: CoffeeM2StructuralUnit[] = [...byFamily.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([family, groups]) => {
      const meanings = groups.map((g) => groupMeaning.get(g)!.meaning);
      const meaning = family === 'course' ? resolveCourse(meanings) : meanings[0];
      const members = groups.flatMap((g) => groupMarks.get(g) ?? []);
      const modifiers = new Set<CoffeeM2StructuralModifier>();
      for (const g of groups) {
        for (const m of groupMeaning.get(g)!.modifiers) modifiers.add(m);
        for (const m of extra.get(g) ?? []) modifiers.add(m);
      }
      return {
        meaning,
        groups: [...groups].sort(),
        bands: members.map((m) => m.band),
        modifiers: [...modifiers].sort(),
        closeCircle: members.some((m) => m.handleRelation === 'handle_near'),
      };
    });

  // 4) Build unified threads.
  const threads: CoffeeM2Thread[] = [];
  const threadEvidence: Record<string, string[]> = {};
  const finish = (base: Omit<CoffeeM2Thread, 'id' | 'facets' | 'depth' | 'scenario'>, groups: string[]) => {
    const id = `T${threads.length + 1}`;
    const facets = threadFacets(base);
    threads.push({ id, ...base, facets, depth: coffeeM2Depth(facets), scenario: coffeeM2Scenario(base) });
    threadEvidence[id] = [...new Set(groups)].sort();
  };

  for (const t of m1.meaning.threads) {
    const groups = m1.audit.threadEvidence[t.id]?.identityGroups ?? [];
    const modifiers = new Set<string>(t.modifiers);
    // Closed object/structure compatibility: a continuous form on a contact mark adds `continuing`.
    const contactContinuous = groups.some((g) =>
      (groupMarks.get(g) ?? []).some((m) => OBJECT_CONTINUITY_SIGNS.has(String(coffeeM1MarkSign(m))) && m.form.continuity === 'continuous'));
    if (contactContinuous) modifiers.add('continuing');
    finish(objectBase(t, [...modifiers].sort()), groups);
  }

  for (const combined of coffeeM2CombineStructural(units, separatedFamilies)) {
    const developments = combined.units.map((u) => u.meaning);
    const developmentHorizons = combined.units.map((u) => ({ development: u.meaning, horizon: horizonOf(u.bands) }));
    const distinct = new Set(developmentHorizons.map((d) => d.horizon));
    const modifiers = new Set<string>(combined.units.flatMap((u) => u.modifiers));
    if (combined.units.some((u) => u.closeCircle)) modifiers.add('close_circle');
    if (combined.units.some((u) => u.groups.length > 1)) modifiers.add('recurring');

    const contextBindings: CoffeeM1ContextBinding[] = [];
    const contextForbidden: CoffeeM1ContextForbidden[] = [];
    const conjecture: string[] = [];
    if (declared.includes('decision_exists')) {
      const tokens = developments.map((d) => STRUCTURE_DECISION[d]).filter((t): t is string => !!t);
      if (tokens.length) {
        contextBindings.push('user_decision');
        contextForbidden.push('option_identity', 'correct_option');
        conjecture.push(...tokens);
      }
    }
    const compatible = sections.filter((s) => developments.some((d) => STRUCTURE_DOMAIN[s][d]));
    let domain: CoffeeM1Domain | null = null;
    if (compatible.length === 1) {
      domain = DOMAIN_NAME[compatible[0]];
      conjecture.push(...developments.map((d) => STRUCTURE_DOMAIN[compatible[0]][d]).filter((t): t is string => !!t));
    }
    finish(
      {
        lane: 'structure',
        developments,
        combination: combined.combination,
        horizon: distinct.size === 1 ? developmentHorizons[0].horizon : 'coming_period',
        developmentHorizons,
        valence: combined.valence,
        modifiers: [...modifiers].sort(),
        contextBindings,
        domain,
        conjecture: [...new Set([...developments, ...(combined.combination ? [combined.combination] : []), ...conjecture])],
        forbiddenSpecifics: [...new Set([...COMMON_FORBIDDEN, ...combined.units.flatMap((u) => STRUCTURE_FORBIDDEN[FAMILY[u.meaning]])])],
        contextForbidden,
      },
      combined.units.flatMap((u) => u.groups),
    );
  }

  // 5) Capacity across both lanes: families and independent identity groups only.
  const families = new Set(threads.flatMap((t) => t.developments.map((d) => (t.lane === 'structure' ? FAMILY[d as CoffeeM2StructuralMeaning] : d))));
  const groupsUsed = new Set(Object.values(threadEvidence).flat());
  const useful = threads.some(
    (t) =>
      t.combination !== null ||
      t.developmentHorizons.some((d) => d.horizon === 'nearer_term' || d.horizon === 'further_out') ||
      t.modifiers.some((m) => m !== 'recurring'),
  );
  const capacity: CoffeeM1Capacity =
    families.size === 0 ? 'insufficient'
      : families.size === 1 ? 'single_thread'
        : families.size >= 3 && groupsUsed.size >= 3 && useful ? 'rich' : 'multi_thread';

  const depthRank: Record<CoffeeM2Depth, number> = { thin: 0, developed: 1, deep: 2 };
  const maxDepth = threads.length ? threads.map((t) => t.depth).sort((a, b) => depthRank[b] - depthRank[a])[0] : null;

  return {
    meaning: {
      subject: m1.meaning.subject,
      declaredContext: declared,
      intentReference: m1.meaning.intentReference,
      threads,
      diagnostics: {
        capacity,
        groundedDevelopmentCount: families.size,
        distinctFacetCount: Math.max(0, ...threads.map((t) => t.facets.length)),
        maxDepth,
        scenarioAvailable: threads.some((t) => t.scenario !== null),
      },
    },
    audit: {
      objectOwnedGroups: [...objectOwned].sort(),
      structureOwnedGroups: [...groupMeaning.keys()].sort(),
      contextGroups: [...groupMarks.keys()].filter((g) => !objectOwned.has(g) && !groupMeaning.has(g)).sort(),
      threadEvidence,
      contractGaps: COFFEE_M2_CONTRACT_GAPS,
    },
  };
}

function objectBase(t: CoffeeFortuneThread, modifiers: string[]): Omit<CoffeeM2Thread, 'id' | 'facets' | 'depth' | 'scenario'> {
  return {
    lane: 'object',
    developments: [...t.developments],
    combination: t.combination,
    horizon: t.horizon,
    developmentHorizons: t.developmentHorizons.map((d) => ({ development: d.development, horizon: d.horizon })),
    valence: t.valence,
    modifiers,
    contextBindings: [...t.contextBindings],
    domain: t.domain,
    conjecture: [...t.conjecture],
    forbiddenSpecifics: [...t.forbiddenSpecifics],
    contextForbidden: [...t.contextForbidden],
  };
}

/**
 * Read-only views of the M2 facet equivalence tables, for the dark W2 writer
 * beat planner. Exported so composition reuses M2's own classes instead of a
 * second interpretation; M2 behaviour is unchanged.
 */
export const COFFEE_M2_CORE_CLASS: Readonly<Record<string, string>> = CORE_CLASS;
export const COFFEE_M2_MODIFIER_FACET: Readonly<Record<string, Readonly<CoffeeM2Facet>>> = MODIFIER_FACET;
export const COFFEE_M2_CONSEQUENCE_FACET: Readonly<Record<string, string>> = CONSEQUENCE_FACET;
