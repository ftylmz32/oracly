import { createHash } from 'node:crypto';

export function looksLikeOpenAiKey(token: string): boolean {
  return token.startsWith('sk-');
}

export function parseBearer(authorizationHeader: unknown): string | null {
  if (typeof authorizationHeader !== 'string') return null;
  if (!authorizationHeader.startsWith('Bearer ')) return null;
  const token = authorizationHeader.slice('Bearer '.length).trim();
  return token || null;
}

export function identityKeyFromSubject(subject: string): string {
  return `sub:${hash(subject)}`;
}

export function identityKeyFromOpaqueToken(token: string): string {
  return `tok:${hash(token)}`;
}

export function identityKeyFromIp(ip: string): string {
  return `ip:${hash(ip)}`;
}

function hash(value: string): string {
  return createHash('sha256').update(value).digest('hex').slice(0, 24);
}
