/**
 * Slice 5 — LOCAL transport-level E2E harness for Coffee V3 (three_view_v3:
 * two genuine cup photos + one saucer photo; never a fourth).
 *
 * Runs the REAL backend application (`buildServer`: real auth / App Check
 * middleware, real reading-operation / staged-image / gem / flow / result
 * routes) and the REAL durable worker (`ReadingProcessor` → real
 * `AiProxyService.coffeeV3` → real frozen V3 pipeline) over isolated
 * in-memory storage. The ONLY substitutes are:
 *   - OpenAI: a scripted FAKE fetch (synthetic observer / writer outputs —
 *     they prove plumbing and frozen-gate behavior, NOT interpretation
 *     quality); every call is recorded; zero real provider calls;
 *   - Cloud Tasks: the injected `ReadingTaskScheduler` invokes the real
 *     `ReadingProcessor.process()` directly when a task is due (the OIDC
 *     worker hop is the only production hop not exercised);
 *   - time: a shared controllable clock (advanced only via /control).
 * Two app instances: V3 creation flag ON and OFF (process-local env only;
 * nothing is persisted, nothing is remote).
 *
 * Usage: npx tsx tests/e2e/coffee-v3-e2e-harness.ts <handshake.json>
 * A separate loopback CONTROL server exposes test-only state/scripting.
 */
import { createServer } from 'node:http';
import { createHash, randomBytes } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { identityKeyFromSubject } from '../../src/auth/identity.js';
import { AiProxyService } from '../../src/ai/service.js';
import { readingStageStore } from '../../src/ai/reading/stage-cache.js';
import { COFFEE_V3_MIN_PREMIUM_BEATS, COFFEE_V3_OBSERVER_STAGE, excludeCrossKindAmbiguities } from '../../src/ai/reading/coffee-v3-live-pipeline.js';
import { buildCoffeeV3MarkMap } from '../../src/ai/reading/coffee-v3-mark-map.js';
import { coffeeV3ObserverSystem } from '../../src/ai/reading/observer-prompts.js';
import { classifyCoffeeIntention } from '../../src/ai/reading/coffee-intention-context.js';
import { interpretCoffeeM2 } from '../../src/ai/reading/coffee-m2-semantic-engine.js';
import { planCoffeeM2Writer } from '../../src/ai/reading/coffee-m2-writer-beat-plan.js';
import { planCoffeeV3Narrative } from '../../src/ai/reading/coffee-v3n-narrative-plan.js';
import { COFFEE_V3N_RESULT_CONTRACT, COFFEE_V3N_WRITER_REJECTIONS_STAGE, FROZEN_COFFEE_V3N_PROMPT_SHA256 } from '../../src/ai/reading/coffee-v3n-narrative-pipeline.js';
import { COFFEE_V3D_DIRECT_PROMPT, COFFEE_V3D_REJECTIONS_STAGE, FROZEN_COFFEE_V3D_PROMPT_SHA256 } from '../../src/ai/reading/coffee-v3d-direct-pipeline.js';
import { FROZEN_COFFEE_M2_PROMPT_SHA256 } from '../../src/ai/reading/coffee-v3-live-pipeline.js';
import type { CoffeeMultiViewObservationV3 } from '../../src/ai/reading/types.js';
import { buildServer } from '../../src/server.js';
import { MemoryDocumentStore } from '../../src/reading/memory-document-store.js';
import { MemoryStagedObjectStore } from '../../src/reading/memory-staged-object-store.js';
import { MemorySharedWindowStore } from '../../src/rate-limit/shared-window-store.js';
import { FirestoreResponseReplayRepository } from '../../src/middleware/response-replay-repository.js';
import { provisionalGemCostPolicy } from '../../src/reading/gem-cost-policy.js';
import { GemLedger } from '../../src/reading/gem-ledger.js';
import { FirestoreReadingOperationRepository } from '../../src/reading/operation-repository.js';
import { ReadingOperationService } from '../../src/reading/operation-service.js';
import { FirestoreReadingStagedImageRepository } from '../../src/reading/operation-staged-image-repository.js';
import { ReadingStagedImageService } from '../../src/reading/operation-staged-image-service.js';
import { FirestoreProviderStageRepository } from '../../src/reading/provider-stage-repository.js';
import { ReadingFlow } from '../../src/reading/reading-flow.js';
import { ReadingProcessor, type ReadingCompletionNotifier } from '../../src/reading/reading-processor.js';
import { ReadingResultRepository } from '../../src/reading/reading-result-repository.js';
import { provisionalWaitPolicy } from '../../src/reading/wait-policy.js';
import type { ServerClock } from '../../src/reading/clock.js';
import type { ReadingTaskScheduler } from '../../src/reading/reading-task-scheduler.js';
import { c31Spec } from '../fixtures/coffee-c31-fixtures.js';
import { m1Observation } from '../fixtures/coffee-m1-fixtures.js';
import { COFFEE_V3N_PREMIUM_WRITER_OUTPUT, coffeeV3PremiumSpec, toThreeViewObservation } from '../fixtures/coffee-v3-three-view.js';
import { StaticAppCheckVerifier, jsonResponse, signHs256, testConfig } from '../helpers.js';
import {
  COFFEE_V3_LIVE_IMAGE_COUNT,
  OFFICIAL_OPENAI_BASE_URL,
  createLiveProviderGuard,
  systemPromptSha256,
  type LiveProviderGuard,
} from './live-provider-guard.js';

