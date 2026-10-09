import type { CoffeeForbiddenSpecific } from './coffee-fortune-beat.js';
import type {
  CoffeeM1Combination,
  CoffeeM1Conjecture,
  CoffeeM1ContextBinding,
  CoffeeM1ContextForbidden,
  CoffeeM1Domain,
  CoffeeM1Horizon,
  CoffeeM1Modifier,
  CoffeeM1Subject,
  CoffeeM1Valence,
} from './coffee-m1-interpretation.js';
import {
  COFFEE_M2_CONSEQUENCE_FACET,
  COFFEE_M2_CORE_CLASS,
  COFFEE_M2_MODIFIER_FACET,
  coffeeM2Scenario,
  type CoffeeM2Diagnostics,
  type CoffeeM2Meaning,
  type CoffeeM2ScenarioContext,
  type CoffeeM2StructuralCombination,
  type CoffeeM2StructuralMeaning,
  type CoffeeM2StructuralModifier,
  type CoffeeM2Thread,
} from './coffee-m2-semantic-engine.js';
import { assertCoffeeV3MeaningOnly } from './coffee-v3-mark-map.js';

/**
 * W2 — DARK PRE-WRITER BEAT PLANNER. ADDITIVE AND DARK: no live path, writer,
 * worker or route imports this.
 *
 * M2 MEANING → ordered, writer-safe semantic beats. The planner decides
 * COMPOSITION only: which licensed ideas are used, how they are grouped and
 * ordered, where the relation, scenario and qualifiers sit, and where the plan
 * stops. It never writes prose and never reinterprets M2: developments,
 * horizons, domain, valence, scenarios, capacity and depth are taken as given,
 * and the facet equivalence classes are M2's own.
 *
 * Input is CoffeeM2Meaning ONLY (never the M2 audit, evidence, identity
 * groups, marks or observer data).
 */

// ---------------------------------------------------------------------------
// Contract gaps (reported, never faked)
// ---------------------------------------------------------------------------

/**
 * Facts M2 meaning does not expose directly. Each is either resolved by a
 * closed, deterministic rule over M2's own public tables, or left unplanned:
 * - scenario source: M2 does not say which development a scenario realizes;
 *   it is recovered by probing coffeeM2Scenario per development (same rule M2
 *   used), never by guessing;
 * - modifier owner: M2 modifiers are thread-level; the owner is taken from the
 *   closed producer table below only when it is unique, otherwise the group is
 *   omitted (close_circle / recurring on a two-development thread);
 * - consequence owner: a consequence facet on a two-development thread has no
 *   exposed owner and is omitted.
 */
export const COFFEE_M2_WRITER_CONTRACT_GAPS = [
  'scenario_source_not_exposed_derived_by_m2_probe',
  'modifier_owner_not_exposed_closed_producer_table',
  'consequence_owner_not_exposed_on_two_development_thread',
] as const;

// ---------------------------------------------------------------------------
// Plan model
// ---------------------------------------------------------------------------

/** The hard writer contract every beat carries. Constant: nothing ever relaxes it. */
export const COFFEE_M2_WRITER_CONSTRAINTS = {
  maxIndependentGroups: 2,
  noCausation: true,
  noAdvice: true,
  noNewConsequence: true,
  noPresupposition: true,
  noExtraScenario: true,
  noSummary: true,
  noChronology: true,
  noRestatement: true,
} as const;
export type CoffeeM2WriterConstraints = typeof COFFEE_M2_WRITER_CONSTRAINTS;

/** No summary / conclusion / closing / payoff purpose exists. */
export type CoffeeM2WriterBeatPurpose = 'relation' | 'development' | 'scenario' | 'elaboration';

export type CoffeeM2WriterGroupKind = 'core_development' | 'trajectory' | 'persistence' | 'scope' | 'consequence' | 'scenario';

/** One independently expressible public idea. */
export type CoffeeM2WriterGroup = {
  kind: CoffeeM2WriterGroupKind;
  /** M2 facet equivalence class (dedup key); `SCENARIO` for an independent scenario group. */
  cls: string;
  /** Licensed machine tokens for this one idea (development / modifier / conjecture tokens). */
  tokens: string[];
  /** A core development's OWN horizon; null when unspecified or not a core group. */
  horizon: CoffeeM1Horizon | null;
  /** Elaboration / scenario: the core class this group is about (already stated, referenced only). */
  about: string | null;
};

