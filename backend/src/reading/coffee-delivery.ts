/**
 * Slice 4C/4D — shared Coffee terminal-delivery verdict for the durable
 * worker's Coffee V2 (three-photo) AND legacy unslotted single-photo paths.
 * (The four-view contract settles through its own typed terminal failure
 * and never reaches this module; Palm / Soulmate never use it.)
 *
 * `ReadingPipeline.coffeeV2()` and `ReadingPipeline.coffee()` return either a
 * public Coffee reading (`toPublicCoffee`: string `overall`, no `status`
 * key) or the structured `{ status: 'insufficient_semantic_signal', reason }`
 * outcome. Only the former may ever be persisted / completed. Strict
 * structural check (never a substring search over prose):
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

export const COFFEE_INSUFFICIENT_REASONS = [
  'no_safe_semantic_facets',
  'insufficient_semantic_capacity',
] as const;
export type CoffeeInsufficientReason = (typeof COFFEE_INSUFFICIENT_REASONS)[number];

export type CoffeeDeliveryVerdict =
  | { kind: 'reading' }
  | { kind: 'insufficient'; reason: CoffeeInsufficientReason; failureCode: FailureCode }
  | { kind: 'malformed'; failureCode: FailureCode };

export function classifyCoffeeDelivery(data: unknown): CoffeeDeliveryVerdict {
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
      (COFFEE_INSUFFICIENT_REASONS as readonly string[]).includes(reason) &&
      keys.length === 2 &&
      keys.includes('reason')
    ) {
      return {
        kind: 'insufficient',
        reason: reason as CoffeeInsufficientReason,
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
