import {
  toCoffeeM2TurkishWriterPayload,
  type CoffeeM2TurkishWriterPayload,
  type CoffeeTurkishSurfaceRole,
  COFFEE_TURKISH_SURFACE_OVERLAPS,
} from './coffee-m2-turkish-surface-bank.js';
import type { CoffeeM2WriterPlan } from './coffee-m2-writer-beat-plan.js';
import { assertCoffeeV3MeaningOnly } from './coffee-v3-mark-map.js';

/**
 * W4C — DARK TURKISH REALIZATION POLICY. ADDITIVE AND DARK: no live path,
 * writer, worker or route imports this.
 *
 * W2 decides WHAT is said; W4A supplies HOW it MAY be said; W4C decides
 * which KINDS of W4A forms are grammatically and referentially safe for each
 * beat: legal syntactic roles, what an elaboration refers back to, which
 * subjects must stay apart across beats, opener repetition limits, scenario
 * role rules, scenario pairs that read as repetition, and public overlap
 * restrictions attached to the beats they bind. It never selects the final
 * phrase and never writes prose; the plan itself is untouched.
 */

// ---------------------------------------------------------------------------
// Referent bank: safe ways to refer BACK to an already stated class
// ---------------------------------------------------------------------------

type Referent = {
  text: string;
  /** Only usable when this conjecture token is licensed somewhere in the plan. */
  requiresToken?: string;
  /** Not usable under these relations: there the word publicly names BOTH components. */
  jointUnder?: readonly string[];
  /** Only usable when this user-context binding is present. */
  requiresContext?: string;
};

/** Referents preserve the class meaning; no generic "bu durum". */
export const COFFEE_TURKISH_REFERENTS: Readonly<Record<string, readonly Referent[]>> = {
  OPPORTUNITY: [
    { text: 'bu fırsat' },
    { text: 'bu imkân' },
    { text: 'gelen fırsat' },
    { text: 'bu kısmet', jointUnder: ['opportunity_with_gradual_growth'] },
  ],
  GROWTH: [
    { text: 'bu büyüme' },
    { text: 'büyümesi' },
    { text: 'bu gelişme' },
    { text: 'bereketi', requiresToken: 'abundance' },
  ],
  OPENING: [{ text: 'açılan bu yol' }, { text: 'bu açılan yol' }, { text: 'önündeki bu yol' }, { text: 'açılan yol' }],
  CHANGE: [{ text: 'bu yeni yön' }, { text: 'bu dönüş' }, { text: 'yeni yön' }],
  COMMITMENT: [
    { text: 'bu bağ' },
    { text: 'bu bağ ihtimali' },
    { text: 'aranızdaki bağ', requiresContext: 'current_relationship' },
    { text: 'bağın' },
  ],
  FEELING: [{ text: 'bu duygular' }, { text: 'derinleşen duyguların' }, { text: 'bu hisler' }, { text: 'hislerin' }],
  MULTIPLICITY: [{ text: 'bu ihtimaller' }, { text: 'bu seçenekler' }, { text: 'açılan bu yollar' }, { text: 'ihtimallerin' }],
  COMMUNICATION: [{ text: 'bu iletişim' }, { text: 'bu haberleşme' }, { text: 'haberleşme' }],
  WRITTEN_COMMUNICATION: [{ text: 'bu yazışma' }, { text: 'yazılı haber' }],
  FORWARD: [{ text: 'bu gidişat' }, { text: 'bu ilerleyiş' }, { text: 'gidişat' }],
};

/**
 * W4C.1 — the nouns that publicly NAME a class as a whole entity. Used to keep
 * a tempo-bound facet off the entity (the QA checker matches their folded stems).
 */
export const COFFEE_TURKISH_ENTITY_NOUNS: Readonly<Record<string, readonly string[]>> = {
  OPPORTUNITY: ['fırsat', 'imkân', 'kısmet', 'nasip'],
  GROWTH: ['büyüme', 'gelişme', 'bereket'],
};

/**
 * W4C.1 — facet referents. When an elaboration's class forms a tempo pair
 * with a class that the SAME relation already attaches to the elaboration's
 * owner, every entity noun of that owner may already carry the other tempo
 * (under growing_kismet the kısmet / fırsat itself grows). The elaboration then
 * refers ONLY to its facet. "hareket" here is the public realization of
 * MOMENTUM: never a new event, action, person or development. Only three
 * natural forms exist; "fırsat tarafındaki hareket" was rejected as stiff.
 */