export type CoffeeM2WriterRelation = {
  combination: CoffeeM1Combination | CoffeeM2StructuralCombination;
  /** Relation conjecture tokens M2 licensed for this combination. */
  conjecture: string[];
  /** The two component classes the relation joins. */
  components: string[];
  /** Co-development only: never causal. */
  mode: 'co_development';
};

export type CoffeeM2WriterScenario = {
  context: CoffeeM2ScenarioContext;
  specificity: 'S1' | 'S2';
  manifestations: string[];
  forbidden: string[];
  /** Core class this scenario concretely realizes (null only when M2's source could not be recovered). */
  realizes: string | null;
  /** fused = same idea as its core group (one use); shared = second group of the core's beat; own_beat = its own beat. */
  placement: 'fused' | 'shared' | 'own_beat';
};

export type CoffeeM2WriterMention = 'introduce' | 'implied';

export type CoffeeM2WriterQualifiers = {
  domain: { domain: CoffeeM1Domain; mention: CoffeeM2WriterMention } | null;
  context: Array<{ binding: CoffeeM1ContextBinding; mention: CoffeeM2WriterMention }>;
  /** Tone hint only; never a fact. */
  tone: CoffeeM1Valence;
};

export type CoffeeM2WriterBeat = {
  id: string;
  threadId: string;
  purpose: CoffeeM2WriterBeatPurpose;
  groups: CoffeeM2WriterGroup[];
  relation: CoffeeM2WriterRelation | null;
  scenario: CoffeeM2WriterScenario | null;
  qualifiers: CoffeeM2WriterQualifiers;
  constraints: CoffeeM2WriterConstraints;
};

export type CoffeeM2WriterOmissionReason =
  | 'class_already_consumed'
  | 'modifier_owner_ambiguous'
  | 'consequence_owner_ambiguous'
  | 'scenario_redundant'
  | 'scenario_duplicate'
  | 'relation_not_distinct'
  | 'relation_components_consumed';

export type CoffeeM2WriterPlan = {
  status: 'planned' | 'insufficient';
  subject: CoffeeM1Subject;
  beats: CoffeeM2WriterBeat[];
  /** Writer-safe union of every thread's M2 forbidden lists (stricter, never looser). */
  forbidden: { specifics: CoffeeForbiddenSpecific[]; context: CoffeeM1ContextForbidden[] };
  omitted: Array<{ threadId: string; cls: string; reason: CoffeeM2WriterOmissionReason }>;
  diagnostics: {
    /** M2 diagnostics, echoed unchanged. */
    m2: CoffeeM2Diagnostics;
    beatCount: number;
    maxGroupsPerBeat: number;
    relationCount: number;
    scenarioCount: number;
  };
};

/** Dark planner audit. Never part of a provider payload. */
export type CoffeeM2WriterPlanAudit = {
  consumedFacetClasses: string[];
  qualifierFacetClasses: string[];
  omittedFacetClasses: string[];
  omittedReasons: Record<string, CoffeeM2WriterOmissionReason>;
  scenarioConsumed: Array<{
    threadId: string;
    placement: CoffeeM2WriterScenario['placement'] | 'omitted_redundant' | 'omitted_duplicate';
    source: string | null;
    beatId: string | null;
  }>;
  relationConsumed: Array<{ threadId: string; combination: string; status: 'consumed' | 'not_distinct' | 'components_consumed'; beatId: string | null }>;
  beatGroupCounts: Record<string, number>;
  conjectureAsQualifier: string[];
  unplacedConjecture: Array<{ threadId: string; token: string; reason: 'no_group_of_class' | 'unmapped' }>;
  contractGaps: readonly string[];
};

export type CoffeeM2WriterPlanResult = { plan: CoffeeM2WriterPlan; audit: CoffeeM2WriterPlanAudit };

// ---------------------------------------------------------------------------
// Closed tables
// ---------------------------------------------------------------------------

type DevelopmentToken = string;
const ANY = '*' as const;

/**
 * Which developments can produce each modifier: COFFEE_M1_FORM_GRAMMAR (object
 * lane) and the M2 structure lane. `*` = any development (relation- or
 * placement-derived modifiers).
 */
