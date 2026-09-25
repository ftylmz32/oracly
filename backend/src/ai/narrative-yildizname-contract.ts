/** Phase 5 — strict Yıldızname natal narrative request wire validation. */
import { ErrorCode, fail } from '../errors.js';
import { asRecord } from './sanitize.js';
import {
  asEnumSet,
  YILDIZNAME_ANGLE_KINDS,
  YILDIZNAME_BODIES,
  YILDIZNAME_CONTRACT_VERSION,
  YILDIZNAME_FIDELITIES,
  YILDIZNAME_HOUSE_SYSTEMS,
  YILDIZNAME_LIMITS,
  YILDIZNAME_MODE,
  YILDIZNAME_NARRATIVE_VERSION,
  YILDIZNAME_OMITTED_LAYERS,
  YILDIZNAME_POLICY_RULES,
  YILDIZNAME_POLICY_VERSION,
  YILDIZNAME_SCOPES,
  YILDIZNAME_SERIALIZER_VERSION,
} from './narrative-yildizname-limits.js';
import {
  requireAngleFactRef,
  requireAspectFactRef,
  requireAspectType,
  requireBalanceFactRef,
  requireBody,
  requireCertainty,
  requireDegreeWithinSign,
  requireEnum,
  requireHouseFactRef,
  requireHouseNumber,
  requireOrb,
  requirePlacementFactRef,
  requireSign,
  requireString,
  requireThemeRef,
} from './narrative-yildizname-contract-fields.js';

export type YildiznameWireLanguage = 'tr' | 'en' | 'ru';
export type YildiznameScope = (typeof YILDIZNAME_SCOPES)[number];
export type YildiznameFidelity = (typeof YILDIZNAME_FIDELITIES)[number];

export type YildiznameWireNarrative = {
  version: number;
  serializerVersion: number;
  languageCode: YildiznameWireLanguage;
  scope: YildiznameScope;
  fidelity: YildiznameFidelity;
  houseSystem?: string;
  placements: Record<string, unknown>[];
  angles: Record<string, unknown>[];
  houses: Record<string, unknown>[];
  aspects: Record<string, unknown>[];
  balances: Record<string, unknown>[];
  discoveryThemes: Record<string, unknown>[];
  omittedLayers: string[];
  policy: { version: string; rules: string[] };
  calculationVersion?: string;
};

export type YildiznameNarrativeValidated = {
  operation: 'yildizname_reading';
  mode: 'natal_narrative_v1';
  contractVersion: 1;
  language: YildiznameWireLanguage;
  narrative: YildiznameWireNarrative;
};

const TOP_KEYS = new Set(['mode', 'contractVersion', 'language', 'narrative']);
const NARRATIVE_KEYS = new Set([
  'version',
  'serializerVersion',
  'languageCode',
  'scope',
  'fidelity',
  'houseSystem',
  'placements',
  'angles',
  'houses',
  'aspects',
  'balances',
  'discoveryThemes',
  'omittedLayers',
  'policy',
  'calculationVersion',
]);

const FORBIDDEN = new Set([
  'ownerId',
  'owner',
  'userId',
  'user_id',
  'uid',
  'sub',
  'firebaseUid',
  'latitude',
  'longitude',
  'cuspLongitude',
  'timezoneId',
  'timezone',
  'birthTime',
  'birthDate',
  'birthPlace',
  'utcInstant',
  'sourceId',
  'rawProfile',
  'storageKey',
  'artifactId',
  'sessionId',
  'readingId',
  'evidenceId',
  'provenance',
  'transits',
  'transit',
]);

const SCOPES = asEnumSet(YILDIZNAME_SCOPES);
const FIDELITIES = asEnumSet(YILDIZNAME_FIDELITIES);
const ANGLE_KINDS = asEnumSet(YILDIZNAME_ANGLE_KINDS);
const HOUSE_SYSTEMS = asEnumSet(YILDIZNAME_HOUSE_SYSTEMS);
const OMITTED = asEnumSet(YILDIZNAME_OMITTED_LAYERS);
const BODIES = asEnumSet(YILDIZNAME_BODIES);

function reject(): never {
  fail(ErrorCode.invalidRequest);
}

function exactKeys(obj: Record<string, unknown>, allowed: Set<string>): void {
  for (const k of Object.keys(obj)) {
    if (!allowed.has(k) || FORBIDDEN.has(k)) reject();
  }
}

