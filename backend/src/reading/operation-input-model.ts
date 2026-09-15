/**
 * BATCH 5G — durable structured input for a ReadingOperation that needs to
 * reconstruct its own generation later (Soulmate). Never image bytes, never
 * secrets, never raw identifiers — only the small set of fields the
 * Soulmate pipeline genuinely reads. A different reading type's fields
 * would use a different allowed-key set; this file intentionally only
 * defines Soulmate's, since Coffee/Palm cannot use this (image bytes, not
 * covered — see BATCH 5F's durable-blob-storage stop condition).
 */
import type { ReadingType } from './operation-model.js';
import { Timestamp } from '@google-cloud/firestore';

export const INPUT_SCHEMA_VERSION = 1;

export const SOULMATE_INPUT_KEYS = [
  'name',
  'birthIso',
  'gender',
  'intention',
] as const;
export type SoulmateInputKey = (typeof SOULMATE_INPUT_KEYS)[number];

const MAX_LEN: Record<SoulmateInputKey, number> = {
  name: 60,
  birthIso: 10,
  gender: 16,
  intention: 200,
};

const BIRTH_ISO = /^\d{4}-\d{2}-\d{2}$/;

export type SoulmateInputFields = Partial<Record<SoulmateInputKey, string>>;

export type ReadingOperationInputRecord = {
  schemaVersion: typeof INPUT_SCHEMA_VERSION;
  operationId: string;
  ownerUserId: string;
  readingType: ReadingType;
  createdAtMs: number;
  updatedAtMs: number;
  fields: SoulmateInputFields;
};

/**
 * Rejects unknown keys outright (no unnecessary personal data smuggled
 * in), bounds every value's length, and requires the two fields the
 * pipeline cannot run without (name, birthIso — a plain YYYY-MM-DD date,
 * never a Date/JS object, never a full timestamp).
 */
export function sanitizeSoulmateFields(raw: unknown): SoulmateInputFields | null {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return null;
  const record = raw as Record<string, unknown>;
  for (const key of Object.keys(record)) {
    if (!(SOULMATE_INPUT_KEYS as readonly string[]).includes(key)) return null;
  }
  const out: SoulmateInputFields = {};
  for (const key of SOULMATE_INPUT_KEYS) {
    const value = record[key];
    if (value == null) continue;
    if (typeof value !== 'string') return null;
    const trimmed = value.trim();
    if (!trimmed) continue;
    if (trimmed.length > MAX_LEN[key]) return null;
    out[key] = trimmed;
  }
  if (!out.name) return null;
  if (!out.birthIso || !BIRTH_ISO.test(out.birthIso)) return null;
  if (out.gender != null && out.gender !== 'feminine' && out.gender !== 'masculine') {
    return null;
  }
  return out;
}

export function toStoredInputDocument(
  record: ReadingOperationInputRecord,
): Record<string, unknown> {
  return {
    schemaVersion: record.schemaVersion,
    operationId: record.operationId,
    ownerUserId: record.ownerUserId,
    readingType: record.readingType,
    createdAtMs: record.createdAtMs,
    updatedAtMs: record.updatedAtMs,
    fields: record.fields,
    expiresAt: Timestamp.fromMillis(record.updatedAtMs + 30 * 86_400_000),
  };
}

export function parseStoredInputRecord(
  data: Record<string, unknown> | undefined,
): ReadingOperationInputRecord | null {
  if (!data) return null;
  if (data.schemaVersion !== INPUT_SCHEMA_VERSION) return null;
  if (typeof data.operationId !== 'string' || data.operationId.length < 8) return null;
  if (typeof data.ownerUserId !== 'string' || data.ownerUserId.length < 4) return null;
  if (typeof data.readingType !== 'string') return null;
  if (typeof data.createdAtMs !== 'number' || typeof data.updatedAtMs !== 'number') {
    return null;
  }
  const fields = sanitizeSoulmateFields(data.fields);
  if (!fields) return null;
  return {
    schemaVersion: INPUT_SCHEMA_VERSION,
    operationId: data.operationId,
    ownerUserId: data.ownerUserId,
    readingType: data.readingType as ReadingType,
    createdAtMs: data.createdAtMs,
    updatedAtMs: data.updatedAtMs,
    fields,
  };
}