/**
 * The engine BOTH modes run (the live mode only swaps the fake fetch for the
 * guarded real one): ReadingProcessor → AiProxyService.coffeeV3 → V3N
 * narrative pipeline → V3N writer → v3_narrative_v1. The retired M2/W4 writer
 * sha is listed only so a run can prove it was NOT used.
 */
const handshakePath = process.argv[2];
if (!handshakePath) throw new Error('usage: coffee-v3-e2e-harness.ts <handshake.json> [--live] [--engine=direct]');
const ENGINE = process.argv.includes('--engine=direct') ? 'direct' : 'narrative';
const PIPELINE = ENGINE === 'direct'
  ? {
      resultContract: COFFEE_V3N_RESULT_CONTRACT,
      engine: 'coffee-v3d-direct-pipeline',
      writerPromptSha256: FROZEN_COFFEE_V3D_PROMPT_SHA256,
      retiredM2WriterPromptSha256: FROZEN_COFFEE_M2_PROMPT_SHA256,
    }
  : {
      resultContract: COFFEE_V3N_RESULT_CONTRACT,
      engine: 'coffee-v3n-narrative-pipeline',
      writerPromptSha256: FROZEN_COFFEE_V3N_PROMPT_SHA256,
      retiredM2WriterPromptSha256: FROZEN_COFFEE_M2_PROMPT_SHA256,
    };

// --------------------------------------------------- Slice 6: live preflight
// `--live` replaces ONLY the scripted fake provider with the real OpenAI
// transport behind the fail-closed guard. Every prerequisite is checked
// BEFORE any server, guard or credential use; a missing one exits with
// LIVE_PREFLIGHT_BLOCKED and zero provider requests.
const LIVE = process.argv.includes('--live');
/** Exactly the three product photos (the staged slot names); a fourth is never read. */
const LIVE_SLOTS = ['v3_cup_view_a', 'v3_cup_view_b', 'v3_saucer_view'] as const;
const liveInputDir = process.env.ORACLY_COFFEE_LIVE_INPUT ?? 'D:\\oracly_coffee_live_input';
const liveOutputDir = process.env.ORACLY_COFFEE_LIVE_OUTPUT ?? 'D:\\oracly_coffee_live_output';

/** Mirrors the client normalizer's host fast path: JPEG, no Exif, 8 KiB–8 MiB. */
function hasExifSegment(bytes: Buffer): boolean {
  if (bytes.length < 4 || bytes[0] !== 0xff || bytes[1] !== 0xd8) return false;
  let offset = 2;
  while (offset + 4 <= bytes.length) {
    if (bytes[offset] !== 0xff) break;
    const marker = bytes[offset + 1];
    if (marker === 0xd8 || marker === 0xd9 || marker === 0xda) break;
    if (marker < 0xd0 || marker > 0xd9) {
      const segLen = (bytes[offset + 2] << 8) | bytes[offset + 3];
      if (marker === 0xe1 && bytes.subarray(offset + 4, offset + 8).toString('latin1') === 'Exif') return true;
      offset += 2 + segLen;
    } else {
      offset += 2;
    }
  }
  return false;
}

/**
 * Writer-only replay (live mode only): `ORACLY_COFFEE_LIVE_REPLAY_OBSERVATION`
 * names a previous live evidence file. Its recorded REAL observation (the
 * provider's own output, cached verbatim by the pipeline) is replayed as the
 * cached observer stage of the new operation, so the pipeline sends NO
 * observer request; the guard runs writer-only (≤ 2 writer requests). Nothing
 * is fabricated or edited: the observation must come from exactly one
 * successful 3-image observer record whose system prompt equals today's.
 */
type LiveReplay = { source: string; fileSha256: string; observationSha256: string; observation: CoffeeMultiViewObservationV3 };
const REPLAY_PATH = LIVE ? process.env.ORACLY_COFFEE_LIVE_REPLAY_OBSERVATION?.trim() || null : null;

