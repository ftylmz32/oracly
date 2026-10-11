/**
 * LIS2 — dark Coffee V3 processing path, THREE photos (two genuine cup views +
 * one saucer; never a fourth). Every provider call here goes to a
 * FAKE fetch (recorded); zero real OpenAI calls. Exercises the real internal
 * entry (AiProxyService.coffeeV3), the real worker (ReadingProcessor), the
 * real gem route and the real create route.
 */
import { createHash } from 'node:crypto';
import { beforeEach, describe, expect, it } from 'vitest';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { AiProxyService } from '../src/ai/service.js';
import { readingStageStore, createReadingStageStore } from '../src/ai/reading/stage-cache.js';
import {
  COFFEE_V3_MAX_WRITER_COMPLETIONS,
  COFFEE_V3_OBSERVER_STAGE,
  COFFEE_V3_RESULT_CONTRACT,
  COFFEE_V3_STAGED_TO_SEMANTIC_SLOT,
  CoffeeV3TerminalFailure,
  FROZEN_COFFEE_M2_PROMPT_SHA256,
  runCoffeeV3Reading,
} from '../src/ai/reading/coffee-v3-live-pipeline.js';
import { buildCoffeeV3MarkMap } from '../src/ai/reading/coffee-v3-mark-map.js';
import { classifyCoffeeIntention } from '../src/ai/reading/coffee-intention-context.js';
import { interpretCoffeeM2 } from '../src/ai/reading/coffee-m2-semantic-engine.js';
import { planCoffeeM2Writer } from '../src/ai/reading/coffee-m2-writer-beat-plan.js';
import { prepareCoffeeM2TurkishRealization } from '../src/ai/reading/coffee-m2-turkish-realization-policy.js';
import { assembleCoffeeM2PublicReading } from '../src/ai/reading/coffee-m2-turkish-realization-check.js';
import { coffeeM2WriterPromptSha256, coffeeM2WriterSystemPrompt, coffeeM2WriterUserMessage } from '../src/ai/reading/coffee-m2-writer-prompt.js';
import { COFFEE_V3_OBSERVER_SCHEMA } from '../src/ai/reading/schemas.js';
import { coffeeV3ObserverSystem, coffeeV3ObserverUser } from '../src/ai/reading/observer-prompts.js';
import { COFFEE_V3_SLOTS, type CoffeeMultiViewObservationV3 } from '../src/ai/reading/types.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../src/reading/memory-staged-object-store.js';
import { provisionalGemCostPolicy } from '../src/reading/gem-cost-policy.js';
import { GemLedger } from '../src/reading/gem-ledger.js';
import { FirestoreReadingOperationRepository } from '../src/reading/operation-repository.js';
import { ReadingOperationService } from '../src/reading/operation-service.js';
import { FirestoreReadingStagedImageRepository } from '../src/reading/operation-staged-image-repository.js';
import { ReadingStagedImageService } from '../src/reading/operation-staged-image-service.js';
import { FirestoreProviderStageRepository } from '../src/reading/provider-stage-repository.js';
import { ReadingFlow } from '../src/reading/reading-flow.js';
import { NoopReadingCompletionNotifier, ReadingProcessor } from '../src/reading/reading-processor.js';
import { ReadingResultRepository } from '../src/reading/reading-result-repository.js';
import { provisionalWaitPolicy } from '../src/reading/wait-policy.js';
import type { ServerClock } from '../src/reading/clock.js';
import type { OpenAiCompleteOptions } from '../src/ai/openai-transport.js';
import type { AppConfig } from '../src/config.js';
import { c31Spec } from './fixtures/coffee-c31-fixtures.js';
import { m1Observation, type M1FixtureSpec } from './fixtures/coffee-m1-fixtures.js';
import { toThreeViewObservation } from './fixtures/coffee-v3-three-view.js';
import {
  StaticAppCheckVerifier,
  appCheckHeader,
  authHeader,
  fakeJpeg,
  jsonResponse,
  signHs256,
  testApp,
  testConfig,
} from './helpers.js';

class FixedClock implements ServerClock {
  constructor(public ms: number) {}
  now(): Date {
    return new Date(this.ms);
  }
}

const DECISION = 'Bir karar vermem gerekiyor, önümde birkaç seçenek var.';
const STAGED = ['v3_cup_view_a', 'v3_cup_view_b', 'v3_saucer_view'] as const;
const RETIRED_STAGED = ['v3_cup_handle_far', 'v3_cup_turn_a', 'v3_cup_turn_b', 'v3_saucer'] as const;
const W = 'secondary_option_gaining_weight';
const S = 'options_separating';
const R = 'another_option_relevant';
/** A frozen fixture expressed as the live three-photo observation (fixtures themselves untouched). */
const three = (spec: M1FixtureSpec): CoffeeMultiViewObservationV3 => toThreeViewObservation(m1Observation(spec));
const RITAG = (): CoffeeMultiViewObservationV3 => three(c31Spec('C3F-RITAG', { clearAreas: true }));

/** A W4P5-accepted reading for this payload (passes parser, scenario validator and checker). */
const GOOD_BEATS = [
  { id: 'B1', scenarioItems: [] as string[], text: 'Vermen gereken kararda yolun önümüzdeki dönemde adım adım ilerliyor; biraz daha ileride önün de açılıyor.' },
  { id: 'B2', scenarioItems: [W, S], text: 'Yaklaşan dönemde birden fazla yol beliriyor; seçeneklerden biri gözünde ağırlık kazanabilir, hangi yolun ne olduğu da daha açık seçilebilir.' },
];
const GOOD = JSON.stringify({ beats: GOOD_BEATS });
const PARSER_FAIL = 'this is not json';
const SCENARIO_FAIL = JSON.stringify({ beats: [GOOD_BEATS[0], { ...GOOD_BEATS[1], scenarioItems: [W] }] });
const CHECKER_FAIL = JSON.stringify({
  beats: [
    { id: 'B1', scenarioItems: [], text: 'Vermen gereken kararda yolun önümüzdeki dönemde adım adım ilerliyor; önün de biraz daha ileride açılıyor.' },
    { id: 'B2', scenarioItems: [W, S], text: 'Yaklaşan dönemde birkaç ayrı ihtimale açılıyor; seçeneklerden biri gözünde ağırlık kazanabilir ve seçenekler arasındaki fark daha net görünebilir.' },
  ],
});

// ---------------------------------------------------------------------------
// Fake transport (module level) and fake fetch (service / worker level)
// ---------------------------------------------------------------------------