function scanForbidden(value: unknown): void {
  if (Array.isArray(value)) {
    for (const v of value) scanForbidden(v);
    return;
  }
  const rec = asRecord(value);
  if (!rec) return;
  for (const k of Object.keys(rec)) {
    if (FORBIDDEN.has(k)) reject();
    scanForbidden(rec[k]);
  }
}

function exactLang(v: unknown): YildiznameWireLanguage | null {
  return v === 'tr' || v === 'en' || v === 'ru' ? v : null;
}

export function validateYildiznameNarrativePayload(
  payload: Record<string, unknown>,
): YildiznameNarrativeValidated {
  exactKeys(payload, TOP_KEYS);
  if (payload.mode !== YILDIZNAME_MODE) reject();
  if (payload.contractVersion !== YILDIZNAME_CONTRACT_VERSION) reject();
  const language = exactLang(payload.language);
  if (!language) reject();
  const narrativeRec = asRecord(payload.narrative);
  if (!narrativeRec) reject();
  scanForbidden(narrativeRec);
  exactKeys(narrativeRec, NARRATIVE_KEYS);
  const narrative = parseNarrative(narrativeRec, language);
  const jsonChars = JSON.stringify(narrative).length;
  if (jsonChars > YILDIZNAME_LIMITS.maxNarrativeJsonChars) reject();
  return {
    operation: 'yildizname_reading',
    mode: 'natal_narrative_v1',
    contractVersion: 1,
    language,
    narrative,
  };
}

function parseNarrative(
  n: Record<string, unknown>,
  language: YildiznameWireLanguage,
): YildiznameWireNarrative {
  if (n.version !== YILDIZNAME_NARRATIVE_VERSION) reject();
  if (n.serializerVersion !== YILDIZNAME_SERIALIZER_VERSION) reject();
  if (n.languageCode !== language) reject();
  const scope = requireEnum(reject, n.scope, SCOPES) as YildiznameScope;
  const fidelity = requireEnum(
    reject,
    n.fidelity,
    FIDELITIES,
  ) as YildiznameFidelity;
  assertScopeFidelity(scope, fidelity);

  if (!Array.isArray(n.placements) || !Array.isArray(n.angles)) reject();
  if (!Array.isArray(n.houses) || !Array.isArray(n.aspects)) reject();
  if (!Array.isArray(n.balances) || !Array.isArray(n.discoveryThemes)) {
    reject();
  }
  if (!Array.isArray(n.omittedLayers)) reject();

  const policy = asRecord(n.policy);
  if (!policy) reject();
  parsePolicy(policy);

  const placements = n.placements.map((p) => parsePlacement(p, scope));
  const angles = n.angles.map((a) => parseAngle(a, scope));
  const houses = n.houses.map((h) => parseHouse(h, scope));
  const aspects = n.aspects.map((a) => parseAspect(a, scope));
  const balances = n.balances.map(parseBalance);
  const discoveryThemes = n.discoveryThemes.map(parseTheme);
  if (discoveryThemes.length > YILDIZNAME_LIMITS.maxThemes) reject();
  if (placements.length > YILDIZNAME_LIMITS.maxPlacements) reject();
  if (angles.length > YILDIZNAME_LIMITS.maxAngles) reject();
  if (houses.length > YILDIZNAME_LIMITS.maxHouses) reject();
  if (aspects.length > YILDIZNAME_LIMITS.maxAspects) reject();
  if (balances.length > YILDIZNAME_LIMITS.maxBalances) reject();

  assertUniqueFactRefs([
    ...placements,
    ...angles,
    ...houses,
    ...aspects,
    ...balances,
  ]);
  assertUniqueThemeRefs(discoveryThemes);
  assertPlacementRefs(placements);
  assertAngleRefs(angles);
  assertHouseRefs(houses);
  assertAspectRefs(aspects);

  if (scope !== 'full') {
    if (angles.length > 0 || houses.length > 0 || aspects.length > 0) reject();
  }

  let houseSystem: string | undefined;
  if ('houseSystem' in n && n.houseSystem != null) {
    if (scope !== 'full') reject();
    houseSystem = requireEnum(reject, n.houseSystem, HOUSE_SYSTEMS);
  } else if (scope === 'full' && houses.length > 0) {
    reject();
  }

  const omittedLayers = parseOmitted(n.omittedLayers);
  let calculationVersion: string | undefined;
  if ('calculationVersion' in n && n.calculationVersion != null) {
    calculationVersion = requireString(
      reject,
      n.calculationVersion,
      YILDIZNAME_LIMITS.maxCalculationVersionChars,
      true,
    );
  }

  return {
    version: YILDIZNAME_NARRATIVE_VERSION,
    serializerVersion: YILDIZNAME_SERIALIZER_VERSION,
    languageCode: language,
    scope,
    fidelity,
    ...(houseSystem ? { houseSystem } : {}),
    placements,
    angles,
    houses,
    aspects,
    balances,
    discoveryThemes,
    omittedLayers,
    policy: {
      version: YILDIZNAME_POLICY_VERSION,
      rules: [...YILDIZNAME_POLICY_RULES],
    },
    ...(calculationVersion ? { calculationVersion } : {}),
  };
}