export const COFFEE_TURKISH_FACET_REFERENTS: Readonly<Record<string, Readonly<Record<string, readonly string[]>>>> = {
  MOMENTUM: { OPPORTUNITY: ['fırsatın hareketi', 'fırsatın etrafındaki hareket', 'bu fırsattaki hareket'] },
};

const isDemonstrative = (text: string) => /^bu\s/i.test(text.trim());

// ---------------------------------------------------------------------------
// Cross-beat tempo compatibility
// ---------------------------------------------------------------------------

/**
 * Class pairs that are NOT semantically contradictory (they qualify different
 * facets) but sound contradictory when said of one shared subject. When both
 * appear in a plan, each must attach to its own referent.
 */
export const COFFEE_TURKISH_TEMPO_PAIRS: ReadonlyArray<{ classes: readonly [string, string]; note: string }> = [
  { classes: ['GROWTH', 'MOMENTUM'], note: 'gradual growth vs gaining speed: growth stays on büyüme / gelişme, speed on the opportunity\'s movement' },
  { classes: ['FORWARD', 'UNEVEN'], note: 'steady progress vs stop-start: keep them on different subjects' },
  { classes: ['MOMENTUM', 'QUIET'], note: 'gaining speed vs still quiet: keep them on different subjects' },
];

// ---------------------------------------------------------------------------
// Scenario pair compatibility (near-synonymous items read as repetition)
// ---------------------------------------------------------------------------

/** Closed list of scenario item pairs that must not be selected together. Never chooses an item. */
export const COFFEE_TURKISH_SCENARIO_INCOMPATIBLE_PAIRS: ReadonlyArray<{ pair: readonly [string, string]; why: string }> = [
  { pair: ['another_option_relevant', 'options_separating'], why: 'one adds an option, the other separates the options: together they pull the same noun two ways' },
  { pair: ['new_financial_opportunity', 'financial_side_strengthened'], why: 'both name a new financial means (fırsat / imkân): reads as one idea said twice' },
  { pair: ['communication_around_chosen_person', 'conversation_about_person_relevant'], why: 'communication and a conversation about the same person: one idea said twice' },
  { pair: ['professional_direction_change', 'other_professional_route'], why: 'a new professional direction and another professional route: one idea said twice' },
];

// ---------------------------------------------------------------------------
// Domain-sensitive surface (idiom only; semantically equivalent)
// ---------------------------------------------------------------------------

/**
 * Some class wordings are idiomatically odd in one public domain. Here a
 * domain may (a) offer equivalent wording that fits it and (b) mark generic
 * wording to avoid there. Never a semantic binding.
 */
export const COFFEE_TURKISH_DOMAIN_SURFACE: Readonly<Record<string, Readonly<Record<string, { forms: readonly string[]; avoid: readonly string[] }>>>> = {
  love: {
    SINGULAR: {
      forms: ['odağı dağılmayan', 'dağınık değil, tek bir odakta', 'başka yerlere savrulmayan'],
      avoid: ['tek bir yerde toplan', 'tek bir noktada toplan'],
    },
    DURABLE: {
      forms: ['parça parça değil, bir bütün', 'kopuk kopuk değil, bütünlüklü', 'bütünlüklü'],
      avoid: ['bütün duruyor', 'kopukluk olmadan bütün', 'bölünmeden duran'],
    },
  },
};

// ---------------------------------------------------------------------------
// Nominalization heuristic (QA + policy metadata; verbal nouns are NOT banned)
// ---------------------------------------------------------------------------

const NOMINAL_STOPLIST = new Set([
  'zaman', 'duman', 'orman', 'roman', 'liman', 'kahraman', 'dusman', 'hemen', 'ogretmen', 'yonetmen', 'ekmek', 'parmak',
  'kaymak', 'irmak', 'cakmak', 'yemek', 'imkan', 'kisman', 'erkek', 'saman', 'yaman', 'keman', 'seyran', 'tamam',
]);

function foldTr(value: string): string {
  return value
    .normalize('NFC')
    .toLocaleLowerCase('tr-TR')
    .replace(/ı/g, 'i').replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ş/g, 's').replace(/ö/g, 'o').replace(/ç/g, 'c').replace(/[âà]/g, 'a').replace(/[îì]/g, 'i').replace(/[ûù]/g, 'u');
}

