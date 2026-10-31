/**
 * Freemium V1 (dark): AI spend by access tier, on top of the existing day
 * guard. A reading-operation reservation is classed by how its operation
 * was opened (free / Premium / credit); a free one must also fit the free
 * share of the day's ceiling. The wrapped guard keeps its own ceiling and
 * records unchanged, and a refused reservation is the existing
 * `spend_guard` outcome. The provider request itself is never touched.
 */
import { createHash } from 'node:crypto';
import type { SpendGuard } from '../ai/spend-guard.js';
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import type { AppConfig } from '../config.js';
import { ErrorCode, fail } from '../errors.js';
import {
  FREEMIUM_SPEND_DAYS,
  freemiumAccessFor,
  freeSpendCapMicros,
  type FreemiumTier,
} from './freemium-access.js';

const HOLDS = 'freemiumSpendHolds';
const OPERATION_KEY = /^reading-operation:([A-Za-z0-9._-]{8,128}):/;

/** The guard unchanged unless Freemium V1 is on and a store exists. */
export function withFreemiumSpend(
  config: AppConfig,
  guard: SpendGuard | null,
  store: FirestoreLike | null | undefined,
  now: () => Date,
): SpendGuard | null {
  if (!guard || !store || !config.freemiumV1Enabled) return guard;
  return new FreemiumSpendGuard(guard, store, freeSpendCapMicros(config), now);
}

export class FreemiumSpendGuard implements SpendGuard {
  constructor(
    private readonly base: SpendGuard,
    private readonly store: FirestoreLike,
    private readonly freeCapMicros: number,
    private readonly now: () => Date,
  ) {}

  async reserve(input: { key: string; ceilingMicros: number }): Promise<void> {
    const tier = await this.tierOf(input.key);
    if (!tier) return this.base.reserve(input);
    const added = await this.hold(input.key, tier, input.ceilingMicros);
    try {
      await this.base.reserve(input);
    } catch (error) {
      if (added) await this.release(input.key).catch(() => undefined);
      throw error;
    }
  }

  async settle(input: { key: string; actualMicros: number | null }): Promise<void> {
    await this.base.settle(input);
    if (!OPERATION_KEY.test(input.key)) return;
    const holdRef = this.store.collection(HOLDS).doc(docId(input.key));
    await this.store.runTransaction(async (tx) => {
      const data = (await tx.get(holdRef)).data();
      if (!data || data.status !== 'held' || !isTier(data.tier) || typeof data.day !== 'string') return;
      const ceiling = numberField(data, 'ceilingMicros');
      const counted = numberField(data, 'countedMicros');
      // An unknown outcome keeps the reserved ceiling, like the day guard.
      const next = input.actualMicros == null || input.actualMicros < 0 ? ceiling : input.actualMicros;
      const dayRef = this.store.collection(FREEMIUM_SPEND_DAYS).doc(data.day);
      const day = (await tx.get(dayRef)).data() ?? {};
      const field = tierField(data.tier);
      tx.set(dayRef, {
        ...day,
        [field]: Math.max(0, numberField(day, field) - counted + next),
        updatedAtMs: this.now().getTime(),
      });
      tx.set(holdRef, { ...data, countedMicros: next, status: 'settled' });
    });
  }

  private async tierOf(key: string): Promise<FreemiumTier | null> {
    const match = OPERATION_KEY.exec(key);
    if (!match) return null;
    try {
      return (await freemiumAccessFor(this.store, match[1]))?.tier ?? null;
    } catch {
      // Unknown class: refuse rather than spend outside the free share.
      fail(ErrorCode.spendGuard, 503);
    }
  }

  private async hold(key: string, tier: FreemiumTier, ceilingMicros: number): Promise<boolean> {
    const holdRef = this.store.collection(HOLDS).doc(docId(key));
    const dayKey = this.now().toISOString().slice(0, 10);
    const dayRef = this.store.collection(FREEMIUM_SPEND_DAYS).doc(dayKey);
    return this.store.runTransaction(async (tx) => {
      if ((await tx.get(holdRef)).exists) return false;
      const day = (await tx.get(dayRef)).data() ?? {};
      const field = tierField(tier);
      const total = numberField(day, field);
      if (tier === 'free' && total + ceilingMicros > this.freeCapMicros) fail(ErrorCode.spendGuard, 503);
      tx.set(dayRef, {
        ...day,
        [field]: total + ceilingMicros,
        freeCapMicros: this.freeCapMicros,
        updatedAtMs: this.now().getTime(),
      });
      tx.set(holdRef, { day: dayKey, tier, ceilingMicros, countedMicros: ceilingMicros, status: 'held' });
      return true;
    });
  }

  private async release(key: string): Promise<void> {
    const holdRef = this.store.collection(HOLDS).doc(docId(key));
    await this.store.runTransaction(async (tx) => {
      const data = (await tx.get(holdRef)).data();
      if (!data || data.status !== 'held' || !isTier(data.tier) || typeof data.day !== 'string') return;
      const dayRef = this.store.collection(FREEMIUM_SPEND_DAYS).doc(data.day);
      const day = (await tx.get(dayRef)).data() ?? {};
      const field = tierField(data.tier);
      tx.set(dayRef, {
        ...day,
        [field]: Math.max(0, numberField(day, field) - numberField(data, 'countedMicros')),
        updatedAtMs: this.now().getTime(),
      });
      tx.delete(holdRef);
    });
  }
}

function tierField(tier: FreemiumTier): string {
  return `${tier}Micros`;
}

function isTier(value: unknown): value is FreemiumTier {
  return value === 'free' || value === 'premium' || value === 'credit';
}

function docId(value: string): string {
  return createHash('sha256').update(value).digest('hex');
}

function numberField(data: Record<string, unknown> | undefined, key: string): number {
  const value = data?.[key];
  return typeof value === 'number' && Number.isFinite(value) ? value : 0;
}