function loadReplay(path: string, blocked: string[]): LiveReplay | null {
  let raw: Buffer;
  let doc: any;
  try {
    raw = readFileSync(path);
    doc = JSON.parse(raw.toString('utf8'));
  } catch {
    blocked.push('replay_file_unreadable_or_not_json');
    return null;
  }
  const before = blocked.length;
  const results = Array.isArray(doc?.results) ? doc.results : [];
  if (results.length !== 1) blocked.push('replay_expected_exactly_one_result');
  const obs = results[0]?.semanticFunnel?.observation;
  if (!obs || typeof obs !== 'object') blocked.push('replay_observation_missing');
  else {
    if (obs.contract !== 'multi_view_marks_v3') blocked.push('replay_observation_contract');
    if (obs.usable !== true) blocked.push('replay_observation_not_usable');
    const slots = Array.isArray(obs.views) ? obs.views.map((v: { slot?: unknown }) => v?.slot) : [];
    if (JSON.stringify(slots) !== JSON.stringify(['cup_view_a', 'cup_view_b', 'saucer'])) blocked.push('replay_observation_views_not_three_view');
    for (const k of ['sightings', 'marks', 'relations', 'ambiguities']) if (!Array.isArray(obs[k])) blocked.push(`replay_observation_${k}_not_array`);
    if (!obs.saucer || typeof obs.saucer !== 'object') blocked.push('replay_observation_saucer_missing');
  }
  const records = Array.isArray(doc?.provider?.records) ? doc.provider.records : [];
  const observers = records.filter((r: { kind?: unknown }) => r?.kind === 'observer');
  if (observers.length !== 1) blocked.push('replay_expected_exactly_one_observer_record');
  else {
    const r = observers[0];
    if (r.status !== 200 || r.outcome !== 'ok') blocked.push('replay_observer_record_not_ok');
    if (r.imageCount !== COFFEE_V3_LIVE_IMAGE_COUNT) blocked.push('replay_observer_record_not_three_images');
    const currentObserverSha = createHash('sha256').update(coffeeV3ObserverSystem(), 'utf8').digest('hex');
    if (r.systemPromptSha256 !== currentObserverSha) blocked.push('replay_observer_prompt_changed_since_recording');
  }
  if (blocked.length > before) return null;
  return {
    source: path,
    fileSha256: createHash('sha256').update(raw).digest('hex'),
    observationSha256: createHash('sha256').update(JSON.stringify(obs)).digest('hex'),
    observation: obs as CoffeeMultiViewObservationV3,
  };
}

function livePreflight(): { apiKey: string; visionModel: string; replay: LiveReplay | null; photoHashes: Record<string, string> } {
  const blocked: string[] = [];
  if (ENGINE === 'direct' && REPLAY_PATH) blocked.push('v3d_does_not_accept_v3n_observation_replay');
  const replay = REPLAY_PATH ? loadReplay(REPLAY_PATH, blocked) : null;
  if (!existsSync(liveInputDir)) blocked.push(`input_dir_missing:${liveInputDir}`);
  const hashes = new Set<string>();
  const photoHashes: Record<string, string> = {};
  for (const slot of LIVE_SLOTS) {
    const path = join(liveInputDir, `${slot}.jpg`);
    if (!existsSync(path)) {
      blocked.push(`photo_missing:${slot}.jpg`);
      continue;
    }
    let bytes: Buffer;
    try {
      bytes = readFileSync(path);
    } catch {
      blocked.push(`photo_unreadable:${slot}.jpg`);
      continue;
    }
    if (bytes[0] !== 0xff || bytes[1] !== 0xd8 || bytes[2] !== 0xff) blocked.push(`photo_not_jpeg:${slot}.jpg`);
    if (bytes.length < 8 * 1024 || bytes.length > 8 * 1024 * 1024) blocked.push(`photo_size_out_of_range:${slot}.jpg`);
    if (hasExifSegment(bytes)) blocked.push(`photo_has_exif_host_normalizer_unsupported:${slot}.jpg`);
    const digest = createHash('sha256').update(bytes).digest('hex');
    hashes.add(digest);
    photoHashes[slot] = digest;
  }
  if (hashes.size > 0 && hashes.size < LIVE_SLOTS.length) blocked.push('photos_not_distinct');
  const rights = join(liveInputDir, 'rights.txt');
  // Owner-provided only; never generated or interpreted beyond presence.
  if (!existsSync(rights) || readFileSync(rights, 'utf8').trim().length === 0) blocked.push('rights_txt_missing_or_empty');
  const apiKey = process.env.ORACLY_COFFEE_LIVE_OPENAI_API_KEY?.trim() ?? '';
  if (!apiKey) blocked.push('credential_missing:ORACLY_COFFEE_LIVE_OPENAI_API_KEY');
  else if (process.env.OPENAI_API_KEY && process.env.OPENAI_API_KEY.trim() === apiKey) {
    blocked.push('credential_is_the_general_OPENAI_API_KEY_use_a_dedicated_non_production_key');
  }
  const base = (process.env.OPENAI_BASE_URL ?? OFFICIAL_OPENAI_BASE_URL).replace(/\/$/, '');
  if (base !== OFFICIAL_OPENAI_BASE_URL) blocked.push('non_official_OPENAI_BASE_URL');
  const visionModel = process.env.ORACLY_COFFEE_LIVE_VISION_MODEL?.trim() || 'gpt-5.6-sol';
  if (replay) console.log(`LIVE_REPLAY_OBSERVATION sha256=${replay.observationSha256} file_sha256=${replay.fileSha256}`);
  if (blocked.length) {
    console.log(`LIVE_PREFLIGHT_BLOCKED ${JSON.stringify(blocked)}`);
    process.exit(2);
  }
  return { apiKey, visionModel, replay, photoHashes };
}
const liveSetup = LIVE ? livePreflight() : null;
let liveGuard: LiveProviderGuard | null = null;

