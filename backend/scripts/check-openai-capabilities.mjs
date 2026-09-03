#!/usr/bin/env node
/**
 * Opt-in OpenAI capability preflight — NEVER run from startup, tests, or deploy.
 *
 * Usage (manual only):
 *   OPENAI_API_KEY=… npm run check:openai
 *
 * Does NOT generate images. Lists models and reports visibility only.
 * Exit 1 if auth fails or required models are not visible.
 */
import { exit } from 'node:process';

const key = (process.env.OPENAI_API_KEY ?? '').trim();
const base = (process.env.OPENAI_BASE_URL ?? 'https://api.openai.com/v1').replace(/\/$/, '');
const textModel = (process.env.OPENAI_MODEL ?? 'gpt-4o').trim();
const imageModel = (process.env.OPENAI_IMAGE_MODEL ?? 'gpt-image-2').trim();

function redact(s) {
  return String(s).replace(/sk-[A-Za-z0-9_-]+/g, '[redacted]');
}

function fail(msg) {
  console.error(JSON.stringify({ ok: false, error: redact(msg) }));
  exit(1);
}

if (!key) fail('OPENAI_API_KEY missing in environment');
if (key.startsWith('mock_')) fail('mock key rejected');

const res = await fetch(`${base}/models`, {
  headers: { Authorization: `Bearer ${key}` },
});

if (res.status === 401 || res.status === 403) {
  fail('authentication rejected');
}
if (!res.ok) {
  fail(`models list HTTP ${res.status}`);
}

const body = await res.json();
const ids = new Set(
  Array.isArray(body?.data)
    ? body.data.map((m) => String(m?.id ?? '')).filter(Boolean)
    : [],
);

const textVisible = ids.has(textModel) || [...ids].some((id) => id.startsWith(textModel));
const imageVisible =
  ids.has(imageModel) || [...ids].some((id) => id.startsWith(imageModel));

const report = {
  ok: textVisible && imageVisible,
  authentication: 'accepted',
  textModel: { id: textModel, visible: textVisible },
  imageModel: { id: imageModel, visible: imageVisible },
  note:
    'Model listing is not proof that generation succeeds. GPT Image may require organization verification. Do not treat this as a paid smoke test.',
};

console.log(JSON.stringify(report, null, 2));
if (!report.ok) exit(1);