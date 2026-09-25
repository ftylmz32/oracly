/** Phase 5 — deterministic canonical JSON + Yıldızname SHA-256 fingerprint. */
import { createHash } from 'node:crypto';
import type { YildiznameNarrativeValidated } from './narrative-yildizname-contract.js';

/** Lexicographic object-key sort; array order preserved. */
export function canonicalJson(value: unknown): string {
  return JSON.stringify(canonicalize(value));
}

function canonicalize(value: unknown): unknown {
  if (value === null || typeof value !== 'object') return value;
  if (Array.isArray(value)) return value.map(canonicalize);
  const obj = value as Record<string, unknown>;
  const keys = Object.keys(obj).sort();
  const out: Record<string, unknown> = {};
  for (const k of keys) out[k] = canonicalize(obj[k]);
  return out;
}

export function yildiznameRequestFingerprint(
  request: YildiznameNarrativeValidated,
): string {
  const preimage = canonicalJson({
    mode: request.mode,
    contractVersion: request.contractVersion,
    language: request.language,
    narrative: request.narrative,
  });
  const digest = createHash('sha256').update(preimage, 'utf8').digest('hex');
  return `yildizname-narrative:${digest}`;
}