// ---------------------------------------------------------------- fixtures
// SYNTHETIC provider outputs (offline fixtures): three-view observations
// (`premium` = RITAG + one strong object sign, `ritag` = structure-only,
// `sparse` = too few grounded claims) and SIMULATED V3N narrative-writer
// responses for the decision intention below. The internal V3 entry runs the
// V3N narrative successor. Proof of plumbing and gates, not of real quality.
const WRITER: Record<string, string> = {
  good: COFFEE_V3N_PREMIUM_WRITER_OUTPUT,
  direct_good: 'Uzun zamandır beklettiğin bir konuşma yeniden önüne geliyor. Bu kez karşı tarafın yaklaşımı daha açık; sen de ne istediğini saklamadan söylediğinde aradaki düğüm çözülmeye başlayacak. İş tarafında ise küçük görünen bir teklif, düşündüğünden daha kalıcı bir kapı açabilir. Acele bir kesinlik yerine gelişmelerin yönünü izlediğinde iki konunun da aynı dönemde netleştiğini göreceksin.',
  direct_leak: 'Fincanında bir kuş görüyorum; bu sana yakında gelecek bir haberi anlatıyor. Uzun zamandır beklediğin konuşma yeniden açılacak ve önündeki seçeneklerden biri daha belirgin hale gelecek. İş tarafında da yeni bir kapı açılıyor gibi görünüyor.',
  // Gate failures (thin / generic): each is refused by the V3N acceptance.
  scenario_fail: JSON.stringify({ paragraphs: [{ claims: ['c1', 'c2'], text: 'Bir yol beliriyor gibi.' }, { claims: ['c3', 'c4'], text: 'Güzel şeyler olacak.' }] }),
  checker_fail: JSON.stringify({ paragraphs: [{ claims: ['c1', 'c2'], text: 'Her şey yoluna girecek.' }, { claims: ['c3', 'c4'], text: 'Kesinlikle.' }] }),
};
const OBSERVATIONS: Record<string, () => unknown> = {
  premium: () => toThreeViewObservation(m1Observation(coffeeV3PremiumSpec())),
  ritag: () => toThreeViewObservation(m1Observation(c31Spec('C3F-RITAG', { clearAreas: true }))),
  sparse: () => toThreeViewObservation(m1Observation(c31Spec('C3F-BASAK', { clearAreas: true }))),
  insufficient: () => toThreeViewObservation(m1Observation({ marks: [] } as never)),
  unusable: () => ({ ...toThreeViewObservation(m1Observation(c31Spec('C3F-RITAG', { clearAreas: true }))), usable: false }),
  v2_no_meaning: () => ({
    usable: true,
    reason: '',
    photoChecks: {
      cupPrimary: { cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true, usefulRegionsVisible: true },
      cupSecondary: { cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true, usefulRegionsVisible: true },
      saucer: { saucerVisible: true, adequateFocusLight: true, residueOrFlowVisible: false, usefulRegionsVisible: true },
    },
    evidence: [
      { id: 'e1', region: 'base', description: 'odd silhouette', resemblance: 'purple dragon', confidence: 'high', visibility: 'clear', sourceSlot: 'cup_primary' },
      { id: 'e2', region: 'rim', description: 'odd outline', resemblance: 'green teapot', confidence: 'high', visibility: 'clear', sourceSlot: 'cup_secondary' },
      { id: 'e3', region: 'base', description: 'odd smear', resemblance: 'silver comet', confidence: 'high', visibility: 'clear', sourceSlot: 'saucer' },
    ],
  }),
};

/**
 * Live evidence only: the semantic funnel of ONE operation, recomputed
 * deterministically from the cached observer output (no provider call):
 * observation → mark map → M2 meaning → W2 plan → premium floor. Lets a thin
 * real reading be diagnosed from evidence instead of inference. Written only
 * to the external evidence directory (never the repository).
 */
function semanticFunnel(ownerUserId: string, operationId: string, intention: string | null) {
  const obs = readingStageStore.get<CoffeeMultiViewObservationV3>(ownerUserId, `reading-operation:${operationId}`, COFFEE_V3_OBSERVER_STAGE);
  if (!obs) return { observation: null };
  // Same integration step as the pipeline: cross-kind possible-same pairs are
  // excluded from identity merging (recorded here), the observation is kept.
  const { observation: forMap, excluded } = excludeCrossKindAmbiguities(obs);
  const built = buildCoffeeV3MarkMap(forMap);
  if (built.status !== 'ok') return { observation: obs, excludedAmbiguities: excluded, map: built };
  const marks = [...built.map.cupMarks, ...built.map.saucerMarks];
  const meaning = interpretCoffeeM2(built.map, classifyCoffeeIntention(intention ?? '')).meaning;
  const plan = planCoffeeM2Writer(meaning).plan;
  return {
    observation: obs,
    map: {
      cupMarks: built.map.cupMarks.length,
      saucerMarks: built.map.saucerMarks.length,
      distinctMarkCount: built.map.distinctMarkCount,
      candidates: marks.flatMap((m) => m.candidates.map((c) => ({ mark: m.id, label: c.label, usable: c.usable }))),
      audit: built.map.audit,
    },
    m2: {
      diagnostics: meaning.diagnostics,
      threads: meaning.threads.map((t) => ({
        id: t.id, lane: t.lane, developments: t.developments, combination: t.combination,
        modifiers: t.modifiers, depth: t.depth, facets: t.facets.map((f) => f.cls),
      })),
    },
    plan: {
      status: plan.status,
      beats: plan.beats.map((b) => ({ id: b.id, purpose: b.purpose, groups: b.groups.map((g) => g.cls), relation: !!b.relation, scenario: !!b.scenario })),
      omitted: plan.omitted,
    },
    premiumFloor: { minBeats: COFFEE_V3_MIN_PREMIUM_BEATS, met: plan.status === 'planned' && plan.beats.length >= COFFEE_V3_MIN_PREMIUM_BEATS },
    // The path that actually produces the reading: grounded claims with provenance.
    excludedAmbiguities: excluded,
    v3n: planCoffeeV3Narrative(built.map, classifyCoffeeIntention(intention ?? ''), { softMarks: new Set(excluded.flatMap((e) => e.marks)) }),
  };
}