function fakeTransport(observation: unknown, writer: string[]) {
  const calls: OpenAiCompleteOptions[] = [];
  const queue = [...writer];
  return {
    calls,
    observerCalls: () => calls.filter((c) => c.jsonSchema?.name === 'coffee_v3_observation'),
    writerCalls: () => calls.filter((c) => c.jsonMode === true),
    transport: {
      async complete(options: OpenAiCompleteOptions): Promise<string> {
        calls.push(options);
        if (options.jsonSchema?.name === 'coffee_v3_observation') return typeof observation === 'string' ? observation : JSON.stringify(observation);
        const next = queue.shift();
        if (next === undefined) throw new Error('unexpected_extra_writer_call');
        return next;
      },
    },
  };
}

function fakeFetch(observation: unknown, writer: string[]) {
  const bodies: Array<Record<string, unknown>> = [];
  const queue = [...writer];
  const fetchImpl = async (_url: unknown, init?: RequestInit) => {
    const body = JSON.parse(String(init?.body ?? '{}')) as Record<string, unknown>;
    bodies.push(body);
    const schema = (body.response_format as { json_schema?: { name?: string } } | undefined)?.json_schema?.name;
    const content = schema === 'coffee_v3_observation' ? JSON.stringify(observation) : queue.shift();
    if (content === undefined) throw new Error('unexpected_extra_provider_call');
    return jsonResponse({ choices: [{ message: { content } }] });
  };
  return { fetchImpl, bodies, writerCalls: () => bodies.filter((b) => (b.response_format as { type?: string } | undefined)?.type === 'json_object') };
}

const images = () => STAGED.map((slot, i) => ({ slot, mimeType: 'image/jpeg', bytes: fakeJpeg(20_000 + i * 100) }));

async function run(observation: unknown, writer: string[], opts: { config?: AppConfig; intention?: string; language?: 'tr' | 'en' | 'ru'; expectedPromptSha256?: string; stageStore?: ReturnType<typeof createReadingStageStore> } = {}) {
  const fake = fakeTransport(observation, writer);
  let result: unknown = null;
  let error: unknown = null;
  try {
    result = await runCoffeeV3Reading({
      config: opts.config ?? testConfig(),
      transport: fake.transport,
      stageStore: opts.stageStore ?? createReadingStageStore(),
      images: images(),
      intention: opts.intention ?? DECISION,
      language: opts.language ?? 'tr',
      identity: 'owner-a',
      parentKey: 'reading-operation:test',
      ...(opts.expectedPromptSha256 ? { expectedPromptSha256: opts.expectedPromptSha256 } : {}),
    });
  } catch (e) {
    error = e;
  }
  return { ...fake, result: result as Record<string, unknown> | null, error };
}
const failure = (error: unknown) => (error instanceof CoffeeV3TerminalFailure ? `${error.failureCode}:${error.reason}` : String(error));

beforeEach(() => readingStageStore.clear());

// ---------------------------------------------------------------------------

describe('LIS2 V3 observer (A–J)', () => {
  it('A–F: one observer call, exactly three images (two cup + saucer) in canonical order, each after its label, schema, configured vision model', async () => {
    const r = await run(RITAG(), [GOOD]);
    expect(r.error).toBeNull();
    const obs = r.observerCalls();
    expect(obs).toHaveLength(1);
    expect(obs[0].jsonSchema).toEqual({ name: 'coffee_v3_observation', schema: COFFEE_V3_OBSERVER_SCHEMA });
    expect(obs[0].model).toBe(testConfig().openaiReadingVisionModel);
    expect(obs[0].reasoningEffort).toBe('low');
    expect(obs[0].temperature).toBeUndefined();
    const parts = (obs[0].messages[1].content as Array<{ type: string; text?: string }>);
    expect(parts.filter((p) => p.type === 'image_url')).toHaveLength(3);
    const labels = parts.filter((p, i) => p.type === 'text' && parts[i + 1]?.type === 'image_url').map((p) => p.text!.split(' — ')[1].split('.')[0]);
    expect(labels).toEqual(['CUP_VIEW_A', 'CUP_VIEW_B', 'SAUCER']);
    // Three DIFFERENT images, never a duplicated or synthetic view.
    const urls = parts.filter((p) => p.type === 'image_url').map((p) => (p as unknown as { image_url: { url: string } }).image_url.url);
    expect(new Set(urls).size).toBe(3);
    expect(Object.keys(COFFEE_V3_STAGED_TO_SEMANTIC_SLOT)).toEqual([...STAGED]);
    expect(Object.values(COFFEE_V3_STAGED_TO_SEMANTIC_SLOT)).toEqual(['cup_view_a', 'cup_view_b', 'saucer']);
    expect([...COFFEE_V3_SLOTS]).toEqual(['cup_view_a', 'cup_view_b', 'saucer']);
  });

  it('the observer contract itself is three-view: schema slots, view count and prompts', () => {
    const view = COFFEE_V3_OBSERVER_SCHEMA.properties.views;
    expect(view).toMatchObject({ minItems: 3, maxItems: 3 });
    expect(view.items.properties.slot.enum).toEqual(['cup_view_a', 'cup_view_b', 'saucer']);
    expect(COFFEE_V3_OBSERVER_SCHEMA.properties.sightings.items.properties.slot.enum).toEqual(['cup_view_a', 'cup_view_b', 'saucer']);
    expect(coffeeV3ObserverSystem()).toContain('two photographs of the inside of the SAME cup');
    expect(coffeeV3ObserverSystem()).toContain('two cup photos');
    expect(coffeeV3ObserverSystem()).not.toMatch(/three photographs of the inside|three cup photos|four/i);
    expect(coffeeV3ObserverUser()).toContain('three photographs');
    expect(coffeeV3ObserverUser()).not.toMatch(/four/i);
  });

  it('staged input must be exactly the three live views: four, retired, duplicated or missing views never reach a provider', async () => {
    const base = images();
    const cases = [
      [...base, { slot: 'v3_cup_view_a' as never, mimeType: 'image/jpeg', bytes: fakeJpeg(29_000) }],
      base.slice(0, 2),
      [base[0], { ...base[1], slot: 'v3_cup_view_a' as never }, base[2]],
      RETIRED_STAGED.map((slot, i) => ({ slot: slot as never, mimeType: 'image/jpeg', bytes: fakeJpeg(21_000 + i) })),
    ];
    for (const input of cases) {
      const fake = fakeTransport(RITAG(), [GOOD]);
      const err = await runCoffeeV3Reading({
        config: testConfig(), transport: fake.transport, stageStore: createReadingStageStore(), images: input,
        intention: DECISION, language: 'tr', identity: 'owner-a', parentKey: 'p',
      }).catch((e) => e);
      expect(failure(err)).toBe('unavailable:staged_views_malformed');
      expect(fake.calls).toHaveLength(0);
    }
  });

  it('G: an unusable observation is terminal invalid with no writer call', async () => {
    const r = await run({ ...RITAG(), usable: false, reason: 'blurred' }, [GOOD]);
    expect(failure(r.error)).toBe('invalid:observer_unusable');
    expect(r.writerCalls()).toHaveLength(0);
    const blurred = RITAG();
    blurred.views = blurred.views.map((v, i) => (i === 2 ? { ...v, focusLightAdequate: false } : v));
    expect(failure((await run(blurred, [GOOD])).error)).toBe('invalid:photo_quality');
  });

  it('H: a structurally invalid map is terminal unavailable with no writer call', async () => {
    const broken = RITAG();
    broken.marks[0] = { ...broken.marks[0], sightingIds: ['no-such-sighting'] };
    expect(buildCoffeeV3MarkMap(broken).status).toBe('invalid');
    const r = await run(broken, [GOOD]);
    expect(failure(r.error)).toMatch(/^unavailable:map_invalid:/);
    expect(r.writerCalls()).toHaveLength(0);
    // Malformed views or JSON are also provider defects.
    const views = RITAG();
    views.views = views.views.slice(0, 2);
    expect(failure((await run(views, [GOOD])).error)).toBe('unavailable:observer_views_malformed');
    // A phantom fourth view, a duplicated view, or the retired four-view labels are provider defects too.
    const phantom = RITAG();
    phantom.views = [...phantom.views, { ...phantom.views[1], slot: 'cup_turn_b' }];
    expect(failure((await run(phantom, [GOOD])).error)).toBe('unavailable:observer_views_malformed');
    const duplicated = RITAG();
    duplicated.views = [duplicated.views[0], { ...duplicated.views[0] }, duplicated.views[2]];
    expect(failure((await run(duplicated, [GOOD])).error)).toBe('unavailable:observer_views_malformed');
    expect(failure((await run(m1Observation(c31Spec('C3F-RITAG', { clearAreas: true })), [GOOD])).error)).toBe('unavailable:observer_views_malformed');
    // A sighting on a view that was never photographed is rejected by the map.
    const ghost = RITAG();
    ghost.sightings = ghost.sightings.map((s, i) => (i === 0 ? { ...s, slot: 'cup_turn_a' } : s));
    expect(failure((await run(ghost, [GOOD])).error)).toBe('unavailable:map_invalid:unknown_view');
    expect(failure((await run('{not json', [GOOD])).error)).toBe('unavailable:observer_malformed_json');
    expect(failure((await run({ ...RITAG(), contract: 'other' }, [GOOD])).error)).toBe('unavailable:observer_wrong_contract');
  });

  it('I/M: a sparse cup is never padded — no marks is an honest insufficient (invalid), writer 0', async () => {
    const sparse = three({ marks: [] });
    expect(sparse.marks).toHaveLength(0);
    const r = await run(sparse, [GOOD]);
    expect(failure(r.error)).toBe('invalid:m2_insufficient');
    expect(r.writerCalls()).toHaveLength(0);
  });

  it('J: the observer cache key is isolated and reused within the same operation key', async () => {
    const store = createReadingStageStore();
    await run(RITAG(), [GOOD], { stageStore: store });
    expect(store.get('owner-a', 'reading-operation:test', COFFEE_V3_OBSERVER_STAGE)).not.toBeNull();
    for (const other of ['coffee_observer', 'coffee_v2_observer']) expect(store.get('owner-a', 'reading-operation:test', other)).toBeNull();
    const again = await run(RITAG(), [GOOD], { stageStore: store });
    expect(again.observerCalls()).toHaveLength(0);
    expect(again.error).toBeNull();
  });
});

