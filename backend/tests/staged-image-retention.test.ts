import { describe, expect, it } from 'vitest';
import { mayDeleteExpiredStagedInput } from '../src/reading/staged-image-retention.js';

describe('staged image retention safety', () => {
  const now = 10 * 24 * 60 * 60 * 1000;
  const old = now - 25 * 60 * 60 * 1000;

  it('protects current waiting and processing operations', () => {
    expect(mayDeleteExpiredStagedInput({ status: 'waiting', updatedAtMs: now, readyAtMs: now + 1 }, now)).toBe(false);
    expect(mayDeleteExpiredStagedInput({ status: 'processing', updatedAtMs: now }, now)).toBe(false);
  });

  it('deletes missing, terminal, and demonstrably abandoned operation inputs', () => {
    expect(mayDeleteExpiredStagedInput(undefined, now)).toBe(true);
    expect(mayDeleteExpiredStagedInput({ status: 'ready', updatedAtMs: now }, now)).toBe(true);
    expect(mayDeleteExpiredStagedInput({ status: 'failed', updatedAtMs: now }, now)).toBe(true);
    expect(mayDeleteExpiredStagedInput({ status: 'processing', updatedAtMs: old }, now)).toBe(true);
    expect(mayDeleteExpiredStagedInput({ status: 'waiting', updatedAtMs: old, readyAtMs: old }, now)).toBe(true);
  });

  it('fails closed for malformed or not-yet-overdue waiting records', () => {
    expect(mayDeleteExpiredStagedInput({ status: 'unknown', updatedAtMs: old }, now)).toBe(false);
    expect(mayDeleteExpiredStagedInput({ status: 'waiting', updatedAtMs: old, readyAtMs: now }, now)).toBe(false);
  });
});