// ------------------------------------------------------------------- clock
class ControlledClock implements ServerClock {
  offsetMs = 0;
  now(): Date {
    return new Date(Date.now() + this.offsetMs);
  }
}

// ------------------------------------------------------- scripted provider
type Script = { observation: string; writer: string[] };
const scripts: Script[] = [];
const providerCalls: Array<{ kind: string; at: number; images: number; promptSha: string | null }> = [];
const fakeFetch = async (_url: unknown, init?: RequestInit) => {
  const body = JSON.parse(String(init?.body ?? '{}')) as Record<string, unknown>;
  const schema = (body.response_format as { json_schema?: { name?: string }; type?: string } | undefined);
  const name = schema?.json_schema?.name ?? (schema?.type === 'json_object' ? 'writer' : (ENGINE === 'direct' ? 'direct' : 'unknown'));
  const images = (Array.isArray(body.messages) ? body.messages : [])
    .flatMap((m) => (Array.isArray((m as { content?: unknown }).content) ? ((m as { content: unknown[] }).content) : []))
    .filter((p) => (p as { type?: unknown }).type === 'image_url').length;
  providerCalls.push({ kind: name, at: Date.now(), images, promptSha: systemPromptSha256(body) });
  const script = scripts[0];
  if (!script) throw new Error(`unscripted_provider_call:${name}`);
  let content: string | undefined;
  if (name === 'coffee_v3_observation' || name === 'coffee_v2_observation') {
    content = JSON.stringify(OBSERVATIONS[script.observation]());
    // An observer-only script (no writer step expected) is consumed here.
    if (name === 'coffee_v2_observation' || script.writer.length === 0) scripts.shift();
  } else if (name === 'writer' || name === 'direct') {
    const key = script.writer.shift();
    content = key === undefined ? undefined : WRITER[key];
    if (script.writer.length === 0) scripts.shift();
  }
  if (content === undefined) throw new Error(`unexpected_provider_call:${name}`);
  return jsonResponse({ choices: [{ message: { content } }] });
};

// ------------------------------------------------------------------- stack
type Stack = Awaited<ReturnType<typeof createStack>>;
async function createStack(
  flagOn: boolean,
  secret: string,
  clock: ControlledClock,
  provider: { fetch: typeof fetch; env?: Record<string, string>; maxTaskAttempts?: number; replayObservation?: unknown } = {
    fetch: fakeFetch as typeof fetch,
  },
) {
  const config = testConfig({
    AI_JWT_SECRET: secret,
    AI_APP_CHECK_REQUIRED: 'true',
    AI_RATE_LIMIT_MAX: '100000',
    AI_MAX_CONCURRENT: '50',
    ORACLY_COFFEE_V3_ENABLED: flagOn ? 'true' : 'false',
    // This harness scripts and asserts the V3N chain (observer → plan → writer).
    ORACLY_COFFEE_V3_ENGINE: ENGINE,
    ...(provider.env ?? {}),
  });
  const maxTaskAttempts = provider.maxTaskAttempts ?? 5;
  const store = new MemoryDocumentStore();
  const policy = provisionalWaitPolicy({ coffee: 3_000, palm: 3_000, soulmate: 3_000 });
  const repository = new FirestoreReadingOperationRepository(store);
  const operations = new ReadingOperationService(repository, clock, policy);
  const stagedRepository = new FirestoreReadingStagedImageRepository(store);
  const objects = new MemoryStagedObjectStore();
  const stagedImages = new ReadingStagedImageService(stagedRepository, objects, operations, clock, config);
  const ledger = new GemLedger(store, clock, provisionalGemCostPolicy({ coffee: 10, palm: 15, soulmate: 20 }));
  const flow = new ReadingFlow(store, clock, operations, ledger);
  const results = new ReadingResultRepository(store);
  const providerStages = new FirestoreProviderStageRepository(store);
  const pushes: string[] = [];
  const notifier: ReadingCompletionNotifier = {
    async notifyCompleted(input) {
      pushes.push(input.operationId);
    },
  };
  const processor = new ReadingProcessor(
    repository, flow, stagedRepository, stagedImages, results,
    new AiProxyService(config, provider.fetch, stagedImages),
    clock, notifier, false, providerStages,
  );
  const tasks: Array<{ operationId: string; atMs: number; trigger: string; attempts: number; outcome?: string }> = [];
  const scheduler: ReadingTaskScheduler = {
    async schedule(input) {
      tasks.push({ ...input, attempts: 0 });
      setImmediate(() => void pump());
    },
  };
  let hold = false;
  let pumping = false;
  const replayed = new Set<string>();
  async function pump(): Promise<void> {
    if (hold || pumping) return;
    pumping = true;
    try {
      for (const task of tasks) {
        if (task.outcome || task.atMs > clock.now().getTime()) continue;
        task.attempts += 1;
        try {
          if (provider.replayObservation && !replayed.has(task.operationId)) {
            // Writer-only replay: the recorded observation becomes this
            // operation's cached observer stage (an untouched deep copy).
            const op = await repository.getById(task.operationId);
            if (op?.readingType === 'coffee') {
              readingStageStore.set(op.ownerUserId, `reading-operation:${task.operationId}`, COFFEE_V3_OBSERVER_STAGE, structuredClone(provider.replayObservation));
              replayed.add(task.operationId);
            }
          }
          task.outcome = await processor.process(task.operationId);
        } catch {
          // Cloud Tasks would retry the SAME task with backoff.
          if (task.attempts >= maxTaskAttempts) task.outcome = 'gave_up';
          else setTimeout(() => void pump(), 200);
        }
      }
    } finally {
      pumping = false;
    }
  }
  const app = await buildServer({
    config,
    fetchImpl: provider.fetch,
    logger: false,
    appCheck: new StaticAppCheckVerifier('e2e-app-check'),
    readingOperationRepository: repository,
    readingClock: clock,
    readingWaitPolicy: policy,
    gemLedger: ledger,
    readingFlow: flow,
    readingStagedImageRepository: stagedRepository,
    readingStagedObjectStore: objects,
    readingStagedImages: stagedImages,
    readingTaskScheduler: scheduler,
    readingResults: results,
    readingProcessor: processor,
    sharedWindowStore: new MemorySharedWindowStore(),
    responseReplayRepository: new FirestoreResponseReplayRepository(new MemoryDocumentStore()),
  });
  await app.listen({ host: '127.0.0.1', port: 0 });
  const address = app.server.address();
  const port = typeof address === 'object' && address ? address.port : 0;
  // Cloud Tasks delivers a task once its scheduled time has passed.
  setInterval(() => void pump(), 200).unref();
  return {
    flagOn, config, store, repository, stagedRepository, objects, ledger, flow, results, processor,
    tasks, pushes, port, pump,
    setHold(value: boolean) {
      hold = value;
      if (!value) void pump();
    },
  };
}