const MODIFIER_PRODUCERS: Record<CoffeeM1Modifier | CoffeeM2StructuralModifier, readonly DevelopmentToken[] | typeof ANY> = {
  active: ['contact', 'opportunity'],
  quiet: ['contact'],
  direct: ['contact', 'written_contact'],
  not_yet_open: ['contact', 'written_contact'],
  reaching: ['contact'],
  intermittent: ['written_contact'],
  gaining_momentum: ['opportunity'],
  visible_opening: ['opportunity'],
  multi_stream: ['gradual_growth'],
  steady: ['gradual_growth'],
  long_running: ['gradual_growth', 'direction_change'],
  turning: ['direction_change'],
  continuing_course: ['direction_change'],
  upward_progression: ['direction_change'],
  whole_durable: ['commitment'],
  singular_focus: ['commitment'],
  leaning: ['emotional_movement'],
  usable_opening: ['access_opening'],
  gathering: ['social_presence'],
  stop_start: ['possibilities_branch'],
  continuing: ANY,
  recurring: ANY,
  close_circle: ANY,
  many_small_details: ANY,
  room_within: ANY,
  within_one_phase: ANY,
};

type ConjectureRole =
  | { role: 'development'; classes: string[] }
  | { role: 'relation' }
  | { role: 'domain'; classes: string[] }
  | { role: 'context'; binding: CoffeeM1ContextBinding; classes: string[] };

const dev = (...classes: string[]): ConjectureRole => ({ role: 'development', classes });
const dom = (...classes: string[]): ConjectureRole => ({ role: 'domain', classes });
const ctx = (binding: CoffeeM1ContextBinding, ...classes: string[]): ConjectureRole => ({ role: 'context', binding, classes });
const REL: ConjectureRole = { role: 'relation' };

/** Closed conjecture → role table (exhaustive over M1 conjecture; plus the M2 structure-lane tokens). */
const CONJECTURE_ROLE: Record<CoffeeM1Conjecture | CoffeeM2StructuralMeaning | CoffeeM2StructuralCombination | string, ConjectureRole> = {
  ...({
    news: dev('COMMUNICATION'),
    communication_movement: dev('COMMUNICATION', 'WRITTEN_COMMUNICATION'),
    written_news: dev('WRITTEN_COMMUNICATION'),
    communication_about_chosen_person: ctx('chosen_person', 'COMMUNICATION', 'WRITTEN_COMMUNICATION'),
    kismet: dev('OPPORTUNITY'),
    opportunity: dev('OPPORTUNITY'),
    beautiful_kismet: dev('OPPORTUNITY'),
    lasting_bond_possibility: dev('COMMITMENT'),
    serious_heart_kismet_possibility: dev('COMMITMENT'),
    feelings_deepen: dev('FEELING'),
    heart_inclines: dev('LEANING'),
    path_opening: dev('OPENING'),
    way_through: dev('OPENING'),
    new_direction: dev('CHANGE'),
    new_beginning: dev('CHANGE'),
    gradual_development: dev('GROWTH'),
    abundance: dev('GROWTH'),
    options_clarify: dev('MULTIPLICITY'),
    people_around: dev('PEOPLE'),
    opportunity_with_news: REL,
    opportunity_with_written_news: REL,
    growing_kismet: REL,
    heartfelt_lasting_bond_possibility: REL,
    opening_through_new_direction: REL,
    developing_change: REL,
    options_shape_direction: REL,
    communication_in_relationship: REL,
    decision_clarity: ctx('user_decision', 'MULTIPLICITY', 'OPENING'),
    decision_direction: ctx('user_decision', 'CHANGE'),
    communication_on_awaited_topic: ctx('awaited_topic', 'COMMUNICATION'),
    written_news_on_awaited_topic: ctx('awaited_topic', 'WRITTEN_COMMUNICATION'),
    current_relationship_theme: ctx('current_relationship', 'COMMITMENT', 'FEELING'),
    communication_in_current_relationship: ctx('current_relationship', 'COMMUNICATION', 'WRITTEN_COMMUNICATION'),
    financial_opening: dom('OPPORTUNITY', 'OPENING'),
    financial_growth: dom('GROWTH'),
    career_opening: dom('OPPORTUNITY', 'OPENING'),
    career_direction: dom('CHANGE'),
    career_growth: dom('GROWTH'),
    love_development: dom('COMMITMENT', 'FEELING', 'COMMUNICATION', 'WRITTEN_COMMUNICATION'),
  } satisfies Record<CoffeeM1Conjecture, ConjectureRole>),
  // M2 structure lane
  steady_course: dev('FORWARD'),
  course_turn: dev('CHANGE'),
  stop_start_course: dev('UNEVEN'),
  possibilities_branch: dev('MULTIPLICITY'),
  opening_clarity: dev('OPENING'),
  stalled_course_finds_room: REL,
  opening_moves_forward: REL,
  possibilities_become_visible: REL,
  course_opens_into_alternatives: REL,
  decision_options: ctx('user_decision', 'MULTIPLICITY'),
  career_progression: dom('FORWARD'),
  financial_possibilities: dom('MULTIPLICITY'),
  love_clarity: dom('OPENING'),
};