/** Verbal-noun tokens: -ma/-me + possessive (-ması, -man, -manız …) and -mak/-mek infinitives. */
export function coffeeTurkishVerbalNouns(sentence: string): string[] {
  const tokens = foldTr(sentence).match(/[a-z]+/g) ?? [];
  return tokens.filter((t) => {
    if (t.length < 5) return false;
    const root = t.replace(/(dan|den|da|de|la|le|yla|yle|ya|ye|i|u|in|un|nin|nun)$/u, '');
    if (NOMINAL_STOPLIST.has(t) || NOMINAL_STOPLIST.has(root)) return false;
    return /(ma|me)(si|su|lari|leri|n|niz|nuz|m|miz|muz)$/.test(t) || /(mak|mek)$/.test(t);
  });
}

/**
 * STACKED nominalization: two or more verbal nouns in one sentence (e.g.
 * "… alman ya da … yer alman şeklinde", "…ması, …mesi ve …ması gibi"). A
 * single verbal noun is ordinary Turkish and is never flagged.
 */
export function coffeeTurkishStackedNominalization(text: string): boolean {
  return text.split(/(?<=[.!?…;])\s+/).some((sentence) => coffeeTurkishVerbalNouns(sentence).length >= 2);
}

// ---------------------------------------------------------------------------
// Realization payload
// ---------------------------------------------------------------------------

export type CoffeeM2BeatRealization = {
  order: number;
  /** Legal W4A roles per group class (the writer still chooses the phrase). */
  groupRoles: Array<{ cls: string; roles: CoffeeTurkishSurfaceRole[] }>;
  /** Scenario role rule: an own-beat scenario must be realized by a finite scenario clause. */
  scenarioRoles: { roles: CoffeeTurkishSurfaceRole[]; leadAsSoleRealization: boolean } | null;
  /** Elaboration / own-beat scenario: what it refers back to, and with which words. */
  referent: {
    aboutClass: string;
    /** entity = refer to the owner itself; facet = refer only to the elaborated facet (W4C.1). */
    kind: 'entity' | 'facet';
    referents: string[];
    forbiddenReferents: string[];
    /** facet only: entity nouns of the owner that must not be the subject of this beat. */
    forbiddenEntityNouns: string[];
    lexicalSubjectRequired: boolean;
  } | null;
  /** Public overlap restrictions bound to this beat's classes. */
  overlap: Array<{ cls: string; with: string; useOnly: string[]; neverUse: string[] }>;
  /** Domain-idiom wording for this beat's classes, and generic wording to avoid in that domain. */
  domainWording: Record<string, string[]>;
  avoidWording: string[];
  /** Scenario item pairs that must not be selected together in this beat. */
  scenarioIncompatiblePairs: string[][];
  finitePredicateRequired: true;
  avoidStackedNominalization: true;
  avoidSameOpenerAsPrevious: boolean;
};

export type CoffeeM2TurkishRealizationPayload = CoffeeM2TurkishWriterPayload & {
  realization: {
    beats: CoffeeM2BeatRealization[];
    crossBeat: {
      noIdenticalAdjacentOpener: true;
      /** Max beats that may open with a demonstrative ("Bu …"); never all of a 3+ beat plan. */
      demonstrativeOpenerMax: number;
      tempo: Array<{ classes: string[]; note: string; separateReferents: Record<string, string[]>; neverShared: string[] }>;
    };
  };
};

const CORE_ROLES: CoffeeTurkishSurfaceRole[] = ['predicate', 'lead', 'modifier'];
const RELATION_ROLES: CoffeeTurkishSurfaceRole[] = ['relational', 'predicate', 'lead', 'modifier'];
const ELABORATION_ROLES: CoffeeTurkishSurfaceRole[] = ['predicate', 'modifier', 'continuation'];