// ------------------------------------------------------------------ control
function sha(buf: Buffer) {
  return createHash('sha256').update(buf).digest('hex');
}

async function stateFor(stack: Stack, operationId: string | null, owner: string) {
  const docs = [...stack.store.docs.entries()];
  const op = operationId ? await stack.repository.getById(operationId) : null;
  const slots = operationId
    ? (await stack.stagedRepository.listCoffeeV3Slots(operationId, op?.ownerUserId ?? owner)).map((r) => ({
        slot: r.slot,
        ownerUserId: r.ownerUserId,
        contentType: r.contentType,
        checksumSha256: r.checksumSha256,
        uploadState: r.uploadState,
        objectPath: r.objectPath,
      }))
    : [];
  const objectHashes: Record<string, string> = {};
  for (const [path, value] of stack.objects.objects.entries()) {
    const bytes = (value as { bytes?: Buffer }).bytes ?? (value as unknown as Buffer);
    if (Buffer.isBuffer(bytes)) objectHashes[path] = sha(bytes);
  }
  return {
    operation: op,
    v3Slots: slots,
    objectCount: stack.objects.objects.size,
    objectHashes,
    // Per operation when one is given (results are keyed by operationId).
    resultCount: docs.filter(([k]) =>
      k.includes('readingOperationResults/') && (operationId == null || k.includes(operationId))).length,
    resultCountAll: docs.filter(([k]) => k.includes('readingOperationResults/')).length,
    result: operationId ? await stack.results.get(operationId) : null,
    refunds: docs.filter(([, d]) => (d as { type?: string }).type === 'refund').length,
    balance: await stack.ledger.balanceOf(owner).catch(() => null),
    operationCount: docs.filter(([k]) => k.startsWith('readingOperations/')).length,
    pushes: [...stack.pushes],
    tasks: stack.tasks.map((t) => ({ operationId: t.operationId, trigger: t.trigger, attempts: t.attempts, outcome: t.outcome ?? null })),
    providerCalls: providerCalls.map((c) => c.kind),
    providerImageCounts: providerCalls.map((c) => c.images),
    providerPromptShas: providerCalls.map((c) => c.promptSha),
    pendingScripts: scripts.length,
    liveProvider: liveGuard ? { records: liveGuard.records(), refusals: liveGuard.refusals(), attempts: liveGuard.attempts(), sealed: liveGuard.sealed() } : null,
  };
}

const secret = randomBytes(24).toString('hex');
const clock = new ControlledClock();
let on: Stack;
let off: Stack;
if (liveSetup) {
  // Real OpenAI transport behind the fail-closed guard; frozen settings are
  // passed explicitly (the pipeline still verifies every pin itself). The
  // general OPENAI_API_KEY from the environment is never read.
  liveGuard = createLiveProviderGuard({
    realFetch: globalThis.fetch.bind(globalThis),
    baseUrl: OFFICIAL_OPENAI_BASE_URL,
    writerOnly: liveSetup.replay !== null,
    directOnly: ENGINE === 'direct',
  });
  const env = {
    OPENAI_API_KEY: liveSetup.apiKey,
    OPENAI_BASE_URL: OFFICIAL_OPENAI_BASE_URL,
    OPENAI_READING_WRITER_MODEL: 'gpt-5.6-sol',
    OPENAI_READING_VISION_MODEL: liveSetup.visionModel,
    OPENAI_READING_REASONING_EFFORT: 'low',
    OPENAI_ALLOWED_MODELS: [...new Set(['gpt-4o', 'gpt-5.6-sol', liveSetup.visionModel])].join(','),
    OPENAI_VISION: 'true',
    OPENAI_TIMEOUT_SECONDS: '120',
  };
  // No automatic task retry: an ambiguous attempt may already be billed.
  on = await createStack(true, secret, clock, {
    fetch: liveGuard.fetch as typeof fetch,
    env,
    maxTaskAttempts: 1,
    replayObservation: liveSetup.replay?.observation,
  });
  off = on; // no flag-OFF instance in live mode
} else {
  on = await createStack(true, secret, clock);
  off = await createStack(false, secret, clock);
}
const subjects = { a: 'e2e-owner-a', b: 'e2e-owner-b' };
const owners = { a: identityKeyFromSubject(subjects.a), b: identityKeyFromSubject(subjects.b) };