function assertScopeFidelity(
  scope: YildiznameScope,
  fidelity: YildiznameFidelity,
): void {
  if (scope === 'legacy' && fidelity !== 'tropicalSunSign') reject();
  if (scope === 'reduced' && fidelity !== 'reducedNatal') reject();
  if (scope === 'full' && fidelity !== 'fullNatalEphemeris') reject();
}

function parsePolicy(policy: Record<string, unknown>): void {
  exactKeys(policy, new Set(['version', 'rules']));
  if (policy.version !== YILDIZNAME_POLICY_VERSION) reject();
  if (!Array.isArray(policy.rules)) reject();
  if (policy.rules.length !== YILDIZNAME_POLICY_RULES.length) reject();
  for (let i = 0; i < YILDIZNAME_POLICY_RULES.length; i++) {
    if (policy.rules[i] !== YILDIZNAME_POLICY_RULES[i]) reject();
  }
}

const PLACEMENT_KEYS_BASE = new Set([
  'factRef',
  'body',
  'sign',
  'certainty',
]);
const PLACEMENT_KEYS_FULL = new Set([
  ...PLACEMENT_KEYS_BASE,
  'degreeWithinSign',
  'retrograde',
  'house',
]);

function parsePlacement(
  raw: unknown,
  scope: YildiznameScope,
): Record<string, unknown> {
  const p = asRecord(raw);
  if (!p) reject();
  const allowed =
    scope === 'full' ? PLACEMENT_KEYS_FULL : PLACEMENT_KEYS_BASE;
  exactKeys(p, allowed);
  const factRef = requirePlacementFactRef(reject, p.factRef);
  const body = requireBody(reject, p.body);
  if (factRef !== `placement.${body}`) reject();
  requireSign(reject, p.sign);
  const certainty = requireCertainty(reject, p.certainty);
  if (scope === 'reduced' && certainty !== 'intervalStable') reject();
  if (scope === 'legacy' && certainty !== 'exact') reject();
  if (certainty === 'intervalStable' && 'degreeWithinSign' in p) reject();
  if (scope !== 'full') {
    if ('degreeWithinSign' in p || 'retrograde' in p || 'house' in p) reject();
  } else {
    if ('degreeWithinSign' in p) {
      requireDegreeWithinSign(reject, p.degreeWithinSign);
    }
    if ('retrograde' in p && typeof p.retrograde !== 'boolean') reject();
    if ('house' in p) requireHouseNumber(reject, p.house);
  }
  return p;
}

function parseAngle(
  raw: unknown,
  scope: YildiznameScope,
): Record<string, unknown> {
  if (scope !== 'full') reject();
  const a = asRecord(raw);
  if (!a) reject();
  exactKeys(
    a,
    new Set(['factRef', 'kind', 'sign', 'degreeWithinSign', 'house', 'certainty']),
  );
  const factRef = requireAngleFactRef(reject, a.factRef);
  const kind = requireEnum(reject, a.kind, ANGLE_KINDS);
  if (factRef !== `angle.${kind}`) reject();
  requireSign(reject, a.sign);
  requireDegreeWithinSign(reject, a.degreeWithinSign);
  requireHouseNumber(reject, a.house);
  const certainty = requireCertainty(reject, a.certainty);
  if (certainty !== 'exact') reject();
  return a;
}

function parseHouse(
  raw: unknown,
  scope: YildiznameScope,
): Record<string, unknown> {
  if (scope !== 'full') reject();
  const h = asRecord(raw);
  if (!h) reject();
  exactKeys(h, new Set(['factRef', 'number', 'sign']));
  const factRef = requireHouseFactRef(reject, h.factRef);
  const number = requireHouseNumber(reject, h.number);
  if (factRef !== `house.${number}`) reject();
  requireSign(reject, h.sign);
  return h;
}

