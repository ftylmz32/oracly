/**
 * Real-provider editorial QA — Yıldızname (addressName) + daily astrology.
 * HARD CAP: 6 real Chat Completions (3 + 3). NO retry. NO gems, NO quota,
 * NO customer data: synthetic payloads exported by
 * test/features/star_map/narrative/real_qa_payload_export_test.dart.
 *
 * Every call reserves against the shared production daily spend ledger
 * (FirestoreSpendGuard, AI_DAILY_SPEND_CAP_USD), so this run cannot push the
 * day over the server cap. Firestore uses a short-lived user access token
 * (QA_GCLOUD_ACCESS_TOKEN). OPENAI_API_KEY is read from the process env only
 * and is never printed or written.
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { Firestore } from '@google-cloud/firestore';
import { OAuth2Client } from 'google-auth-library';
import { loadConfig } from '../src/config.js';
import { AiProxyService } from '../src/ai/service.js';
import { FirestoreSpendGuard } from '../src/ai/spend-guard.js';
import { validateAiBody } from '../src/ai/validate-request.js';
import { ProxyError } from '../src/errors.js';
import type { FirestoreLike } from '../src/billing/entitlement-repository.js';

const CAP = 6;
const IN = resolve(process.cwd(), 'docs/qa/yz-astro-real-qa-20261020.payloads.json');
const OUT = resolve(process.cwd(), 'docs/qa/yz-astro-real-qa-20261020.round1.results.json');

type Item = { id: string; operation: string; payload: Record<string, unknown> };

async function main(): Promise<void> {
  if (!process.env.OPENAI_API_KEY) throw new Error('OPENAI_API_KEY missing — STOP. used=0');
  const token = process.env.QA_GCLOUD_ACCESS_TOKEN;
  if (!token) throw new Error('QA_GCLOUD_ACCESS_TOKEN missing — STOP. used=0');

  const config = loadConfig({
    ...process.env,
    APP_ENV: 'development',
    OPENAI_BASE_URL: 'https://api.openai.com/v1',
    OPENAI_MODEL: 'gpt-4o',
    OPENAI_ALLOWED_MODELS: 'gpt-4o,gpt-4o-mini,gpt-5.6-sol',
    OPENAI_YILDIZNAME_NARRATIVE_MODEL: 'gpt-5.6-sol',
    OPENAI_YILDIZNAME_NARRATIVE_REASONING_EFFORT: 'none',
    OPENAI_TIMEOUT_SECONDS: '60',
    AI_DAILY_SPEND_CAP_USD: '5',
    AI_SPEND_KILL_SWITCH: 'false',
    FIREBASE_PROJECT_ID: 'oracly-7f613',
  });
  const auth = new OAuth2Client();
  auth.setCredentials({ access_token: token });
  const firestore = new Firestore({
    projectId: 'oracly-7f613',
    databaseId: config.firestoreDatabaseId,
    authClient: auth,
  } as ConstructorParameters<typeof Firestore>[0]);
  const store = firestore as unknown as FirestoreLike;
  if (!config.aiDailySpendCapMicros) throw new Error('spend cap missing — STOP. used=0');
  const guard = new FirestoreSpendGuard(store, config.aiDailySpendCapMicros, false, () => new Date());
  const service = new AiProxyService(config, undefined, undefined, guard);

  const day = new Date().toISOString().slice(0, 10);
  const ledger = async () => {
    const snap = await firestore.collection('aiSpendDays').doc(day).get();
    const total = snap.exists ? (snap.data()?.totalMicros as number) ?? 0 : 0;
    return total / 1_000_000;
  };
  const before = await ledger();
  console.log(`spend ledger ${day} before: $${before.toFixed(4)} / cap $5`);

  const items = JSON.parse(readFileSync(IN, 'utf8')) as Item[];
  if (items.length > CAP) throw new Error('payload count exceeds cap — STOP. used=0');
  const results: Record<string, unknown>[] = [];
  let used = 0;
  for (const item of items) {
    const validated = validateAiBody({ operation: item.operation, payload: item.payload });
    used += 1;
    const started = Date.now();
    try {
      const data = await service.handle(validated, undefined);
      results.push({ id: item.id, ok: true, ms: Date.now() - started, data });
      console.log(`[${used}/${CAP}] ${item.id} ok ${Date.now() - started}ms`);
    } catch (error) {
      const code = error instanceof ProxyError ? error.code : 'internal_error';
      results.push({ id: item.id, ok: false, ms: Date.now() - started, error: code });
      console.log(`[${used}/${CAP}] ${item.id} FAILED ${code}`);
    }
  }
  const after = await ledger();
  console.log(`spend ledger ${day} after: $${after.toFixed(4)} (this run ≈ $${(after - before).toFixed(4)})`);
  writeFileSync(
    OUT,
    JSON.stringify({ day, used, cap: CAP, spendBeforeUsd: before, spendAfterUsd: after, results }, null, 2),
  );
  await firestore.terminate();
}

main().catch((e) => {
  console.error(e instanceof Error ? e.message : 'QA failed');
  process.exitCode = 1;
});
