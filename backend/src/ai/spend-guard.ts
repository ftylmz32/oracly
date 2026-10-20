/**
 * One UTC-day spend ledger. Reservations are atomic and idempotent per key.
 * An unknown outcome keeps the reserved ceiling. It is never written down to zero.
 */
import { createHash } from 'node:crypto';
import { ErrorCode, fail } from '../errors.js';
import type { FirestoreLike } from '../billing/entitlement-repository.js';

const DAYS = 'aiSpendDays';
const HOLDS = 'aiSpendHolds';

export type SpendGuard = {
  reserve(input: { key: string; ceilingMicros: number }): Promise<void>;
  settle(input: { key: string; actualMicros: number | null }): Promise<void>;
};

export function createClosedSpendGuard(): SpendGuard {
  return {
    async reserve() {
      fail(ErrorCode.spendGuard, 503);
    },
    async settle() {},
  };
}

export class FirestoreSpendGuard implements SpendGuard {
  constructor(
    private readonly store: FirestoreLike,
    private readonly capMicros: number,
    private readonly killed: boolean,
    private readonly now: () => Date,
  ) {}

  async reserve(input: { key: string; ceilingMicros: number }): Promise<void> {
    if (this.killed || this.capMicros <= 0 || input.ceilingMicros <= 0) {
      fail(ErrorCode.spendGuard, 503);
    }
    const day = utcDay(this.now());
    const holdId = docId(input.key);
    await this.store.runTransaction(async (tx) => {
      const holdRef = this.store.collection(HOLDS).doc(holdId);
      const dayRef = this.store.collection(DAYS).doc(day);
      const hold = await tx.get(holdRef);
      if (hold.exists) return;
      const current = await tx.get(dayRef);
      const total = numberField(current.data(), 'totalMicros');
      if (total + input.ceilingMicros > this.capMicros) fail(ErrorCode.spendGuard, 503);
      tx.set(dayRef, { totalMicros: total + input.ceilingMicros, capMicros: this.capMicros, updatedAtMs: this.now().getTime() });
      tx.set(holdRef, {
        day,
        ceilingMicros: input.ceilingMicros,
        countedMicros: input.ceilingMicros,
        status: 'held',
      });
    });
  }

  async settle(input: { key: string; actualMicros: number | null }): Promise<void> {
    const holdId = docId(input.key);
    await this.store.runTransaction(async (tx) => {
      const holdRef = this.store.collection(HOLDS).doc(holdId);
      const hold = await tx.get(holdRef);
      const data = hold.data();
      if (!hold.exists || !data || data.status === 'settled') return;
      const ceiling = numberField(data, 'ceilingMicros');
      const counted = numberField(data, 'countedMicros');
      const next = input.actualMicros == null || input.actualMicros < 0 ? ceiling : input.actualMicros;
      const day = typeof data.day === 'string' ? data.day : utcDay(this.now());
      const dayRef = this.store.collection(DAYS).doc(day);
      const current = await tx.get(dayRef);
      const total = numberField(current.data(), 'totalMicros');
      tx.set(dayRef, {
        totalMicros: Math.max(0, total - counted + next),
        capMicros: this.capMicros,
        updatedAtMs: this.now().getTime(),
      });
      tx.set(holdRef, { ...data, countedMicros: next, status: 'settled' });
    });
  }
}

function utcDay(now: Date): string {
  return now.toISOString().slice(0, 10);
}

function docId(value: string): string {
  return createHash('sha256').update(value).digest('hex');
}

function numberField(data: Record<string, unknown> | undefined, key: string): number {
  const value = data?.[key];
  return typeof value === 'number' && Number.isFinite(value) ? value : 0;
}