describe('three-view geometry: two real cup views are merged only on handle-anchored agreement', () => {
  const form = { motion: 'unknown', verticalDirection: 'unknown', openness: 'unknown', course: 'unknown', posture: 'unknown', continuity: 'unknown', grouping: 'unknown' } as const;
  const obs = (rimB: number): CoffeeMultiViewObservationV3 => ({
    contract: 'multi_view_marks_v3',
    usable: true,
    reason: null,
    views: [
      { slot: 'cup_view_a', surfaceVisible: true, focusLightAdequate: true, residueVisible: true, handleVisible: true, handleClock: 12 },
      { slot: 'cup_view_b', surfaceVisible: true, focusLightAdequate: true, residueVisible: true, handleVisible: true, handleClock: 6 },
      { slot: 'saucer', surfaceVisible: true, focusLightAdequate: true, residueVisible: false, handleVisible: null, handleClock: null },
    ],
    sightings: [
      { id: 'a1', slot: 'cup_view_a', surface: 'cup_wall', band: 'middle', rimClock: 3, saucerZone: null, bandCoverage: ['middle'], description: 'x', visibility: 'clear', confidence: 'high' },
      { id: 'b1', slot: 'cup_view_b', surface: 'cup_wall', band: 'middle', rimClock: rimB, saucerZone: null, bandCoverage: ['middle'], description: 'x', visibility: 'clear', confidence: 'high' },
    ],
    marks: [{ id: 'm1', surface: 'cup_wall', kind: 'residue', topology: 'line', sightingIds: ['a1', 'b1'], form: { ...form }, resemblances: [] }],
    relations: [],
    ambiguities: [],
    saucer: { surfaceState: 'clean', flow: { present: false, direction: 'none' } },
  });

  it('the same mark seen in both cup photos (cup turned half a circle) is one trusted physical mark', () => {
    // View A: handle at 12, mark at 3 → 90° from the handle. View B: handle at 6, mark at 9 → also 90°.
    const built = buildCoffeeV3MarkMap(obs(9));
    if (built.status !== 'ok') throw new Error(built.status);
    expect(built.map.cupMarks).toHaveLength(1);
    expect(built.map.cupMarks[0]).toMatchObject({ identity: 'certain', coverage: { count: 2, slots: ['cup_view_a', 'cup_view_b'] }, handleRelation: 'neutral' });
    expect(built.map.distinctMarkCount).toBe(1);
    expect(built.map.audit.untrustedMergeIds).toEqual([]);
  });

  it('a claimed merge whose handle-anchored angles disagree is split, never invented as certain', () => {
    // View B mark at 3 with the handle at 6 → 270°, i.e. the opposite wall: not the same mark.
    const built = buildCoffeeV3MarkMap(obs(3));
    if (built.status !== 'ok') throw new Error(built.status);
    expect(built.map.audit.untrustedMergeIds).toEqual(['m1']);
    expect(built.map.cupMarks.map((m) => m.identity)).toEqual(['possible_same_mark', 'possible_same_mark']);
    expect(built.map.cupMarks.map((m) => m.coverage.slots)).toEqual([['cup_view_a'], ['cup_view_b']]);
    expect(built.map.distinctMarkCount).toBe(1);
  });

  it('frozen fixtures expressed as three photos build the identical meaning map as their original form', () => {
    for (const spec of [c31Spec('C3F-RITAG', { clearAreas: true }), c31Spec('C3F-UNAL', { clearAreas: true })]) {
      const original = buildCoffeeV3MarkMap(m1Observation(spec));
      const live = buildCoffeeV3MarkMap(toThreeViewObservation(m1Observation(spec)));
      if (original.status !== 'ok' || live.status !== 'ok') throw new Error('fixture');
      const meaning = (map: typeof original.map) => interpretCoffeeM2(map, classifyCoffeeIntention(DECISION)).meaning;
      expect(JSON.stringify(meaning(live.map))).toBe(JSON.stringify(meaning(original.map)));
    }
  });
});