function parseAspect(
  raw: unknown,
  scope: YildiznameScope,
): Record<string, unknown> {
  if (scope !== 'full') reject();
  const a = asRecord(raw);
  if (!a) reject();
  exactKeys(
    a,
    new Set(['factRef', 'bodyA', 'bodyB', 'type', 'orb', 'certainty']),
  );
  const factRef = requireAspectFactRef(reject, a.factRef);
  const bodyA = requireBody(reject, a.bodyA);
  const bodyB = requireBody(reject, a.bodyB);
  const type = requireAspectType(reject, a.type);
  if (bodyA === bodyB) reject();
  if (factRef !== `aspect.${bodyA}.${bodyB}.${type}`) reject();
  requireOrb(reject, a.orb);
  const certainty = requireCertainty(reject, a.certainty);
  if (certainty !== 'exact') reject();
  return a;
}

function parseBalance(raw: unknown): Record<string, unknown> {
  const b = asRecord(raw);
  if (!b) reject();
  exactKeys(b, new Set(['factRef', 'kind', 'counts', 'dominant']));
  const factRef = requireBalanceFactRef(reject, b.factRef);
  if (b.kind === 'elements') {
    if (factRef !== 'balance.elements') reject();
    const counts = asRecord(b.counts);
    if (!counts) reject();
    exactKeys(counts, new Set(['fire', 'earth', 'air', 'water']));
    for (const k of ['fire', 'earth', 'air', 'water']) {
      if (typeof counts[k] !== 'number' || !Number.isInteger(counts[k])) {
        reject();
      }
      if ((counts[k] as number) < 0) reject();
    }
    requireEnum(
      reject,
      b.dominant,
      new Set(['fire', 'earth', 'air', 'water']),
    );
  } else if (b.kind === 'modalities') {
    if (factRef !== 'balance.modalities') reject();
    const counts = asRecord(b.counts);
    if (!counts) reject();
    exactKeys(counts, new Set(['cardinal', 'fixed', 'mutable']));
    for (const k of ['cardinal', 'fixed', 'mutable']) {
      if (typeof counts[k] !== 'number' || !Number.isInteger(counts[k])) {
        reject();
      }
      if ((counts[k] as number) < 0) reject();
    }
    requireEnum(reject, b.dominant, new Set(['cardinal', 'fixed', 'mutable']));
  } else {
    reject();
  }
  return b;
}

function parseTheme(raw: unknown): Record<string, unknown> {
  const t = asRecord(raw);
  if (!t) reject();
  exactKeys(t, new Set(['themeRef', 'label']));
  requireThemeRef(reject, t.themeRef);
  requireString(reject, t.label, YILDIZNAME_LIMITS.maxLabelChars, true);
  return t;
}

function parseOmitted(raw: unknown[]): string[] {
  if (raw.length > YILDIZNAME_LIMITS.maxOmittedLayers) reject();
  const seen = new Set<string>();
  const out: string[] = [];
  for (const item of raw) {
    const s = requireString(
      reject,
      item,
      YILDIZNAME_LIMITS.maxOmittedLayerChars,
      true,
    );
    if (!OMITTED.has(s) && !BODIES.has(s)) reject();
    if (seen.has(s)) reject();
    seen.add(s);
    out.push(s);
  }
  return out;
}

function assertUniqueFactRefs(facts: Record<string, unknown>[]): void {
  const seen = new Set<string>();
  for (const f of facts) {
    const ref = String(f.factRef);
    if (seen.has(ref)) reject();
    seen.add(ref);
  }
}

function assertUniqueThemeRefs(themes: Record<string, unknown>[]): void {
  const seen = new Set<string>();
  for (const t of themes) {
    const ref = String(t.themeRef);
    if (seen.has(ref)) reject();
    seen.add(ref);
  }
}

function assertPlacementRefs(placements: Record<string, unknown>[]): void {
  for (const p of placements) {
    if (String(p.factRef) !== `placement.${p.body}`) reject();
  }
}

function assertAngleRefs(angles: Record<string, unknown>[]): void {
  for (const a of angles) {
    if (String(a.factRef) !== `angle.${a.kind}`) reject();
  }
}

function assertHouseRefs(houses: Record<string, unknown>[]): void {
  for (const h of houses) {
    if (String(h.factRef) !== `house.${h.number}`) reject();
  }
}

function assertAspectRefs(aspects: Record<string, unknown>[]): void {
  for (const a of aspects) {
    const expected = `aspect.${a.bodyA}.${a.bodyB}.${a.type}`;
    if (String(a.factRef) !== expected) reject();
  }
}
