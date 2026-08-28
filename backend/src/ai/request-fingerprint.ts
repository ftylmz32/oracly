/** Compact fingerprints — never hash full image payloads. */
import type { ValidatedRequest } from './validate-request.js';
import { sanitizeText } from './sanitize.js';

export function fingerprintRequest(request: ValidatedRequest): string {
  switch (request.operation) {
    case 'chat':
      return `chat:${sanitizeText(request.userMessage).toLowerCase()}`;
    case 'oracle':
      return `oracle:${request.kind}:${sanitizeText(request.userMessage).toLowerCase()}`;
    case 'dream_analysis': {
      const narrative = sanitizeText(request.payload.narrative).toLowerCase();
      return `dream:${narrative}`;
    }
    case 'coffee_analysis':
      return imageFp('coffee', request.payload);
    case 'palm_analysis':
      return imageFp('palm', request.payload, String(request.payload.hand ?? ''));
    case 'soulmate_draw':
      return `soulmate:${sanitizeText(request.name).toLowerCase()}|${request.birthDate}|${request.gender ?? ''}|${sanitizeText(request.intention ?? '').toLowerCase()}`;
    case 'tts':
      return `tts:${sanitizeText(request.text).toLowerCase()}|${request.voiceId}|${request.speechSpeed}`;
  }
}

function imageFp(
  op: string,
  payload: Record<string, unknown>,
  extra = '',
): string {
  const raw = typeof payload.imageBase64 === 'string' ? payload.imageBase64 : '';
  const len =
    typeof payload.byteLength === 'number'
      ? payload.byteLength
      : raw.length;
  if (!raw) return `${op}:0:${extra}`;
  const mid = raw.charCodeAt(Math.floor(raw.length / 2));
  return `${op}:${len}:${raw.charCodeAt(0)}:${mid}:${raw.charCodeAt(raw.length - 1)}:${extra}`;
}

export function parseIdempotencyKey(header: unknown): string | null {
  if (typeof header !== 'string') return null;
  const key = header.trim();
  if (!key || key.length > 128) return null;
  if (!/^[A-Za-z0-9._:-]+$/.test(key)) return null;
  return key;
}

export function isExpensiveOperation(operation: string): boolean {
  return (
    operation === 'coffee_analysis' ||
    operation === 'palm_analysis' ||
    operation === 'soulmate_draw' ||
    operation === 'dream_analysis'
  );
}