describe('LIS2 frozen semantic bridge and pins (K–T)', () => {
  const expectedUser = (spec: M1FixtureSpec, intention: string) => {
    const built = buildCoffeeV3MarkMap(m1Observation(spec));
    if (built.status !== 'ok') throw new Error('fixture');
    const plan = planCoffeeM2Writer(interpretCoffeeM2(built.map, classifyCoffeeIntention(intention)).meaning).plan;
    return coffeeM2WriterUserMessage(prepareCoffeeM2TurkishRealization(plan));
  };

  it('K/L/O/P/Q: the writer receives exactly the frozen chain\'s payload for the trusted intention', async () => {
    const r = await run(RITAG(), [GOOD]);
    expect(r.writerCalls()[0].messages[1].content).toBe(expectedUser(c31Spec('C3F-RITAG', { clearAreas: true }), DECISION));
    expect(r.writerCalls()[0].messages[0].content).toBe(coffeeM2WriterSystemPrompt());
    expect(String(r.writerCalls()[0].messages[1].content)).toContain('user_decision');
    expect(coffeeM2WriterPromptSha256()).toBe(FROZEN_COFFEE_M2_PROMPT_SHA256);
    expect(FROZEN_COFFEE_M2_PROMPT_SHA256).toBe('bc1b618baa26e2e113e995cc3c02f9e09e5e40d844e6c6b35c6880f599cc9e48');
  });

  it('N: an insufficient W2 plan never reaches the writer (with frozen M2 it coincides with M2 insufficient)', async () => {
    const r = await run(three(c31Spec('C3F-UNAL', { clearAreas: true })), [GOOD], { intention: 'Önümüzdeki dönem genel olarak' });
    expect(failure(r.error)).toMatch(/^invalid:(m2|w2)_insufficient$/);
    expect(r.writerCalls()).toHaveLength(0);
  });

  it('R/S/T: a wrong prompt hash, writer model or reasoning fails closed before ANY provider call', async () => {
    const wrongHash = await run(RITAG(), [GOOD], { expectedPromptSha256: '0'.repeat(64) });
    expect(failure(wrongHash.error)).toBe('unavailable:prompt_hash_mismatch');
    const wrongModel = await run(RITAG(), [GOOD], { config: testConfig({ OPENAI_READING_WRITER_MODEL: 'gpt-4o' }) });
    expect(failure(wrongModel.error)).toBe('unavailable:writer_model_mismatch');
    const wrongReasoning = await run(RITAG(), [GOOD], { config: testConfig({ OPENAI_READING_REASONING_EFFORT: 'medium' }) });
    expect(failure(wrongReasoning.error)).toBe('unavailable:writer_reasoning_mismatch');
    const notAllowed = await run(RITAG(), [GOOD], { config: testConfig({ OPENAI_ALLOWED_MODELS: 'gpt-4o,gpt-4o-mini' }) });
    expect(failure(notAllowed.error)).toBe('unavailable:writer_model_mismatch');
    for (const r of [wrongHash, wrongModel, wrongReasoning, notAllowed]) expect(r.calls).toHaveLength(0);
  });

  it('Turkish only: EN / RU operations never reach a provider', async () => {
    for (const language of ['en', 'ru'] as const) {
      const r = await run(RITAG(), [GOOD], { language });
      expect(failure(r.error)).toBe('unavailable:language_not_supported');
      expect(r.calls).toHaveLength(0);
    }
  });
});

describe('LIS2 writer gates and the single blind re-sample (U–AA)', () => {
  it('U: a first completion that passes every gate succeeds with one writer call', async () => {
    const r = await run(RITAG(), [GOOD]);
    expect(r.error).toBeNull();
    expect(r.writerCalls()).toHaveLength(1);
  });

  for (const [label, first] of [['V parser', PARSER_FAIL], ['W scenario', SCENARIO_FAIL], ['X checker', CHECKER_FAIL]] as const) {
    it(`${label} failure on the first completion, pass on the second: two writer calls, success`, async () => {
      const r = await run(RITAG(), [first, GOOD]);
      expect(r.error).toBeNull();
      expect(r.writerCalls()).toHaveLength(2);
      expect(r.result!.overall).toBe(assembleCoffeeM2PublicReading(GOOD_BEATS));
    });
  }

  it('Y/Z: two gate failures are terminal unavailable — exactly two writer calls, never a third, no result', async () => {
    const r = await run(RITAG(), [CHECKER_FAIL, SCENARIO_FAIL, GOOD]);
    expect(failure(r.error)).toBe('unavailable:writer_gates_failed');
    expect(r.writerCalls()).toHaveLength(COFFEE_V3_MAX_WRITER_COMPLETIONS);
    expect(r.result).toBeNull();
  });

  it('AA: the re-sample request is byte-identical (no feedback, no prior output, same model / reasoning / jsonMode)', async () => {
    const r = await run(RITAG(), [PARSER_FAIL, GOOD]);
    const [a, b] = r.writerCalls();
    expect(JSON.stringify(b)).toBe(JSON.stringify(a));
    expect(a).toMatchObject({ model: 'gpt-5.6-sol', reasoningEffort: 'low', jsonMode: true });
    expect(a.temperature).toBeUndefined();
    expect(a.jsonSchema).toBeUndefined();
    expect(a.messages).toHaveLength(2);
  });

  it('transport errors propagate untouched (owned by the provider-stage machinery, no in-pipeline retry)', async () => {
    const fake = fakeTransport(RITAG(), []);
    const err = await runCoffeeV3Reading({
      config: testConfig(), transport: fake.transport, stageStore: createReadingStageStore(), images: images(),
      intention: DECISION, language: 'tr', identity: 'owner-a', parentKey: 'p',
    }).catch((e) => e);
    expect(err).not.toBeInstanceOf(CoffeeV3TerminalFailure);
    expect(String(err)).toContain('unexpected_extra_writer_call');
    expect(fake.writerCalls()).toHaveLength(1);
  });
});