/**
 * Closed relation policy. `distinct` = the curated combination says something
 * beyond its two components and MUST be planned exactly once. `co_theme` = it
 * only says the two share a theme, which the qualifiers already carry: the
 * components stay together, without a relation token.
 */
const RELATION_POLICY: Record<CoffeeM1Combination | CoffeeM2StructuralCombination, { policy: 'distinct' | 'co_theme'; conjecture: string }> = {
  opportunity_with_gradual_growth: { policy: 'distinct', conjecture: 'growing_kismet' },
  commitment_with_emotion: { policy: 'distinct', conjecture: 'heartfelt_lasting_bond_possibility' },
  access_through_direction: { policy: 'distinct', conjecture: 'opening_through_new_direction' },
  choice_with_direction: { policy: 'distinct', conjecture: 'options_shape_direction' },
  direction_with_growth: { policy: 'distinct', conjecture: 'developing_change' },
  contact_with_opportunity: { policy: 'distinct', conjecture: 'opportunity_with_news' },
  written_contact_with_opportunity: { policy: 'distinct', conjecture: 'opportunity_with_written_news' },
  contact_in_relationship: { policy: 'co_theme', conjecture: 'communication_in_relationship' },
  course_opens_into_alternatives: { policy: 'distinct', conjecture: 'course_opens_into_alternatives' },
  stalled_course_finds_room: { policy: 'distinct', conjecture: 'stalled_course_finds_room' },
  opening_moves_forward: { policy: 'distinct', conjecture: 'opening_moves_forward' },
  possibilities_become_visible: { policy: 'distinct', conjecture: 'possibilities_become_visible' },
};

/**
 * Closed scenario redundancy table: a manifestation that only restates an
 * M2 class. Unlisted manifestations add concrete, distinct realization.
 */
const SCENARIO_RESTATES: Readonly<Record<string, string>> = {
  steady_professional_progress: 'FORWARD',
  gradual_financial_improvement: 'GROWTH',
  multiple_supporting_channels: 'MULTI_STREAM',
  multiple_professional_options: 'MULTIPLICITY',
  another_option_visible: 'MULTIPLICITY',
  single_track_gaining_alternatives: 'MULTIPLICITY',
  another_direction: 'CHANGE',
  professional_direction_change: 'CHANGE',
  direction_change_worth_considering: 'CHANGE',
  matter_opening: 'OPENING',
  new_financial_opportunity: 'OPPORTUNITY',
  declared_relationship_more_serious: 'COMMITMENT',
  communication_around_chosen_person: 'COMMUNICATION',
  communication_around_awaited_matter: 'COMMUNICATION',
};

const MODIFIER_CATEGORIES = new Set(['trajectory', 'persistence', 'scope']);
const QUALIFIER_CATEGORIES = new Set(['horizon', 'domain', 'user_context']);

// ---------------------------------------------------------------------------
// Helpers (pure; never mutate M2 meaning)
// ---------------------------------------------------------------------------

const coreClass = (development: string) => COFFEE_M2_CORE_CLASS[development] ?? development;

function ownerOf(tokens: string[], developments: string[]): string | null {
  let candidates = new Set(developments);
  for (const token of tokens) {
    const producers = MODIFIER_PRODUCERS[token as keyof typeof MODIFIER_PRODUCERS] ?? ANY;
    if (producers === ANY) continue;
    candidates = new Set([...candidates].filter((d) => producers.includes(d)));
  }
  return candidates.size === 1 ? [...candidates][0] : null;
}

