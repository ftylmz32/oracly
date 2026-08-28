#!/usr/bin/env node
/**
 * Production HTTPS smoke for ORACLY AI proxy.
 * Refuses localhost / loopback / plain HTTP / private LAN hosts.
 *
 * Usage:
 *   ORACLY_PROD_BASE_URL=https://api.example.com \
 *   ORACLY_PROD_BEARER=<firebase-id-token> \
 *   npm run smoke:prod
 *
 * Optional: ORACLY_PROD_OPERATION=chat (default)
 */
import { exit } from 'node:process';

const baseRaw = (process.env.ORACLY_PROD_BASE_URL ?? '').trim().replace(/\/$/, '');
const bearer = (process.env.ORACLY_PROD_BEARER ?? '').trim();
const operation = (process.env.ORACLY_PROD_OPERATION ?? 'chat').trim();

function fail(message) {
  console.error(`smoke:prod FAIL - ${message}`);
  exit(1);
}

function assertPublicHttps(raw) {
  if (!raw) fail('Set ORACLY_PROD_BASE_URL=https://<production-host>');
  let url;
  try {
    url = new URL(raw.includes('://') ? raw : `https://${raw}`);
  } catch {
    fail('ORACLY_PROD_BASE_URL is not a valid URL');
  }
  if (url.protocol !== 'https:') fail('HTTPS required (no http://)');
  const host = url.hostname.toLowerCase();
  if (
    host === 'localhost' ||
    host === '127.0.0.1' ||
    host === '::1' ||
    host === '0.0.0.0'
  ) {
    fail('loopback/localhost is not a production host');
  }
  if (
    /^(10\.|192\.168\.|169\.254\.)/.test(host) ||
    /^172\.(1[6-9]|2\d|3[0-1])\./.test(host)
  ) {
    fail('private/LAN IP is not a production host');
  }
  return url.origin;
}

const origin = assertPublicHttps(baseRaw);
if (!bearer) fail('Set ORACLY_PROD_BEARER to a real Firebase ID token');
if (bearer.startsWith('sk-') || bearer.startsWith('mock_')) {
  fail('Bearer must be a Firebase ID token, not an OpenAI key or mock token');
}

const health = await fetch(`${origin}/health`);
const healthBody = await health.text();
if (health.status !== 200 || !healthBody.includes('"ok"')) {
  fail(`/health expected 200 ok, got ${health.status} ${healthBody.slice(0, 200)}`);
}

const ready = await fetch(`${origin}/ready`);
const readyBody = await ready.text();
if (ready.status !== 200 || !readyBody.includes('"ready"')) {
  fail(`/ready expected 200 ready, got ${ready.status} ${readyBody.slice(0, 200)}`);
}

const payloads = {
  chat: {
    operation: 'chat',
    payload: { userMessage: 'Selam', priorUser: [], language: 'tr' },
  },
  soulmate_draw: {
    operation: 'soulmate_draw',
    payload: {
      name: 'Elif',
      birthDate: '1994-03-12',
      gender: 'feminine',
      language: 'tr',
    },
  },
};

const body = payloads[operation];
if (!body) {
  fail(
    `ORACLY_PROD_OPERATION=${operation} needs a photo payload; use chat or soulmate_draw for this script`,
  );
}

const complete = await fetch(`${origin}/v1/ai/complete`, {
  method: 'POST',
  headers: {
    'content-type': 'application/json',
    accept: 'application/json',
    authorization: `Bearer ${bearer}`,
  },
  body: JSON.stringify(body),
});
const completeText = await complete.text();
let parsed;
try {
  parsed = JSON.parse(completeText);
} catch {
  fail(`non-JSON response ${complete.status}: ${completeText.slice(0, 200)}`);
}

if (complete.status === 401) {
  fail('unauthorized (401) - Firebase ID token rejected');
}
if (complete.status === 403) {
  fail('forbidden (403)');
}
if (complete.status !== 200) {
  fail(`unexpected status ${complete.status}: ${completeText.slice(0, 300)}`);
}
if (parsed?.success !== true || !parsed?.data) {
  fail(`envelope not success: ${completeText.slice(0, 300)}`);
}
if (/sk-[A-Za-z0-9_-]+/i.test(completeText) || /Bearer\s+\S+/i.test(completeText)) {
  fail('response appears to leak a secret');
}

console.log(
  JSON.stringify(
    {
      ok: true,
      origin,
      operation,
      health: health.status,
      ready: ready.status,
      complete: complete.status,
      dataKeys: Object.keys(parsed.data),
    },
    null,
    2,
  ),
);