describe('LIS2 result contract (AB–AI)', () => {
  it('AB–AF: m2_public_v1, empty visual and legacy lanes, overall is exactly the assembled gated reading', async () => {
    const r = await run(RITAG(), [GOOD]);
    expect(r.result).toEqual({
      coffeeResultContract: COFFEE_V3_RESULT_CONTRACT,
      visualObservation: '',
      overall: assembleCoffeeM2PublicReading(GOOD_BEATS),
      love: '',
      career: '',
      money: '',
      nearFuture: '',
      takeaway: '',
      symbols: [],
    });
    expect(COFFEE_V3_RESULT_CONTRACT).toBe('m2_public_v1');
  });

  it('AG/AH/AI: no observer evidence, QA metadata or audit leaks into the result', async () => {
    const raw = JSON.stringify((await run(RITAG(), [GOOD])).result);
    expect(raw).not.toMatch(/scenarioItems|sighting|resemblance|marks|evidence|diagnostics|audit|realization|wording|beats|secondary_option|options_separating|fincan|telve/);
  });
});

// ---------------------------------------------------------------------------
// Worker, economy, gem acceleration and create gate (real services, fake fetch)
// ---------------------------------------------------------------------------

function worker(writer: string[], observation: unknown = RITAG()) {
  const store = new MemoryDocumentStore();
  const clock = new FixedClock(Date.parse('2026-10-10T00:00:00.000Z'));
  const policy = provisionalWaitPolicy({ coffee: 1000, palm: 1000, soulmate: 1000 });
  const operationRepository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(operationRepository, clock, policy);
  const stagedRepository = new FirestoreReadingStagedImageRepository(store);
  const objects = new MemoryStagedObjectStore();
  const config = testConfig();
  const stagedImages = new ReadingStagedImageService(stagedRepository, objects, operations, clock, config);
  const ledger = new GemLedger(store, clock, provisionalGemCostPolicy({ coffee: 10, palm: 15, soulmate: 20 }));
  const flow = new ReadingFlow(store, clock, operations, ledger);
  const results = new ReadingResultRepository(store);
  const providerStages = new FirestoreProviderStageRepository(store);
  const fake = fakeFetch(observation, writer);
  const ai = new AiProxyService(config, fake.fetchImpl, stagedImages);
  let handleCalls = 0;
  const spyAi = {
    handle: (...args: Parameters<AiProxyService['handle']>) => {
      handleCalls += 1;
      return ai.handle(...args);
    },
    coffeeV3: (input: Parameters<AiProxyService['coffeeV3']>[0]) => ai.coffeeV3(input),
  };
  const processor = new ReadingProcessor(operationRepository, flow, stagedRepository, stagedImages, results, spyAi, clock, new NoopReadingCompletionNotifier(), false, providerStages);
  const owner = identityKeyFromSubject('lis2-owner');
  let hasAnyV2Calls = 0;
  const originalHasAny = stagedImages.hasAnyCoffeeV2Slot.bind(stagedImages);
  stagedImages.hasAnyCoffeeV2Slot = async (input) => {
    hasAnyV2Calls += 1;
    return originalHasAny(input);
  };
  async function v3Op(tag: string) {
    const op = await operations.create({ ownerUserId: owner, readingType: 'coffee', sourceRequestId: `lis2-${tag}`, coffeeInputContract: 'trusted_intention_v1', coffeeIntention: DECISION, coffeeCaptureContract: 'three_view_v3' });
    await flow.remember(op);
    return op;
  }
  /** A persisted pre-decision 'four_view_v3' operation with its four retired views staged. */
  async function retiredOp(tag: string) {
    const created = await v3Op(tag);
    const op = await operationRepository.mutate(created.operationId, owner, (r) => ({ ...r, coffeeCaptureContract: 'four_view_v3' }));
    for (const [i, slot] of RETIRED_STAGED.entries()) {
      const bytes = fakeJpeg(40_000 + i * 100);
      const objectPath = `reading-staging/coffee/${owner}/${op.operationId}/${slot}.jpg`;
      await stagedRepository.upsert({
        schemaVersion: 1, operationId: op.operationId, ownerUserId: owner, readingType: 'coffee', objectPath,
        contentType: 'image/jpeg', byteSize: bytes.length, checksumSha256: createHash('sha256').update(bytes).digest('hex'),
        uploadState: 'complete', slot, createdAtMs: clock.ms, updatedAtMs: clock.ms,
      });
      await objects.put(objectPath, bytes, 'image/jpeg');
    }
    return op;
  }
  async function stageAll(operationId: string, slots: readonly string[] = STAGED) {
    for (const [i, slot] of slots.entries()) {
      await stagedImages.stage({ ownerUserId: owner, operationId, mimeType: 'image/jpeg', imageBase64: fakeJpeg(20_000 + i * 100).toString('base64'), slot });
    }
  }
  const resultDocs = () => [...store.docs.keys()].filter((k) => k.includes('readingOperationResults/')).length;
  const refunds = () => [...store.docs.values()].filter((d) => (d as { type?: string }).type === 'refund').length;
  return { store, clock, config, operations, operationRepository, stagedRepository, stagedImages, objects, ledger, flow, results, providerStages, fake, processor, owner, v3Op, retiredOp, stageAll, resultDocs, refunds, handleCalls: () => handleCalls, hasAnyV2Calls: () => hasAnyV2Calls };
}

