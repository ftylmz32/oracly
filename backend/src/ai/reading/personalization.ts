/**
 * BATCH 3A.1 — parses the small, optional, bounded personalization object
 * out of a Coffee/Palm request payload. Every field is capped and
 * sanitized; nothing here is ever large enough to be a raw Journal/memory
 * dump, and a missing/malformed object never blocks a reading — it just
 * resolves to "no personalization available".
 */

import { asRecord, sanitizeText, stringList } from '../sanitize.js';
import type { ReadingPersonalization } from './types.js';

const MAX_NAME = 40;
const MAX_INTENTION = 200;
const MAX_MEMORY_SUMMARY = 220;
const MAX_THEMES = 3;
const MAX_THEME_LEN = 40;

export function personalizationFromUnknown(
  payload: unknown,
): ReadingPersonalization | undefined {
  const record = asRecord(payload);
  const raw = asRecord(record?.personalization);
  if (!raw) return undefined;

  const firstName = sanitizeText(raw.firstName, MAX_NAME) || undefined;
  const intention = sanitizeText(raw.intention, MAX_INTENTION) || undefined;
  const memorySummary =
    sanitizeText(raw.memorySummary, MAX_MEMORY_SUMMARY) || undefined;
  const relevantThemes = stringList(raw.relevantThemes, MAX_THEMES).map((t) =>
    t.slice(0, MAX_THEME_LEN),
  );

  if (
    !firstName &&
    !intention &&
    !memorySummary &&
    relevantThemes.length === 0
  ) {
    return undefined;
  }

  return {
    ...(firstName ? { firstName } : {}),
    ...(intention ? { intention } : {}),
    ...(relevantThemes.length > 0 ? { relevantThemes } : {}),
    ...(memorySummary ? { memorySummary } : {}),
  };
}
