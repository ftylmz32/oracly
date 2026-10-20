/** Offline: re-run the server refusal rules on recorded QA texts (no provider). */
import { readFileSync } from 'node:fs';
import { validateAiBody } from '../src/ai/validate-request.js';
import { ASTROLOGY_DAILY_FIELDS, astrologyDailyRefusal } from '../src/ai/astrology-daily-result.js';

const payloads = JSON.parse(readFileSync('docs/qa/yz-astro-real-qa-20261020.payloads.json', 'utf8')) as { id: string; operation: string; payload: Record<string, unknown> }[];
const file = process.argv[2]!;
const results = JSON.parse(readFileSync(file, 'utf8')).results as { id: string; data?: Record<string, string> }[];
for (const r of results) {
  if (!r.id.startsWith('astrology.') || !r.data) continue;
  const p = payloads.find((x) => x.id === r.id)!;
  const v = validateAiBody({ operation: p.operation, payload: p.payload });
  if (v.operation !== 'astrology_daily') continue;
  const fields = Object.fromEntries(ASTROLOGY_DAILY_FIELDS.map((f) => [f, String(r.data![f] ?? '')])) as Parameters<typeof astrologyDailyRefusal>[0];
  const hedges = (Object.values(fields).join(' ').match(/\p{L}+(?:abil|ebil)\p{L}*/gu) ?? []).length;
  console.log(`${r.id}: ${astrologyDailyRefusal(fields, v.sky) ?? 'PASS'} · hedges=${hedges}`);
}