/**
 * The evidence document of a run: engine proof (which writer contract ran),
 * provider metadata, and per operation the delivered reading verbatim, its
 * result contract, the claim ↔ evidence map and the recomputed funnel.
 */
async function buildEvidence(
  operationIds: string[],
  provider: { records: ReadonlyArray<{ kind: string; systemPromptSha256: string | null }> } & Record<string, unknown>,
  writerOutputs: ReadonlyArray<{ index: number; attempt: number; outputSha256: string; text: string }> = [],
) {
  const writerShas = provider.records.filter((r) => r.kind === 'writer' || r.kind === 'direct').map((r) => r.systemPromptSha256);
  const results = await Promise.all(operationIds.map((id) => evidenceFor(id)));
  // Live only: every real writer text, verbatim, with the acceptance verdict
  // (matched by the pipeline's own rejection hash). Local evidence file only.
  const rejected = new Map(
    results.flatMap((r) => (r.writerRejections as Array<{ outputSha256: string; failures: string[] }> | null) ?? []).map((x) => [x.outputSha256, x.failures]),
  );
  const delivered = results.some((r) => r.resultContract === PIPELINE.resultContract);
  return {
    at: new Date().toISOString(),
    pipeline: {
      ...PIPELINE,
      writerPromptShasSeen: writerShas,
      usedExpectedWriter: writerShas.length > 0 && writerShas.every((s) => s === PIPELINE.writerPromptSha256),
      usedV3NWriter: ENGINE === 'narrative' && writerShas.length > 0 && writerShas.every((s) => s === PIPELINE.writerPromptSha256),
      usedRetiredM2Writer: writerShas.some((s) => s === PIPELINE.retiredM2WriterPromptSha256),
    },
    provider,
    replay: liveSetup?.replay
      ? { source: liveSetup.replay.source, fileSha256: liveSetup.replay.fileSha256, observationSha256: liveSetup.replay.observationSha256, observerRequestsSent: 0 }
      : null,
    inputEvidence: liveSetup ? { photoSha256BySlot: liveSetup.photoHashes } : null,
    qualityProtocol: {
      verdicts: ['grounded_in_visible_differences', 'specific_not_generic', 'natural_turkish', 'coherent_depth', 'non_repetitive', 'no_invented_certainty', 'worth_paying_for'],
      comparison: 'Blind A/B: run the same intention on a second genuinely different three-photo cup set; hide filenames and order from the reviewer; require materially different themes/details while preserving safety and coherence.',
      prohibition: 'A single set or two resamples of the same set cannot prove image sensitivity.',
    },
    operations: operationIds,
    results,
    writerOutputs: writerOutputs.map((o) => ({
      index: o.index,
      attempt: o.attempt,
      outputSha256: o.outputSha256,
      verdict: rejected.has(o.outputSha256) ? 'rejected' : delivered ? 'accepted' : 'unknown',
      failures: rejected.get(o.outputSha256) ?? [],
      text: o.text,
    })),
  };
}

/** One operation's evidence: delivered reading, contract, claim ↔ evidence, rejections, funnel. */
async function evidenceFor(id: string) {
  const operation = await on.repository.getById(id);
  const result = (await on.results.get(id))?.data ?? null;
  const funnel = operation && ENGINE === 'narrative' ? semanticFunnel(operation.ownerUserId, id, operation.coffeeIntention) : null;
  const v3n = funnel && 'v3n' in funnel ? funnel.v3n : null;
  return {
    operationId: id,
    operation,
    // The delivered reading, verbatim, and the engine that produced it.
    reading: typeof result?.overall === 'string' ? result.overall : null,
    resultContract: result?.coffeeResultContract ?? null,
    result,
    // Claim ↔ evidence: what the writer was told (life meaning) and the
    // server-side visual evidence it rests on (never shown to the person).
    claimEvidence: v3n
      ? v3n.claims.map((c) => ({
          id: c.id, theme: c.theme, meaningToldToWriter: c.meaning, horizon: c.horizon, placement: c.placement,
          certainty: c.certainty, evidence: { seen: c.seen, symbol: c.symbol, surface: c.surface, provenance: c.provenance },
        }))
      : null,
    paragraphs: v3n ? v3n.paragraphs : null,
    // Why each refused writer sample failed: codes, paragraph / claim, matched
    // term and the output sha256 (a live run adds the texts under writerOutputs).
    writerRejections: operation
      ? readingStageStore.get(operation.ownerUserId, `reading-operation:${id}`, ENGINE === 'direct' ? COFFEE_V3D_REJECTIONS_STAGE : COFFEE_V3N_WRITER_REJECTIONS_STAGE)
      : null,
    semanticFunnel: funnel,
  };
}