describe('LIS2 worker dispatch and success (AS–BC)', () => {
  it('AS/AT/AX/AY/AZ: three_view_v3 is dispatched by contract (no V2 slot-presence call), persisted once, completed once, V3 views cleaned', async () => {
    const h = worker([GOOD]);
    const op = await h.v3Op('success');
    await h.stageAll(op.operationId);
    h.clock.ms = op.readyAtMs;
    expect(await h.processor.process(op.operationId)).toBe('completed');
    expect(h.hasAnyV2Calls()).toBe(0);
    expect(h.handleCalls()).toBe(0);
    expect(h.fake.bodies).toHaveLength(2); // 1 observer + 1 writer, all fake
    // The one observer request carries exactly the three staged photos.
    const observer = h.fake.bodies.find((b) => JSON.stringify(b).includes('coffee_v3_observation'))!;
    expect(JSON.stringify(observer).match(/data:image\/jpeg;base64,/g)).toHaveLength(3);
    const stored = await h.operationRepository.getById(op.operationId);
    expect(stored).toMatchObject({ status: 'ready', coffeeCaptureContract: 'three_view_v3' });
    expect(h.resultDocs()).toBe(1);
    expect(await h.stagedRepository.listCoffeeV3Slots(op.operationId, h.owner)).toEqual([]);
    expect(h.objects.objects.size).toBe(0);
  });

  it('missing / pending views stay retryable "not ready" with no provider call and no cleanup', async () => {
    const h = worker([GOOD]);
    const op = await h.v3Op('partial');
    await h.stageAll(op.operationId, STAGED.slice(0, 2));
    h.clock.ms = op.readyAtMs;
    await expect(h.processor.process(op.operationId)).rejects.toMatchObject({ retryable: true });
    expect(h.fake.bodies).toHaveLength(0);
    expect(await h.stagedRepository.listCoffeeV3Slots(op.operationId, h.owner)).toHaveLength(2);
    expect((await h.operationRepository.getById(op.operationId))!.status).not.toBe('failed');
  });

  it('BA/BB: a completed or persisted provider checkpoint is replayed without another provider call or a second result', async () => {
    const h = worker([GOOD]);
    const op = await h.v3Op('replay');
    await h.stageAll(op.operationId);
    h.clock.ms = op.readyAtMs;
    expect(await h.processor.process(op.operationId)).toBe('completed');
    const calls = h.fake.bodies.length;
    expect(await h.processor.process(op.operationId)).toBe('noop');
    expect(h.fake.bodies).toHaveLength(calls);
    expect(h.resultDocs()).toBe(1);
  });

  it('BC: an in-flight checkpoint left by a crash is still outcome_unknown → failFinal(unavailable), no provider call', async () => {
    const h = worker([GOOD]);
    const op = await h.v3Op('unknown');
    await h.stageAll(op.operationId);
    h.clock.ms = op.readyAtMs;
    await h.providerStages.claimAttempt(op.operationId, h.owner);
    expect(await h.processor.process(op.operationId)).toBe('failed');
    expect(h.fake.bodies).toHaveLength(0);
    expect(await h.operationRepository.getById(op.operationId)).toMatchObject({ status: 'failed', failureCode: 'unavailable' });
  });

  it('a persisted retired four_view_v3 operation is never processed: no provider call, never V2, refunded terminal, views cleaned', async () => {
    const h = worker([GOOD]);
    await h.ledger.credit({ ownerUserId: h.owner, amount: 40, idempotencyKey: 'seed-credit-retired' });
    const op = await h.retiredOp('retired');
    await h.ledger.accelerate({ ownerUserId: h.owner, operationId: op.operationId, idempotencyKey: 'accelerate-retired' });
    expect(await h.ledger.balanceOf(h.owner)).toBe(30);
    h.clock.ms = Math.max(h.clock.ms, op.readyAtMs);
    expect(await h.processor.process(op.operationId)).toBe('failed');
    expect(h.fake.bodies).toHaveLength(0);
    expect(h.handleCalls()).toBe(0);
    expect(h.hasAnyV2Calls()).toBe(0);
    expect(await h.operationRepository.getById(op.operationId)).toMatchObject({ status: 'failed', failureCode: 'unavailable', coffeeCaptureContract: 'four_view_v3' });
    expect(h.resultDocs()).toBe(0);
    expect(h.refunds()).toBe(1);
    expect(await h.ledger.balanceOf(h.owner)).toBe(40);
    expect(h.objects.objects.size).toBe(0);
    expect(await h.processor.process(op.operationId)).toBe('noop');
    expect(h.refunds()).toBe(1);
  });

  it('AU/AV/AW: null-contract V2, legacy Coffee and Palm still go through the unchanged public handler', async () => {
    const h = worker([]);
    const v2 = await h.operations.create({ ownerUserId: h.owner, readingType: 'coffee', sourceRequestId: 'lis2-v2' });
    await h.flow.remember(v2);
    for (const [i, slot] of ['cup_primary', 'cup_secondary', 'saucer'].entries()) {
      await h.stagedImages.stage({ ownerUserId: h.owner, operationId: v2.operationId, mimeType: 'image/jpeg', imageBase64: fakeJpeg(30_000 + i).toString('base64'), slot });
    }
    h.clock.ms = v2.readyAtMs;
    await h.processor.process(v2.operationId).catch(() => null);
    expect(h.handleCalls()).toBe(1);
    // V2 is still chosen by slot presence: once in the worker, once in the unchanged public handler.
    expect(h.hasAnyV2Calls()).toBe(2);
    expect(h.fake.bodies.some((b) => JSON.stringify(b).includes('coffee_v3_observation'))).toBe(false);
  });
});

describe('LIS2 failure economy (AJ–AR)', () => {
  async function failing(observation: unknown, writer: string[], accelerate: boolean, tag: string) {
    const h = worker(writer, observation);
    await h.ledger.credit({ ownerUserId: h.owner, amount: 40, idempotencyKey: `seed-credit-${tag}` });
    const op = await h.v3Op(tag);
    await h.stageAll(op.operationId);
    if (accelerate) await h.ledger.accelerate({ ownerUserId: h.owner, operationId: op.operationId, idempotencyKey: `accelerate-${tag}` });
    h.clock.ms = Math.max(h.clock.ms, op.readyAtMs);
    const outcome = await h.processor.process(op.operationId);
    return { h, op, outcome, record: (await h.operationRepository.getById(op.operationId))! };
  }

  it('AJ/AP: unusable photos → failFinal(invalid), nothing persisted, no refund invented without a debit', async () => {
    const { h, outcome, record } = await failing({ ...RITAG(), usable: false }, [GOOD], false, 'aj');
    expect(outcome).toBe('failed');
    expect(record).toMatchObject({ status: 'failed', failureCode: 'invalid' });
    expect(h.resultDocs()).toBe(0);
    expect(h.refunds()).toBe(0);
    expect(await h.ledger.balanceOf(h.owner)).toBe(40);
  });

  it('AK: M2 insufficient → failFinal(invalid), no writer call, no persist', async () => {
    const { h, record } = await failing(three({ marks: [] }), [GOOD], false, 'ak');
    expect(record).toMatchObject({ status: 'failed', failureCode: 'invalid' });
    expect(h.fake.writerCalls()).toHaveLength(0);
    expect(h.resultDocs()).toBe(0);
  });

  it('AL: a structurally invalid provider map → failFinal(unavailable)', async () => {
    const broken = RITAG();
    broken.marks[0] = { ...broken.marks[0], sightingIds: ['nope'] };
    const { record, h } = await failing(broken, [GOOD], false, 'al');
    expect(record).toMatchObject({ status: 'failed', failureCode: 'unavailable' });
    expect(h.resultDocs()).toBe(0);
  });

  it('AM/AO: two writer gate failures on an accelerated op → failFinal(unavailable), refund exactly once', async () => {
    const { h, record } = await failing(RITAG(), [CHECKER_FAIL, SCENARIO_FAIL], true, 'am');
    expect(record).toMatchObject({ status: 'failed', failureCode: 'unavailable' });
    expect(h.fake.writerCalls()).toHaveLength(2);
    expect(h.resultDocs()).toBe(0);
    expect(h.refunds()).toBe(1);
    expect(await h.ledger.balanceOf(h.owner)).toBe(40);
  });

  it('AN: an accelerated terminal invalid refunds exactly once', async () => {
    const { h, record } = await failing({ ...RITAG(), usable: false }, [GOOD], true, 'an');
    expect(record).toMatchObject({ status: 'failed', failureCode: 'invalid' });
    expect(h.refunds()).toBe(1);
    expect(await h.ledger.balanceOf(h.owner)).toBe(40);
  });

  it('AQ/AR: terminal failure cleans only V3 views; the failed operation never completes later (retake = new operation)', async () => {
    const { h, op } = await failing({ ...RITAG(), usable: false }, [GOOD], false, 'aq');
    expect(await h.stagedRepository.listCoffeeV3Slots(op.operationId, h.owner)).toEqual([]);
    expect(await h.processor.process(op.operationId)).toBe('noop');
    expect((await h.operationRepository.getById(op.operationId))!.status).toBe('failed');
    expect(h.resultDocs()).toBe(0);
    await expect(h.flow.complete({ ownerUserId: h.owner, operationId: op.operationId, resultId: `coffee_${op.operationId}` })).rejects.toBeTruthy();
  });
});