/** The development whose palette row M2's coffeeM2Scenario chose (same rule, probed per development). */
function scenarioSource(thread: CoffeeM2Thread): string | null {
  const scenario = thread.scenario;
  if (!scenario) return null;
  for (const development of thread.developments) {
    const probe = coffeeM2Scenario({ developments: [development], contextBindings: thread.contextBindings, domain: thread.domain });
    if (probe && probe.context === scenario.context && JSON.stringify(probe.manifestations) === JSON.stringify(scenario.manifestations)) {
      return development;
    }
  }
  return null;
}

function horizonFor(thread: CoffeeM2Thread, developments: string[]): CoffeeM1Horizon | null {
  const horizons = [...new Set(thread.developmentHorizons.filter((d) => developments.includes(d.development)).map((d) => d.horizon))];
  // M2's own aggregate convention: one shared horizon, otherwise the broad coming period.
  const horizon = horizons.length === 0 ? 'unspecified' : horizons.length === 1 ? horizons[0] : 'coming_period';
  return horizon === 'unspecified' ? null : horizon;
}

const uniq = <T>(values: T[]) => [...new Set(values)];

// ---------------------------------------------------------------------------
// Planner
// ---------------------------------------------------------------------------

export function planCoffeeM2Writer(meaning: CoffeeM2Meaning): CoffeeM2WriterPlanResult {
  const audit: CoffeeM2WriterPlanAudit = {
    consumedFacetClasses: [],
    qualifierFacetClasses: [],
    omittedFacetClasses: [],
    omittedReasons: {},
    scenarioConsumed: [],
    relationConsumed: [],
    beatGroupCounts: {},
    conjectureAsQualifier: [],
    unplacedConjecture: [],
    contractGaps: COFFEE_M2_WRITER_CONTRACT_GAPS,
  };
  const omitted: CoffeeM2WriterPlan['omitted'] = [];
  const omit = (threadId: string, cls: string, reason: CoffeeM2WriterOmissionReason) => {
    omitted.push({ threadId, cls, reason });
    audit.omittedFacetClasses.push(cls);
    audit.omittedReasons[`${threadId}:${cls}`] = reason;
  };
  const m2 = { ...meaning.diagnostics };
  const forbidden = {
    specifics: uniq(meaning.threads.flatMap((t) => t.forbiddenSpecifics)),
    context: uniq(meaning.threads.flatMap((t) => t.contextForbidden)),
  };

  if (meaning.diagnostics.capacity === 'insufficient' || meaning.threads.length === 0) {
    return {
      plan: {
        status: 'insufficient',
        subject: meaning.subject,
        beats: [],
        forbidden,
        omitted,
        diagnostics: { m2, beatCount: 0, maxGroupsPerBeat: 0, relationCount: 0, scenarioCount: 0 },
      },
      audit,
    };
  }

  const beats: CoffeeM2WriterBeat[] = [];
  const consumed = new Set<string>();
  const introducedDomains = new Set<CoffeeM1Domain>();
  const introducedContexts = new Set<CoffeeM1ContextBinding>();
  const usedScenarios = new Set<string>();

  // Threads keep M2's deterministic order (object lane in M1's curated order,
  // then the structure lane); the planner invents no importance ranking.
  for (const thread of meaning.threads) {
    const threadBeats: Array<Omit<CoffeeM2WriterBeat, 'id' | 'qualifiers' | 'constraints'>> = [];
    const consume = (cls: string) => {
      consumed.add(cls);
      audit.consumedFacetClasses.push(cls);
    };

    // 1) Groups from M2's own facets (already deduped by equivalence class).
    const cores: Array<{ development: string[]; group: CoffeeM2WriterGroup }> = [];
    const owned = new Map<string, CoffeeM2WriterGroup[]>(); // core class -> elaboration groups
    for (const facet of thread.facets) {
      if (QUALIFIER_CATEGORIES.has(facet.category)) {
        audit.qualifierFacetClasses.push(facet.cls);
        continue;
      }
      if (facet.category === 'relational') continue; // planned with the relation below
      if (consumed.has(facet.cls)) {
        omit(thread.id, facet.cls, 'class_already_consumed');
        continue;
      }
      if (facet.category === 'core_development') {
        const developments = thread.developments.filter((d) => coreClass(d) === facet.cls);
        const sameClassModifiers = thread.modifiers.filter((m) => COFFEE_M2_MODIFIER_FACET[m]?.cls === facet.cls);
        cores.push({
          development: developments,
          group: {
            kind: 'core_development',
            cls: facet.cls,
            tokens: uniq([...developments, ...sameClassModifiers]),
            horizon: horizonFor(thread, developments),
            about: null,
          },
        });
        consume(facet.cls);
        continue;
      }
      let owner: string | null;
      let tokens: string[];
      if (MODIFIER_CATEGORIES.has(facet.category)) {
        tokens = thread.modifiers.filter((m) => COFFEE_M2_MODIFIER_FACET[m]?.cls === facet.cls);
        owner = thread.developments.length === 1 ? thread.developments[0] : ownerOf(tokens, thread.developments);
        if (!owner) {
          omit(thread.id, facet.cls, 'modifier_owner_ambiguous');
          continue;
        }
      } else {
        // consequence: only an M2-licensed conjecture facet, never planner-created.
        tokens = thread.conjecture.filter((c) => COFFEE_M2_CONSEQUENCE_FACET[c] === facet.cls);
        owner = thread.developments.length === 1 ? thread.developments[0] : null;
        if (!owner) {
          omit(thread.id, facet.cls, 'consequence_owner_ambiguous');
          continue;
        }
      }
      const about = coreClass(owner);
      owned.set(about, [
        ...(owned.get(about) ?? []),
        { kind: facet.category as CoffeeM2WriterGroupKind, cls: facet.cls, tokens, horizon: null, about },
      ]);
      consume(facet.cls);
    }

    // 2) Relation: the two component groups together, exactly once.
    let relationBeat: (typeof threadBeats)[number] | null = null;
    if (thread.combination) {
      const policy = RELATION_POLICY[thread.combination as keyof typeof RELATION_POLICY];
      const components = uniq(thread.developments.map(coreClass));
      const relClass = `RELATION_${thread.combination}`;
      if (!policy || policy.policy !== 'distinct') {
        omit(thread.id, relClass, 'relation_not_distinct');
        audit.relationConsumed.push({ threadId: thread.id, combination: thread.combination, status: 'not_distinct', beatId: null });
        if (cores.length === 2) {
          threadBeats.push({ threadId: thread.id, purpose: 'development', groups: cores.map((c) => c.group), relation: null, scenario: null });
        }
      } else if (cores.length === 0) {
        omit(thread.id, relClass, 'relation_components_consumed');
        audit.relationConsumed.push({ threadId: thread.id, combination: thread.combination, status: 'components_consumed', beatId: null });
      } else {
        relationBeat = {
          threadId: thread.id,
          purpose: 'relation',
          groups: cores.map((c) => c.group),
          relation: {
            combination: thread.combination as CoffeeM2WriterRelation['combination'],
            conjecture: thread.conjecture.filter((c) => c === policy.conjecture),
            components,
            mode: 'co_development',
          },
          scenario: null,
        };
        threadBeats.push(relationBeat);
        consume(relClass);
      }
    }
    for (const core of cores) {
      if (!threadBeats.some((b) => b.groups.includes(core.group))) {
        threadBeats.push({ threadId: thread.id, purpose: 'development', groups: [core.group], relation: null, scenario: null });
      }
    }

    // 3) Scenario: exactly once, near its source, never split, never repeated.
    const beatOfClass = (cls: string | null) => threadBeats.find((b) => b.groups.some((g) => g.cls === cls)) ?? null;
    if (thread.scenario) {
      const scenario = thread.scenario;
      const sourceDevelopment = scenarioSource(thread);
      const realizes = sourceDevelopment ? coreClass(sourceDevelopment) : null;
      const planned = new Set([...cores.map((c) => c.group.cls), ...[...owned.values()].flat().map((g) => g.cls)]);
      const restating = scenario.manifestations.filter((m) => SCENARIO_RESTATES[m] && planned.has(SCENARIO_RESTATES[m]));
      const key = JSON.stringify([scenario.context, scenario.manifestations]);
      if (usedScenarios.has(key)) {
        omit(thread.id, 'SCENARIO', 'scenario_duplicate');
        audit.scenarioConsumed.push({ threadId: thread.id, placement: 'omitted_duplicate', source: realizes, beatId: null });
      } else if (restating.length === scenario.manifestations.length) {
        omit(thread.id, 'SCENARIO', 'scenario_redundant');
        audit.scenarioConsumed.push({ threadId: thread.id, placement: 'omitted_redundant', source: realizes, beatId: null });
      } else {
        usedScenarios.add(key);
        const sourceBeat = beatOfClass(realizes);
        const base = { context: scenario.context, specificity: scenario.specificity, manifestations: [...scenario.manifestations], forbidden: [...scenario.forbidden], realizes };
        const fused = sourceBeat && restating.some((m) => SCENARIO_RESTATES[m] === realizes);
        if (fused) {
          sourceBeat.scenario = { ...base, placement: 'fused' };
        } else if (sourceBeat && sourceBeat.groups.length < 2) {
          sourceBeat.groups.push({ kind: 'scenario', cls: 'SCENARIO', tokens: [...scenario.manifestations], horizon: null, about: realizes });
          sourceBeat.scenario = { ...base, placement: 'shared' };
        } else {
          const anchor = sourceBeat ?? threadBeats[0] ?? null;
          const own = {
            threadId: thread.id,
            purpose: 'scenario' as const,
            groups: [{ kind: 'scenario' as const, cls: 'SCENARIO', tokens: [...scenario.manifestations], horizon: null, about: realizes }],
            relation: null,
            scenario: { ...base, placement: 'own_beat' as const },
          };
          threadBeats.splice(anchor ? threadBeats.indexOf(anchor) + 1 : threadBeats.length, 0, own);
        }
      }
    }

    // 4) Elaborations: a single-group development beat takes its first owned
    //    group; the rest pair up per owner (max two), in M2 facet order.
    for (const core of cores) {
      const rest = [...(owned.get(core.group.cls) ?? [])];
      const coreBeat = beatOfClass(core.group.cls);
      if (coreBeat && coreBeat.purpose === 'development' && coreBeat.groups.length < 2 && rest.length > 0) {
        coreBeat.groups.push(rest.shift()!);
      }
      for (let i = 0; i < rest.length; i += 2) {
        threadBeats.push({ threadId: thread.id, purpose: 'elaboration', groups: rest.slice(i, i + 2), relation: null, scenario: null });
      }
    }
    // Owned groups whose core class was consumed by an earlier thread still elaborate it.
    for (const [about, groups] of owned) {
      if (cores.some((c) => c.group.cls === about)) continue;
      for (let i = 0; i < groups.length; i += 2) {
        threadBeats.push({ threadId: thread.id, purpose: 'elaboration', groups: groups.slice(i, i + 2), relation: null, scenario: null });
      }
    }

    // 5) Licensed conjecture: development tokens join the first group of their
    //    class; domain / context tokens are carried as qualifiers.
    const allGroups = threadBeats.flatMap((b) => b.groups).filter((g) => g.kind !== 'scenario');
    const domainClasses = new Set<string>();
    const contextClasses = new Map<CoffeeM1ContextBinding, Set<string>>();
    for (const token of thread.conjecture) {
      const role = CONJECTURE_ROLE[token];
      if (!role) {
        audit.unplacedConjecture.push({ threadId: thread.id, token, reason: 'unmapped' });
        continue;
      }
      if (role.role === 'relation') continue;
      const target = allGroups.find((g) => role.classes.includes(g.cls));
      if (role.role === 'development') {
        if (target) target.tokens = uniq([...target.tokens, token]);
        else audit.unplacedConjecture.push({ threadId: thread.id, token, reason: 'no_group_of_class' });
        continue;
      }
      // A domain / context token binds every planned class it names (love_development covers bond and feeling).
      audit.conjectureAsQualifier.push(token);
      const bound = allGroups.filter((g) => role.classes.includes(g.cls)).map((g) => g.cls);
      if (role.role === 'domain') for (const cls of bound) domainClasses.add(cls);
      else contextClasses.set(role.binding, new Set([...(contextClasses.get(role.binding) ?? []), ...bound]));
    }

    // 6) Qualifiers attach to the beats they qualify; each is introduced once.
    const touches = (beat: (typeof threadBeats)[number], classes: Set<string>) =>
      beat.groups.some((g) => classes.has(g.cls) || (g.about !== null && classes.has(g.about)))
      || (beat.scenario?.realizes != null && classes.has(beat.scenario.realizes));
    for (const [index, beat] of threadBeats.entries()) {
      let domain: CoffeeM2WriterQualifiers['domain'] = null;
      if (thread.domain && (domainClasses.size ? touches(beat, domainClasses) : index === 0)) {
        domain = { domain: thread.domain, mention: introducedDomains.has(thread.domain) ? 'implied' : 'introduce' };
        introducedDomains.add(thread.domain);
      }
      const context: CoffeeM2WriterQualifiers['context'] = [];
      for (const binding of thread.contextBindings) {
        const classes = contextClasses.get(binding);
        if (classes ? touches(beat, classes) : index === 0) {
          context.push({ binding, mention: introducedContexts.has(binding) ? 'implied' : 'introduce' });
          introducedContexts.add(binding);
        }
      }
      const id = `B${beats.length + 1}`;
      beats.push({ id, ...beat, qualifiers: { domain, context, tone: thread.valence }, constraints: COFFEE_M2_WRITER_CONSTRAINTS });
      audit.beatGroupCounts[id] = beat.groups.length;
      if (beat.relation) {
        audit.relationConsumed.push({ threadId: thread.id, combination: beat.relation.combination, status: 'consumed', beatId: id });
      }
      if (beat.scenario) {
        audit.scenarioConsumed.push({ threadId: thread.id, placement: beat.scenario.placement, source: beat.scenario.realizes, beatId: id });
      }
    }
  }

  // Hard invariants: fail closed rather than hand a writer an unsafe plan.
  for (const beat of beats) {
    if (beat.groups.length === 0 || beat.groups.length > COFFEE_M2_WRITER_CONSTRAINTS.maxIndependentGroups) {
      throw new Error(`coffee_m2_writer_plan_invariant: ${beat.id} has ${beat.groups.length} groups`);
    }
  }

  return {
    plan: {
      status: 'planned',
      subject: meaning.subject,
      beats,
      forbidden,
      omitted,
      diagnostics: {
        m2,
        beatCount: beats.length,
        maxGroupsPerBeat: Math.max(...beats.map((b) => b.groups.length)),
        relationCount: beats.filter((b) => b.relation).length,
        scenarioCount: beats.filter((b) => b.scenario).length,
      },
    },
    audit,
  };
}

