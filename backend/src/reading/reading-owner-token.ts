/**
 * The account a reading purchase was launched for, as the stores echo it:
 * StoreKit 2 `appAccountToken`, Play `obfuscatedExternalAccountId`. A
 * name-based UUID (version 5 layout over SHA-256 of the Firebase uid),
 * byte for byte the Flutter `ReadingOwnerToken.forUid`. Never reversible.
 */
import { createHash } from 'node:crypto';

export function readingOwnerToken(uid: string): string {
  const bytes = createHash('sha256')
    .update(`oracly.reading.owner:${uid}`, 'utf8')
    .digest()
    .subarray(0, 16);
  bytes[6] = (bytes[6]! & 0x0f) | 0x50;
  bytes[8] = (bytes[8]! & 0x3f) | 0x80;
  const hex = bytes.toString('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-`
    + `${hex.slice(16, 20)}-${hex.slice(20)}`;
}

/** StoreKit upper-cases UUIDs; compare as the client does. */
export function normalizeReadingOwnerToken(raw: unknown): string | null {
  if (typeof raw !== 'string') return null;
  const value = raw.trim().toLowerCase();
  return value ? value : null;
}