// ---------------------------------------------------------------------------

const SECRET = 'unit-test-jwt-secret';
const headers = () => ({ ...authHeader(signHs256(SECRET, { sub: 'user-a' })), ...appCheckHeader('good-token') });

describe('LIS2 create gate (BD–BL)', () => {
  async function createApp(enabled: boolean) {
    const store = new MemoryDocumentStore();
    const repository = new FirestoreReadingOperationRepository(store);
    const app = await testApp(
      testConfig({ AI_JWT_SECRET: SECRET, AI_APP_CHECK_REQUIRED: 'true', ...(enabled ? { ORACLY_COFFEE_V3_ENABLED: 'true' } : {}) }),
      async () => { throw new Error('create must not call AI'); },
      { appCheck: new StaticAppCheckVerifier('good-token'), readingOperationRepository: repository, readingClock: new FixedClock(Date.parse('2026-10-10T00:00:00.000Z')), readingWaitPolicy: provisionalWaitPolicy({ coffee: 60_000, palm: 120_000, soulmate: 180_000 }) },
    );
    return { app, store, repository };
  }
  const body = (extra: Record<string, unknown> = {}) => ({ readingType: 'coffee', sourceRequestId: `req-gate-${Math.random().toString(36).slice(2, 10)}`, language: 'tr', coffeeInputContract: 'trusted_intention_v1', intention: DECISION, coffeeCaptureContract: 'three_view_v3', ...extra });

  it('the flag defaults OFF in every environment and only an explicit true turns it on', () => {
    for (const env of ['development', 'staging', 'production']) expect(testConfig({ APP_ENV: env }).coffeeV3CreationEnabled).toBe(false);
    expect(testConfig({ ORACLY_COFFEE_V3_ENABLED: 'maybe' }).coffeeV3CreationEnabled).toBe(false);
    expect(testConfig({ ORACLY_COFFEE_V3_ENABLED: 'true' }).coffeeV3CreationEnabled).toBe(true);
  });

  it('BD: flag off + three_view_v3 → 400 and nothing created', async () => {
    const { app, store } = await createApp(false);
    const before = store.docs.size;
    const res = await app.inject({ method: 'POST', url: '/v1/reading-operations', headers: headers(), payload: body() });
    expect(res.statusCode).toBe(400);
    expect(store.docs.size).toBe(before);
  });

  it('BE: flag on + Turkish + trusted intention → created as a V3 operation', async () => {
    const { app, repository } = await createApp(true);
    const res = await app.inject({ method: 'POST', url: '/v1/reading-operations', headers: headers(), payload: body() });
    expect(res.statusCode).toBe(200);
    expect((await repository.getById(res.json().data.operationId))!.coffeeCaptureContract).toBe('three_view_v3');
  });

  it('BF/BG/BH/BI: flag on but EN, RU, implicit language, missing intention, wrong / retired contract or unknown value → 400', async () => {
    const { app, store } = await createApp(true);
    const before = store.docs.size;
    const { language: _l, ...noLanguage } = body();
    const { intention: _i, coffeeInputContract: _c, ...noIntention } = body();
    for (const payload of [
      body({ language: 'en' }),
      body({ language: 'ru' }),
      noLanguage,
      noIntention,
      body({ coffeeInputContract: 'other' }),
      body({ coffeeCaptureContract: 'three_view' }),
      body({ coffeeCaptureContract: 'four_view_v3' }),
      body({ coffeeCaptureContract: null }),
      body({ readingType: 'palm', intention: undefined, coffeeInputContract: undefined }),
    ]) {
      const res = await app.inject({ method: 'POST', url: '/v1/reading-operations', headers: headers(), payload });
      expect(res.statusCode, JSON.stringify(payload)).toBe(400);
    }
    expect(store.docs.size).toBe(before);
  });

  it('BL: V2 / legacy creates are unaffected by the flag', async () => {
    for (const enabled of [false, true]) {
      const { app } = await createApp(enabled);
      const { coffeeCaptureContract: _x, ...v2 } = body();
      expect((await app.inject({ method: 'POST', url: '/v1/reading-operations', headers: headers(), payload: v2 })).statusCode).toBe(200);
      expect((await app.inject({ method: 'POST', url: '/v1/reading-operations', headers: headers(), payload: { readingType: 'coffee', sourceRequestId: `req-legacy-${enabled}` } })).statusCode).toBe(200);
    }
  });

  it('BJ: with the flag OFF an already-created V3 operation is still processed to completion', async () => {
    const h = worker([GOOD]);
    expect(h.config.coffeeV3CreationEnabled).toBe(false);
    const op = await h.v3Op('flag-off');
    await h.stageAll(op.operationId);
    h.clock.ms = op.readyAtMs;
    expect(await h.processor.process(op.operationId)).toBe('completed');
  });
});

