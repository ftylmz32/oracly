/**
 * Real-provider editorial QA round for the daily astrology writer only.
 * HARD CAP: 3 real Chat Completions (QA_ROUND names the output). NO retry.
 * Same guards as _yz_astro_real_qa_20261020.ts: shared production daily
 * spend ledger, synthetic payloads, key only in process env, never printed.
 * Records the raw text and the refusal reason when the server checks fail.
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { Firestore } from '@google-cloud/firestore';
import { OAuth2Client } from 'google-auth-library';
import { loadConfig } from '../src/config.js';
import { OpenAiTransport } from '../src/ai/openai-transport.js';
import { FirestoreSpendGuard } from '../src/ai/spend-guard.js';
import { validateAiBody } from '../src/ai/validate-request.js';
import { extractChatText } from '../src/ai/parse-provider.js';
import { astrologyDailyMessages } from '../src/ai/astrology-daily-prompts.js';
import { buildAstrologyDailyCompleteOptions } from '../src/ai/astrology-daily-model.js';
import {
  ASTROLOGY_DAILY_FIELDS,
  astrologyDailyRefusal,
  parseAstrologyDailyResult,
} from '../src/ai/astrology-daily-result.js';
import { ProxyError } from '../src/errors.js';
import type { FirestoreLike } from '../src/billing/entitlement-repository.js';

const CAP = 3;
const ROUND = process.env.QA_ROUND ?? 'round2';
const IN = resolve(process.cwd(), 'docs/qa/yz-astro-real-qa-20261020.payloads.json');
const OUT = resolve(process.cwd(), `docs/qa/astro-real-qa-20261020.${ROUND}.results.json`);

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
  if (!config.aiDailySpendCapMicros) throw new Error('spend cap missing — STOP. used=0');
  const guard = new FirestoreSpendGuard(
    firestore as unknown as FirestoreLike,
    config.aiDailySpendCapMicros,
    false,
    () => new Date(),
  );
  const transport = new OpenAiTransport(config, fetch, guard);
  const day = new Date().toISOString().slice(0, 10);
  const ledger = async () => {
    const snap = await firestore.collection('aiSpendDays').doc(day).get();
    return (snap.exists ? ((snap.data()?.totalMicros as number) ?? 0) : 0) / 1_000_000;
  };
  const before = await ledger();
  console.log(`spend ledger ${day} before: $${before.toFixed(4)} / cap $5`);

  const items = (JSON.parse(readFileSync(IN, 'utf8')) as Item[]).filter(
    (i) => i.operation === 'astrology_daily',
  );
  if (items.length > CAP) throw new Error('payload count exceeds cap — STOP. used=0');
  const results: Record<string, unknown>[] = [];
  let used = 0;
  for (const item of items) {
    const v = validateAiBody({ operation: item.operation, payload: item.payload });
    if (v.operation !== 'astrology_daily') throw new Error('unexpected operation');
    used += 1;
    const started = Date.now();
    let raw = '';
    try {
      raw = extractChatText(
        await transport.complete({
          ...buildAstrologyDailyCompleteOptions(config, config.openaiModel, astrologyDailyMessages(v.sky)),
          reservationKey: `qa:${ROUND}:${item.id}:${started}`,
        }),
      );
      const data = parseAstrologyDailyResult(raw, v.sky);
      results.push({ id: item.id, ok: true, ms: Date.now() - started, data });
      console.log(`[${used}/${CAP}] ${item.id} ok`);
    } catch (error) {
      let reason: string = error instanceof ProxyError ? error.code : 'internal_error';
      let data: unknown;
      try {
        const parsed = JSON.parse(raw) as Record<string, string>;
        data = parsed;
        const fields = Object.fromEntries(
          ASTROLOGY_DAILY_FIELDS.map((f) => [f, String(parsed[f] ?? '')]),
        ) as Parameters<typeof astrologyDailyRefusal>[0];
        reason = astrologyDailyRefusal(fields, v.sky) ?? reason;
      } catch {}
      results.push({ id: item.id, ok: false, ms: Date.now() - started, error: reason, data });
      console.log(`[${used}/${CAP}] ${item.id} REFUSED ${reason}`);
    }
  }
  const after = await ledger();
  console.log(`spend ledger ${day} after: $${after.toFixed(4)} (this run ≈ $${(after - before).toFixed(4)})`);
  writeFileSync(OUT, JSON.stringify({ day, round: ROUND, used, cap: CAP, results }, null, 2));
  await firestore.terminate();
}

main().catch((e) => {
  console.error(e instanceof Error ? e.message : 'QA failed');
  process.exitCode = 1;
});
