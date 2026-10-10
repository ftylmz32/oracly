/**
 * Slice 4C — Coffee V2 terminal-delivery verdict.
 *
 * `ReadingPipeline.coffeeV2()` returns either a public Coffee reading
 * (`toPublicCoffee`: string `overall`, no `status` key) or the structured
 * `{ status: 'insufficient_semantic_signal', reason }` outcome. Only the
 * former may ever be persisted / completed. This is a strict structural
 * check (never a substring search over prose):
 *
 * - exactly `{ status, reason }` with an allow-listed reason → `insufficient`
 *   (terminal `invalid`, the same code Coffee V3 uses for insufficient
 *   meaning);
 * - any other shape carrying `status`, a non-object, or a missing / blank
 *   string `overall` → `malformed` (terminal `unavailable`: fail closed,
 *   never a fabricated reading);
 * - otherwise → `reading` (unchanged success path).
 */
import type { FailureCode } from './operation-model.js';

export const COFFEE_V2_INSUFFICIENT_REASONS = [
  'no_safe_semantic_facets',
  'insufficient_semantic_capacity',
] as const;
export type CoffeeV2InsufficientReason = (typeof COFFEE_V2_INSUFFICIENT_REASONS)[number];

export type CoffeeV2DeliveryVerdict =
  | { kind: 'reading' }
  | { kind: 'insufficient'; reason: CoffeeV2InsufficientReason; failureCode: FailureCode }
  | { kind: 'malformed'; failureCode: FailureCode };

export function classifyCoffeeV2Delivery(data: unknown): CoffeeV2DeliveryVerdict {
  if (!data || typeof data !== 'object' || Array.isArray(data)) {
    return { kind: 'malformed', failureCode: 'unavailable' };
  }
  const record = data as Record<string, unknown>;
  if (Object.prototype.hasOwnProperty.call(record, 'status')) {
    const keys = Object.keys(record);
    const reason = record.reason;
    if (
      record.status === 'insufficient_semantic_signal' &&
      typeof reason === 'string' &&
      (COFFEE_V2_INSUFFICIENT_REASONS as readonly string[]).includes(reason) &&
      keys.length === 2 &&
      keys.includes('reason')
    ) {
      return {
        kind: 'insufficient',
        reason: reason as CoffeeV2InsufficientReason,
        failureCode: 'invalid',
      };
    }
    return { kind: 'malformed', failureCode: 'unavailable' };
  }
  if (typeof record.overall !== 'string' || record.overall.trim().length === 0) {
    return { kind: 'malformed', failureCode: 'unavailable' };
  }
  return { kind: 'reading' };
}
