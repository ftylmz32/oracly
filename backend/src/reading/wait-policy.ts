/**
 * Central wait durations for future Coffee / Palm / Soulmate operations.
 *
 * These values are NON-COMMERCIAL development defaults. They are not
 * prices, not a Premium benefit, and not a client-controlled countdown.
 *
 * NOT APPROVED PRODUCT REQUIREMENTS. `PROVISIONAL_WAIT_MS.coffee` (2h)
 * and `.palm` (4h) below are carried-over placeholders, not a decided
 * monetization/wait-policy design — do not treat them as finalized, and
 * do not let any new code assume or hardcode their specific values
 * (client code must always derive wait/eligibility from the server's own
 * `readyAt`/`waitFinished`/`displayRemaining`, never a duration literal —
 * confirmed true of the Coffee/Palm resume mechanism as of this pass).
 * This is the ONLY file that should define these numbers; a future
 * monetization/wait-policy pass replaces them here, once, through real
 * product decisions — not by touching callers. Batch 5C+ may also swap
 * this for server-side remote configuration.
 */
import type { ReadingType } from './operation-model.js';

export const WAIT_POLICY_KIND = 'provisional_non_commercial' as const;

/** Structural hook only. This batch must not invent a Premium wait benefit. */
export type WaitModifier = {
  readonly kind: 'none';
};

export const noWaitModifier: WaitModifier = { kind: 'none' };

export type WaitPolicy = {
  readonly kind: typeof WAIT_POLICY_KIND;
  durationMs(type: ReadingType): number;
};

const HOUR_MS = 60 * 60 * 1000;

/**
 * Provisional placeholders only — not commercial wait times.
 * One duration per reading type, nowhere else.
 */
export const PROVISIONAL_WAIT_MS: Record<ReadingType, number> = {
  coffee: 2 * HOUR_MS,
  palm: 4 * HOUR_MS,
  soulmate: 8 * HOUR_MS,
};

const MIN_WAIT_MS = 1_000;
const MAX_WAIT_MS = 7 * 24 * HOUR_MS;

/**
 * BATCH 5G — Soulmate has no commercial wait today (instant generation for
 * Premium members; no gem cost, unlike Coffee/Palm's free-with-wait model).
 * Forcing PROVISIONAL_WAIT_MS.soulmate (8h) onto it would be a real,
 * undiscussed UX regression, and there is no wait number to "preserve"
 * since none exists in the live product. This is the smallest non-zero
 * value the policy allows (MIN_WAIT_MS) — Soulmate's operation still goes
 * through the real create/claim mechanism (no special-cased bypass), it
 * just never has a perceptible wait. Coffee/Palm's own durations are
 * untouched by this constant.
 */
export const SOULMATE_NO_COMMERCIAL_WAIT_MS = MIN_WAIT_MS;

export function provisionalWaitPolicy(
  overrides: Partial<Record<ReadingType, number>> = {},
): WaitPolicy {
  const durations: Record<ReadingType, number> = {
    coffee: bounded(overrides.coffee ?? PROVISIONAL_WAIT_MS.coffee),
    palm: bounded(overrides.palm ?? PROVISIONAL_WAIT_MS.palm),
    soulmate: bounded(overrides.soulmate ?? PROVISIONAL_WAIT_MS.soulmate),
  };
  return {
    kind: WAIT_POLICY_KIND,
    durationMs(type: ReadingType): number {
      return durations[type];
    },
  };
}

export function resolveWaitMs(
  type: ReadingType,
  policy: WaitPolicy = provisionalWaitPolicy(),
  modifier: WaitModifier = noWaitModifier,
): number {
  if (modifier.kind !== 'none') {
    throw new Error('unsupported_wait_modifier');
  }
  return policy.durationMs(type);
}

function bounded(value: number): number {
  if (!Number.isInteger(value) || value < MIN_WAIT_MS || value > MAX_WAIT_MS) {
    throw new Error('invalid_wait_duration');
  }
  return value;
}
