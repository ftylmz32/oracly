/**
 * Slice 5 — LOCAL transport-level E2E harness for Coffee V3 (four_view_v3).
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
import { writeFileSync } from 'node:fs';
import { identityKeyFromSubject } from '../../src/auth/identity.js';
import { AiProxyService } from '../../src/ai/service.js';
import { readingStageStore } from '../../src/ai/reading/stage-cache.js';
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
import { StaticAppCheckVerifier, jsonResponse, signHs256, testConfig } from '../helpers.js';

const handshakePath = process.argv[2];
if (!handshakePath) throw new Error('usage: coffee-v3-e2e-harness.ts <handshake.json>');

// ---------------------------------------------------------------- fixtures
// SYNTHETIC provider outputs (copied from the frozen-gate test fixtures):
// a RITAG-style four-view observation and a W4P5-accepted writer response
// for the decision intention below. Proof of plumbing, not of quality.
const W = 'secondary_option_gaining_weight';
const S = 'options_separating';
const GOOD_BEATS = [
  { id: 'B1', scenarioItems: [] as string[], text: 'Vermen gereken kararda yolun önümüzdeki dönemde adım adım ilerliyor; biraz daha ileride önün de açılıyor.' },
  { id: 'B2', scenarioItems: [W, S], text: 'Yaklaşan dönemde birden fazla yol beliriyor; seçeneklerden biri gözünde ağırlık kazanabilir, hangi yolun ne olduğu da daha açık seçilebilir.' },
];
const WRITER: Record<string, string> = {
  good: JSON.stringify({ beats: GOOD_BEATS }),
  scenario_fail: JSON.stringify({ beats: [GOOD_BEATS[0], { ...GOOD_BEATS[1], scenarioItems: [W] }] }),
  checker_fail: JSON.stringify({
    beats: [
      { id: 'B1', scenarioItems: [], text: 'Vermen gereken kararda yolun önümüzdeki dönemde adım adım ilerliyor; önün de biraz daha ileride açılıyor.' },
      { id: 'B2', scenarioItems: [W, S], text: 'Yaklaşan dönemde birkaç ayrı ihtimale açılıyor; seçeneklerden biri gözünde ağırlık kazanabilir ve seçenekler arasındaki fark daha net görünebilir.' },
    ],
  }),
};
const OBSERVATIONS: Record<string, () => unknown> = {
  ritag: () => m1Observation(c31Spec('C3F-RITAG', { clearAreas: true })),
  insufficient: () => m1Observation({ marks: [] } as never),
  unusable: () => ({ ...(m1Observation(c31Spec('C3F-RITAG', { clearAreas: true })) as object), usable: false }),
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
const providerCalls: Array<{ kind: string; at: number }> = [];
const fakeFetch = async (_url: unknown, init?: RequestInit) => {
  const body = JSON.parse(String(init?.body ?? '{}')) as Record<string, unknown>;
  const schema = (body.response_format as { json_schema?: { name?: string }; type?: string } | undefined);
  const name = schema?.json_schema?.name ?? (schema?.type === 'json_object' ? 'writer' : 'unknown');
  providerCalls.push({ kind: name, at: Date.now() });
  const script = scripts[0];
  if (!script) throw new Error(`unscripted_provider_call:${name}`);
  let content: string | undefined;
  if (name === 'coffee_v3_observation' || name === 'coffee_v2_observation') {
    content = JSON.stringify(OBSERVATIONS[script.observation]());
    // An observer-only script (no writer step expected) is consumed here.
    if (name === 'coffee_v2_observation' || script.writer.length === 0) scripts.shift();
  } else if (name === 'writer') {
    const key = script.writer.shift();
    content = key === undefined ? undefined : WRITER[key];
    if (script.writer.length === 0) scripts.shift();
  }
  if (content === undefined) throw new Error(`unexpected_provider_call:${name}`);
  return jsonResponse({ choices: [{ message: { content } }] });
};

// ------------------------------------------------------------------- stack
type Stack = Awaited<ReturnType<typeof createStack>>;
async function createStack(flagOn: boolean, secret: string, clock: ControlledClock) {
  const config = testConfig({
    AI_JWT_SECRET: secret,
    AI_APP_CHECK_REQUIRED: 'true',
    AI_RATE_LIMIT_MAX: '100000',
    AI_MAX_CONCURRENT: '50',
    ORACLY_COFFEE_V3_ENABLED: flagOn ? 'true' : 'false',
  });
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
    new AiProxyService(config, fakeFetch as typeof fetch, stagedImages),
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
  async function pump(): Promise<void> {
    if (hold || pumping) return;
    pumping = true;
    try {
      for (const task of tasks) {
        if (task.outcome || task.atMs > clock.now().getTime()) continue;
        task.attempts += 1;
        try {
          task.outcome = await processor.process(task.operationId);
        } catch {
          // Cloud Tasks would retry the SAME task with backoff.
          if (task.attempts >= 5) task.outcome = 'gave_up';
          else setTimeout(() => void pump(), 200);
        }
      }
    } finally {
      pumping = false;
    }
  }
  const app = await buildServer({
    config,
    fetchImpl: fakeFetch as typeof fetch,
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
    pendingScripts: scripts.length,
  };
}

const secret = randomBytes(24).toString('hex');
const clock = new ControlledClock();
const on = await createStack(true, secret, clock);
const off = await createStack(false, secret, clock);
const subjects = { a: 'e2e-owner-a', b: 'e2e-owner-b' };
const owners = { a: identityKeyFromSubject(subjects.a), b: identityKeyFromSubject(subjects.b) };

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
      case 'GET /state':
        return reply(200, await stateFor(stack, url.searchParams.get('operationId'), owners[(url.searchParams.get('owner') as 'a' | 'b') ?? 'a']));
      case 'POST /shutdown':
        reply(200, { bye: true });
        setTimeout(() => process.exit(0), 50);
        return;
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
    frozen: {
      writerModel: on.config.openaiReadingWriterModel,
      visionModel: on.config.openaiReadingVisionModel,
      reasoning: on.config.openaiReadingReasoningEffort,
    },
  }),
);
console.log(`E2E_HARNESS_READY on=${on.port} off=${off.port} control=${controlPort}`);