// ---------------------------------------------------------------------------
// Provider payload boundary
// ---------------------------------------------------------------------------

export type CoffeeM2WriterPayload = {
  subject: CoffeeM1Subject;
  beats: Array<{
    order: number;
    purpose: CoffeeM2WriterBeatPurpose;
    groups: CoffeeM2WriterGroup[];
    relation: CoffeeM2WriterRelation | null;
    scenario: CoffeeM2WriterScenario | null;
    qualifiers: CoffeeM2WriterQualifiers;
    constraints: CoffeeM2WriterConstraints;
  }>;
  forbidden: CoffeeM2WriterPlan['forbidden'];
};

/**
 * The ONLY value a future writer may receive: ordered beats, their licensed
 * tokens, qualifiers, scenario / relation tokens and forbidden rules. Never
 * the audit, omissions, diagnostics, thread ids or raw user text. An
 * insufficient plan has no payload (the writer must not be invoked).
 */
export function toCoffeeM2WriterPayload(plan: CoffeeM2WriterPlan): CoffeeM2WriterPayload {
  if (plan.status !== 'planned' || plan.beats.length === 0) {
    throw new Error('coffee_m2_writer_plan_insufficient');
  }
  const payload: CoffeeM2WriterPayload = {
    subject: plan.subject,
    beats: plan.beats.map((beat, index) => ({
      order: index + 1,
      purpose: beat.purpose,
      groups: beat.groups.map((g) => ({ ...g, tokens: [...g.tokens] })),
      relation: beat.relation ? { ...beat.relation, conjecture: [...beat.relation.conjecture], components: [...beat.relation.components] } : null,
      scenario: beat.scenario ? { ...beat.scenario, manifestations: [...beat.scenario.manifestations], forbidden: [...beat.scenario.forbidden] } : null,
      qualifiers: { ...beat.qualifiers, context: beat.qualifiers.context.map((c) => ({ ...c })) },
      constraints: { ...beat.constraints },
    })),
    forbidden: { specifics: [...plan.forbidden.specifics], context: [...plan.forbidden.context] },
  };
  assertCoffeeV3MeaningOnly(payload);
  return payload;
}