export function prepareCoffeeM2TurkishRealization(plan: CoffeeM2WriterPlan): CoffeeM2TurkishRealizationPayload {
  const payload = toCoffeeM2TurkishWriterPayload(plan); // refuses an insufficient plan
  const beats = payload.beats;
  const relations = new Set(beats.filter((b) => b.relation).map((b) => b.relation!.combination as string));
  const tokens = new Set(beats.flatMap((b) => b.groups.flatMap((g) => g.tokens)));
  const contexts = new Set(beats.flatMap((b) => b.qualifiers.context.map((c) => c.binding as string)));
  const planClasses = new Set(beats.flatMap((b) => b.groups.map((g) => g.cls)));
  const planDomains = beats.map((b) => b.qualifiers.domain?.domain ?? null);
  const firstDomain = planDomains.find((d) => d) ?? null;

  const usable = (cls: string) => (COFFEE_TURKISH_REFERENTS[cls] ?? []).filter(
    (r) => (!r.requiresToken || tokens.has(r.requiresToken)) && (!r.requiresContext || contexts.has(r.requiresContext)),
  );
  /** Words that name BOTH components of a relation present in this plan. */
  const jointWords = (cls: string) => (COFFEE_TURKISH_REFERENTS[cls] ?? []).filter((r) => r.jointUnder?.some((rel) => relations.has(rel))).map((r) => r.text);

  const ownerOf = (cls: string) => beats.flatMap((b) => b.groups).find((g) => g.cls === cls)?.about ?? cls;
  /**
   * W4C.1: a tempo pair (A, B) binds an elaboration of B about owner O when a
   * relation beat carries O together with A (or A's owner): O's entity nouns
   * may then already carry A's tempo, so B must use a facet referent.
   */
  const tempoBound = (elaborated: string[], owner: string) =>
    COFFEE_TURKISH_TEMPO_PAIRS.some((t) => t.classes.some((b, i) => {
      const a = t.classes[1 - i];
      return elaborated.includes(b) && planClasses.has(a) && beats.some((rb) => rb.relation
        && rb.groups.some((g) => g.cls === owner) && rb.groups.some((g) => g.cls === a || g.cls === ownerOf(a)));
    }));

  const realizedBeats: CoffeeM2BeatRealization[] = beats.map((beat, index) => {
    const domain = beat.qualifiers.domain?.domain ?? firstDomain;
    const groupRoles = beat.groups
      .filter((g) => g.kind !== 'scenario')
      .map((g) => ({
        cls: g.cls,
        roles: g.about ? ELABORATION_ROLES : beat.relation ? RELATION_ROLES : CORE_ROLES,
      }));

    const scenarioRoles = beat.scenario
      ? beat.scenario.placement === 'own_beat'
        ? { roles: ['scenario'] as CoffeeTurkishSurfaceRole[], leadAsSoleRealization: false }
        : { roles: ['lead', 'scenario'] as CoffeeTurkishSurfaceRole[], leadAsSoleRealization: true }
      : null;

    // Referent: elaborations and own-beat scenarios refer back to exactly one owned class.
    // (A beat that states the owned core itself refers back to nothing.)
    const elaborated = beat.groups.find((g) => g.about && !beat.groups.some((c) => c.cls === g.about))?.about ?? null;
    const aboutClass = elaborated ?? (beat.scenario?.placement === 'own_beat' ? beat.scenario.realizes : null);
    let referent: CoffeeM2BeatRealization['referent'] = null;
    if (aboutClass) {
      const joint = jointWords(aboutClass);
      // Referents of OTHER classes in the plan would bleed another independent group in.
      const others = [...planClasses].filter((c) => c !== aboutClass).flatMap((c) => (COFFEE_TURKISH_REFERENTS[c] ?? []).map((r) => r.text));
      const elaboratedClasses = beat.groups.filter((g) => g.about === aboutClass).map((g) => g.cls);
      if (elaborated && tempoBound(elaboratedClasses, aboutClass)) {
        const facet = elaboratedClasses.flatMap((c) => COFFEE_TURKISH_FACET_REFERENTS[c]?.[aboutClass] ?? []);
        const entity = (COFFEE_TURKISH_REFERENTS[aboutClass] ?? []).map((r) => r.text);
        referent = {
          aboutClass,
          kind: 'facet',
          referents: [...facet],
          forbiddenReferents: [...new Set([...joint, ...entity, ...others])],
          forbiddenEntityNouns: [...(COFFEE_TURKISH_ENTITY_NOUNS[aboutClass] ?? [])],
          lexicalSubjectRequired: facet.length === 0,
        };
      } else {
        const own = usable(aboutClass).map((r) => r.text).filter((t) => !joint.includes(t));
        referent = {
          aboutClass,
          kind: 'entity',
          referents: own,
          forbiddenReferents: [...new Set([...joint, ...others])],
          forbiddenEntityNouns: [],
          lexicalSubjectRequired: own.length === 0,
        };
      }
    }

    // Overlap restrictions bound to the classes this beat carries.
    const overlap: CoffeeM2BeatRealization['overlap'] = [];
    for (const o of COFFEE_TURKISH_SURFACE_OVERLAPS) {
      for (const cls of o.classes) {
        const other = o.classes.find((c) => c !== cls)!;
        if (beat.groups.some((g) => g.cls === cls) && planClasses.has(other)) {
          overlap.push({ cls, with: other, useOnly: [...o.distinct[cls]], neverUse: [...o.distinct[other]] });
        }
      }
    }

    // Domain idiom wording.
    const domainWording: Record<string, string[]> = {};
    const avoidWording: string[] = [];
    const surface = domain ? COFFEE_TURKISH_DOMAIN_SURFACE[domain] : undefined;
    for (const g of beat.groups) {
      const row = surface?.[g.cls];
      if (row) {
        domainWording[g.cls] = [...row.forms];
        avoidWording.push(...row.avoid);
      }
    }
    if (beat.groups.some((g) => surface?.[g.cls])) {
      // Overlap "useOnly" wording that the domain marks as unidiomatic is dropped there (never semantics).
      for (const o of overlap) {
        const avoid = surface?.[o.cls]?.avoid ?? [];
        const kept = o.useOnly.filter((t) => !avoid.some((a) => foldTr(t).includes(foldTr(a))));
        o.useOnly = kept.length ? kept : [...(surface?.[o.cls]?.forms ?? o.useOnly)];
        if (surface?.[o.cls]) o.useOnly = [...new Set([...o.useOnly, ...surface[o.cls].forms])];
      }
    }

    // The other class's domain-idiom wording is equally off-limits for this class.
    for (const o of overlap) {
      const otherForms = surface?.[o.with]?.forms ?? [];
      o.neverUse = [...new Set([...o.neverUse, ...otherForms])];
    }

    const manifestations = beat.scenario?.manifestations ?? [];
    const scenarioIncompatiblePairs = COFFEE_TURKISH_SCENARIO_INCOMPATIBLE_PAIRS
      .filter((p) => p.pair.every((m) => manifestations.includes(m)))
      .map((p) => [...p.pair]);

    return {
      order: index + 1,
      groupRoles,
      scenarioRoles,
      referent,
      overlap,
      domainWording,
      avoidWording: [...new Set(avoidWording)],
      scenarioIncompatiblePairs,
      finitePredicateRequired: true as const,
      avoidStackedNominalization: true as const,
      avoidSameOpenerAsPrevious: index > 0,
    };
  });

  // Tempo pairs present in this plan: each class keeps its own referent; joint words are never shared.
  const beatReferentOf = (cls: string) =>
    realizedBeats.find((rb) => rb.referent && beats[rb.order - 1].groups.some((g) => g.cls === cls))?.referent ?? null;
  const tempo = COFFEE_TURKISH_TEMPO_PAIRS
    .filter((t) => t.classes.every((c) => planClasses.has(c)))
    .map((t) => ({
      classes: [...t.classes],
      note: t.note,
      separateReferents: Object.fromEntries(t.classes.map((c) => {
        const bound = beatReferentOf(c);
        if (bound) return [c, [...bound.referents]];
        const owner = ownerOf(c);
        const joint = jointWords(owner);
        return [c, usable(owner).map((r) => r.text).filter((x) => !joint.includes(x))];
      })),
      neverShared: [...new Set(t.classes.flatMap((c) => {
        const bound = beatReferentOf(c);
        const facetEntity = bound?.kind === 'facet' ? (COFFEE_TURKISH_REFERENTS[bound.aboutClass] ?? []).map((r) => r.text) : [];
        return [...jointWords(ownerOf(c)), ...facetEntity];
      }))],
    }));
  // A tempo pair also forbids the joint words on the elaboration beats it touches.
  for (const t of tempo) {
    for (const rb of realizedBeats) {
      if (rb.referent && t.classes.some((c) => beats[rb.order - 1].groups.some((g) => g.cls === c))) {
        rb.referent.forbiddenReferents = [...new Set([...rb.referent.forbiddenReferents, ...t.neverShared])];
      }
    }
  }

  const result: CoffeeM2TurkishRealizationPayload = {
    ...payload,
    realization: {
      beats: realizedBeats,
      crossBeat: {
        noIdenticalAdjacentOpener: true,
        demonstrativeOpenerMax: beats.length >= 3 ? beats.length - 1 : beats.length,
        tempo,
      },
    },
  };
  assertCoffeeV3MeaningOnly(result);
  return result;
}

/** Demonstrative check used by the opener policy (exported for QA). */
export const coffeeTurkishIsDemonstrativeOpener = isDemonstrative;