describe('LIS2 gem acceleration (BK, BM–BR)', () => {
  async function gemWorld(tag: string) {
    const store = new MemoryDocumentStore();
    const clock = new FixedClock(Date.parse('2026-10-10T00:00:00.000Z'));
    const repository = new FirestoreReadingOperationRepository(store);
    const operations = new ReadingOperationService(repository, clock, provisionalWaitPolicy({ coffee: 60_000, palm: 120_000, soulmate: 180_000 }));
    const ledger = new GemLedger(store, clock, provisionalGemCostPolicy({ coffee: 10, palm: 15, soulmate: 20 }));
    const staged = new FirestoreReadingStagedImageRepository(store);
    const owner = identityKeyFromSubject('user-a');
    await ledger.credit({ ownerUserId: owner, amount: 95, idempotencyKey: `seed-credit-${tag}` });
    const app = await testApp(
      testConfig({ AI_JWT_SECRET: SECRET, AI_APP_CHECK_REQUIRED: 'true' }),
      async () => { throw new Error('must not call AI'); },
      { appCheck: new StaticAppCheckVerifier('good-token'), readingOperationRepository: repository, readingStagedImageRepository: staged, readingClock: clock, gemLedger: ledger },
    );
    const put = (operationId: string, slot: string | undefined, extra: Record<string, unknown> = {}) => staged.upsert({
      schemaVersion: 1, operationId, ownerUserId: owner, readingType: 'coffee',
      objectPath: `reading-staging/coffee/x/${operationId}/${slot ?? 'input'}.jpg`, contentType: 'image/jpeg', byteSize: 1024,
      checksumSha256: 'a'.repeat(64), uploadState: 'complete', ...(slot ? { slot: slot as never } : {}),
      createdAtMs: clock.ms, updatedAtMs: clock.ms, ...extra,
    } as never);
    const accelerate = (operationId: string) => app.inject({ method: 'POST', url: `/v1/reading-operations/${operationId}/accelerate`, headers: headers(), payload: { idempotencyKey: `acc-${operationId.slice(0, 8)}` } });
    const spends = () => [...store.docs.values()].filter((d) => (d as { type?: string }).type === 'spend').length;
    const v3 = () => operations.create({ ownerUserId: owner, readingType: 'coffee', sourceRequestId: `gem-v3-${Math.random().toString(36).slice(2, 10)}`, coffeeInputContract: 'trusted_intention_v1', coffeeIntention: DECISION, coffeeCaptureContract: 'three_view_v3' });
    return { app, operations, repository, owner, put, accelerate, spends, v3 };
  }

  it('BK/BO: an existing V3 op with all three complete views is acceleratable once (flag OFF)', async () => {
    const g = await gemWorld('bo');
    const op = await g.v3();
    for (const slot of STAGED) await g.put(op.operationId, slot);
    const res = await g.accelerate(op.operationId);
    expect(res.statusCode).toBe(200);
    expect(g.spends()).toBe(1);
    expect((await g.accelerate(op.operationId)).json().data.idempotent).toBe(true);
    expect(g.spends()).toBe(1);
  });

  it('BM/BN/BP: 2 of 3, a pending view, retired four-view records, V2 / legacy records on a V3 op, or a retired op → 409, no debit', async () => {
    const g = await gemWorld('bm');
    const two = await g.v3();
    for (const slot of STAGED.slice(0, 2)) await g.put(two.operationId, slot);
    const pending = await g.v3();
    for (const slot of STAGED) await g.put(pending.operationId, slot, slot === 'v3_saucer_view' ? { uploadState: 'pending' } : {});
    const retiredShaped = await g.v3();
    for (const slot of RETIRED_STAGED) await g.put(retiredShaped.operationId, slot);
    const retired = await g.v3();
    await g.repository.mutate(retired.operationId, g.owner, (r) => ({ ...r, coffeeCaptureContract: 'four_view_v3' }));
    for (const slot of [...RETIRED_STAGED, ...STAGED]) await g.put(retired.operationId, slot);
    const v2Shaped = await g.v3();
    for (const slot of ['cup_primary', 'cup_secondary', 'saucer']) await g.put(v2Shaped.operationId, slot);
    const legacyShaped = await g.v3();
    await g.put(legacyShaped.operationId, undefined);
    for (const op of [two, pending, retiredShaped, retired, v2Shaped, legacyShaped]) expect((await g.accelerate(op.operationId)).statusCode).toBe(409);
    expect(g.spends()).toBe(0);
  });

  it('BQ/BR: V2 exact-three and legacy single-image acceleration are unchanged; a V3 view on a V2 op does not count', async () => {
    const g = await gemWorld('bq');
    const v2 = await g.operations.create({ ownerUserId: g.owner, readingType: 'coffee', sourceRequestId: 'gem-v2-01' });
    for (const slot of ['cup_primary', 'cup_secondary', 'saucer']) await g.put(v2.operationId, slot);
    expect((await g.accelerate(v2.operationId)).statusCode).toBe(200);
    const legacy = await g.operations.create({ ownerUserId: g.owner, readingType: 'coffee', sourceRequestId: 'gem-legacy-01' });
    await g.put(legacy.operationId, undefined);
    expect((await g.accelerate(legacy.operationId)).statusCode).toBe(200);
    const v2WithV3 = await g.operations.create({ ownerUserId: g.owner, readingType: 'coffee', sourceRequestId: 'gem-v2-v3-01' });
    for (const slot of STAGED) await g.put(v2WithV3.operationId, slot);
    expect((await g.accelerate(v2WithV3.operationId)).statusCode).toBe(409);
    expect(g.spends()).toBe(2);
  });
});

describe('LIS2 public /v1/ai can never select V3', () => {
  it('a coffee_analysis body carrying V3 markers runs the unchanged V2 / legacy handler, never the V3 observer or writer', async () => {
    const h = worker([GOOD]);
    const op = await h.v3Op('public');
    await h.stageAll(op.operationId);
    const ai = new AiProxyService(h.config, h.fake.fetchImpl, h.stagedImages);
    for (const payload of [
      { operationId: op.operationId, coffeeCaptureContract: 'three_view_v3' },
      { operationId: op.operationId, coffeeCaptureContract: 'four_view_v3' },
      { operationId: op.operationId, slots: [...STAGED], contract: 'multi_view_marks_v3' },
    ]) {
      const out = await ai.handle({ operation: 'coffee_analysis', payload, language: 'tr' } as never, undefined, { identity: h.owner, parentKey: 'public' }).catch((e) => e);
      expect(JSON.stringify(out)).not.toContain('m2_public_v1');
    }
    expect(h.fake.bodies.some((b) => JSON.stringify(b).includes('coffee_v3_observation'))).toBe(false);
    expect(h.fake.writerCalls()).toHaveLength(0);
  });
});