const control = createServer(async (req, res) => {
  const url = new URL(req.url ?? '/', 'http://127.0.0.1');
  const chunks: Buffer[] = [];
  for await (const chunk of req) chunks.push(chunk as Buffer);
  const body = chunks.length ? JSON.parse(Buffer.concat(chunks).toString('utf8')) : {};
  const stack = url.searchParams.get('stack') === 'off' ? off : on;
  const reply = (code: number, payload: unknown) => {
    res.writeHead(code, { 'content-type': 'application/json' });
    res.end(JSON.stringify(payload));
  };
  try {
    switch (`${req.method} ${url.pathname}`) {
      case 'POST /script':
        if (LIVE) return reply(409, { error: 'live_mode_has_no_scripted_provider' });
        scripts.push({ observation: body.observation, writer: [...(body.writer ?? [])] });
        readingStageStore.clear();
        return reply(200, { queued: scripts.length });
      case 'POST /hold':
        stack.setHold(Boolean(body.hold));
        return reply(200, { hold: Boolean(body.hold) });
      case 'POST /advance':
        clock.offsetMs += Number(body.ms ?? 0);
        void on.pump();
        void off.pump();
        return reply(200, { offsetMs: clock.offsetMs });
      case 'POST /credit':
        await stack.ledger.credit({
          ownerUserId: owners[body.owner as 'a' | 'b'],
          amount: Number(body.amount),
          idempotencyKey: `e2e-credit-${body.owner}-${randomBytes(6).toString('hex')}`,
        });
        return reply(200, { balance: await stack.ledger.balanceOf(owners[body.owner as 'a' | 'b']) });
      case 'POST /pump':
        await stack.pump();
        return reply(200, { ok: true });
      case 'GET /evidence': {
        // Scripted mode only: the SAME evidence builder the live run writes at
        // shutdown, returned in memory (no file) so E2E can verify its shape.
        if (LIVE) return reply(409, { error: 'live_mode_writes_evidence_at_shutdown' });
        const id = url.searchParams.get('operationId');
        const records = providerCalls.map((c) => ({
          kind: c.kind === 'coffee_v3_observation' ? 'observer' : c.kind,
          imageCount: c.images,
          systemPromptSha256: c.promptSha,
        }));
        return reply(200, await buildEvidence(id ? [id] : [], { records }));
      }
      case 'GET /state':
        return reply(200, await stateFor(stack, url.searchParams.get('operationId'), owners[(url.searchParams.get('owner') as 'a' | 'b') ?? 'a']));
      case 'POST /shutdown': {
        if (liveGuard) {
          liveGuard.seal('test_finished'); // nothing may leave after this
          // Evidence OUTSIDE the repository: request metadata (no credential,
          // no image bytes), every real writer text with its verdict, the
          // delivered public result and the recomputed semantic funnel.
          mkdirSync(liveOutputDir, { recursive: true });
          const evidence = await buildEvidence(
            (body.operationIds ?? []) as string[],
            { records: liveGuard.records(), refusals: liveGuard.refusals(), attempts: liveGuard.attempts(), sealed: liveGuard.sealed() },
            liveGuard.writerOutputs(),
          );
          writeFileSync(join(liveOutputDir, `coffee_v3${ENGINE === 'direct' ? 'd' : 'n'}_live_${Date.now()}.json`), JSON.stringify(evidence, null, 2));
        }
        reply(200, { bye: true });
        setTimeout(() => process.exit(0), 50);
        return;
      }
      default:
        return reply(404, { error: 'unknown_control' });
    }
  } catch (error) {
    return reply(500, { error: String(error) });
  }
});
await new Promise<void>((resolve) => control.listen(0, '127.0.0.1', resolve));
const controlAddress = control.address();
const controlPort = typeof controlAddress === 'object' && controlAddress ? controlAddress.port : 0;

writeFileSync(
  handshakePath,
  JSON.stringify({
    base: `http://127.0.0.1:${on.port}`,
    baseFlagOff: `http://127.0.0.1:${off.port}`,
    control: `http://127.0.0.1:${controlPort}`,
    tokenA: signHs256(secret, { sub: subjects.a }),
    tokenB: signHs256(secret, { sub: subjects.b }),
    ownerKeyA: owners.a,
    ownerKeyB: owners.b,
    appCheck: 'e2e-app-check',
    serverFlagOn: on.config.coffeeV3CreationEnabled,
    serverFlagOff: off.config.coffeeV3CreationEnabled,
    live: LIVE,
    liveInputDir: LIVE ? liveInputDir : null,
    replay: liveSetup?.replay ? { observationSha256: liveSetup.replay.observationSha256 } : null,
    pipeline: PIPELINE,
    frozen: {
      writerModel: on.config.openaiReadingWriterModel,
      visionModel: on.config.openaiReadingVisionModel,
      reasoning: on.config.openaiReadingReasoningEffort,
    },
  }),
);
console.log(`E2E_HARNESS_READY on=${on.port} off=${off.port} control=${controlPort}`);
