/**
 * Server-owned Coffee / Palm credits. Gems never convert into these.
 * A purchase token binds to the first account. Replay does not grant again.
 */
import { createHash, randomBytes } from 'node:crypto';
import type { FirestoreLike, FirestoreTransactionLike } from '../billing/entitlement-repository.js';
import {
  READING_TRIAL_DAILY_CAP,
  readingCommerceProduct,
  type ReadingCommerceFeature,
  type ReadingCommerceProductId,
} from './reading-commerce-catalog.js';

const BALANCES = 'readingEntitlementBalances';
const PURCHASES = 'readingEntitlementPurchases';
const HOLDS = 'readingEntitlementHolds';
const BY_OPERATION = 'readingEntitlementByOperation';
const TRIALS = 'readingEntitlementTrials';
const TRIAL_DAYS = 'readingEntitlementTrialDays';
const EVENTS = 'readingCommerceEvents';

export class ReadingEntitlementError extends Error {
  constructor(readonly code: 'owned_by_other' | 'invalid' | 'unavailable') {
    super(code);
    this.name = 'ReadingEntitlementError';
  }
}

type BalanceDoc = {
  coffee: number;
  palm: number;
  coffeePurchases: number;
  palmPurchases: number;
};

export class ReadingEntitlementLedger {
  constructor(private readonly store: FirestoreLike) {}

  async balance(ownerUserId: string): Promise<BalanceDoc> {
    const snap = await this.store.collection(BALANCES).doc(docId(ownerUserId)).get();
    return readBalance(snap.data());
  }

  async grantPurchase(input: {
    ownerUserId: string;
    platform: 'android' | 'ios';
    productId: ReadingCommerceProductId;
    purchaseToken: string;
    transactionId: string;
    atMs: number;
  }): Promise<{ balance: BalanceDoc; idempotent: boolean }> {
    const product = readingCommerceProduct(input.productId);
    if (!product || !input.purchaseToken.trim() || !input.transactionId.trim()) {
      throw new ReadingEntitlementError('invalid');
    }
    const purchaseId = docId(`${input.platform}\0${input.purchaseToken.trim()}`);
    try {
      return await this.store.runTransaction(async (tx) => {
        const purchaseRef = this.store.collection(PURCHASES).doc(purchaseId);
        const balanceRef = this.store.collection(BALANCES).doc(docId(input.ownerUserId));
        const existing = await tx.get(purchaseRef);
        const bound = existing.data();
        if (existing.exists && bound?.ownerUserId !== input.ownerUserId) {
          throw new ReadingEntitlementError('owned_by_other');
        }
        const balance = readBalance((await tx.get(balanceRef)).data());
        if (existing.exists) return { balance, idempotent: true };
        const next = add(balance, product.feature, product.grants);
        const purchases = product.feature === 'coffee' ? balance.coffeePurchases : balance.palmPurchases;
        next[product.feature === 'coffee' ? 'coffeePurchases' : 'palmPurchases'] = purchases + 1;
        tx.set(balanceRef, next);
        tx.set(purchaseRef, {
          ownerUserId: input.ownerUserId,
          productId: input.productId,
          feature: product.feature,
          units: product.grants,
          transactionId: input.transactionId,
        });
        this.writeEvent(tx, `purchase:${purchaseId}`, {
          name: 'purchase_completed',
          feature: product.feature,
          productId: input.productId,
          proposedTryMinor: product.proposedTryMinor,
          atMs: input.atMs,
        });
        if (purchases >= 1) {
          this.writeEvent(tx, `repurchase:${purchaseId}`, {
            name: 'repurchase',
            feature: product.feature,
            productId: input.productId,
            proposedTryMinor: product.proposedTryMinor,
            atMs: input.atMs,
          });
        }
        return { balance: next, idempotent: false };
      });
    } catch (error) {
      if (error instanceof ReadingEntitlementError) throw error;
      throw new ReadingEntitlementError('unavailable');
    }
  }

  async grantTrial(input: {
    ownerUserId: string;
    atMs: number;
    dailyCap?: number;
  }): Promise<'granted' | 'already' | 'capped'> {
    const cap = input.dailyCap ?? READING_TRIAL_DAILY_CAP;
    const day = new Date(input.atMs).toISOString().slice(0, 10);
    try {
      return await this.store.runTransaction(async (tx) => {
        const trialRef = this.store.collection(TRIALS).doc(docId(input.ownerUserId));
        const dayRef = this.store.collection(TRIAL_DAYS).doc(day);
        const balanceRef = this.store.collection(BALANCES).doc(docId(input.ownerUserId));
        if ((await tx.get(trialRef)).exists) return 'already';
        const count = numberField((await tx.get(dayRef)).data(), 'count');
        if (count >= cap) return 'capped';
        const balance = readBalance((await tx.get(balanceRef)).data());
        tx.set(dayRef, { count: count + 1 });
        tx.set(trialRef, { grantedAtMs: input.atMs });
        tx.set(balanceRef, add(balance, 'coffee', 1));
        this.writeEvent(tx, `trial:${docId(input.ownerUserId)}`, {
          name: 'trial_granted',
          feature: 'coffee',
          productId: null,
          proposedTryMinor: null,
          atMs: input.atMs,
        });
        return 'granted';
      });
    } catch (error) {
      if (error instanceof ReadingEntitlementError) throw error;
      throw new ReadingEntitlementError('unavailable');
    }
  }

  async consume(input: {
    ownerUserId: string;
    feature: ReadingCommerceFeature;
    sourceRequestId: string;
  }): Promise<{ ok: true; holdId: string } | { ok: false; reason: 'none' | 'closed' }> {
    const holdId = docId(`${input.ownerUserId}\0${input.sourceRequestId}`);
    return this.store.runTransaction(async (tx) => {
      const holdRef = this.store.collection(HOLDS).doc(holdId);
      const balanceRef = this.store.collection(BALANCES).doc(docId(input.ownerUserId));
      const hold = await tx.get(holdRef);
      const current = hold.data();
      if (hold.exists && current?.ownerUserId === input.ownerUserId && current.feature === input.feature) {
        if (current.state === 'held') return { ok: true as const, holdId };
        return { ok: false as const, reason: 'closed' as const };
      }
      const balance = readBalance((await tx.get(balanceRef)).data());
      if (balance[input.feature] < 1) return { ok: false as const, reason: 'none' as const };
      tx.set(balanceRef, add(balance, input.feature, -1));
      tx.set(holdRef, {
        ownerUserId: input.ownerUserId,
        feature: input.feature,
        sourceRequestId: input.sourceRequestId,
        operationId: null,
        state: 'held',
      });
      return { ok: true as const, holdId };
    });
  }

  async bind(holdId: string, operationId: string): Promise<void> {
    await this.store.runTransaction(async (tx) => {
      const holdRef = this.store.collection(HOLDS).doc(holdId);
      const hold = await tx.get(holdRef);
      const data = hold.data();
      if (!hold.exists || !data || data.state !== 'held') return;
      tx.set(holdRef, { ...data, operationId });
      tx.set(this.store.collection(BY_OPERATION).doc(operationId), {
        holdId,
        ownerUserId: data.ownerUserId,
      });
    });
  }

  async restoreBySource(ownerUserId: string, sourceRequestId: string): Promise<boolean> {
    return this.restoreHold(docId(`${ownerUserId}\0${sourceRequestId}`), ownerUserId);
  }

  async restoreByOperation(ownerUserId: string, operationId: string): Promise<boolean> {
    const pointer = await this.store.collection(BY_OPERATION).doc(operationId).get();
    const holdId = pointer.data()?.holdId;
    if (typeof holdId !== 'string' || pointer.data()?.ownerUserId !== ownerUserId) return false;
    return this.restoreHold(holdId, ownerUserId);
  }

  async noteCompleted(ownerUserId: string, operationId: string, atMs: number): Promise<void> {
    const pointer = await this.store.collection(BY_OPERATION).doc(operationId).get();
    if (pointer.data()?.ownerUserId !== ownerUserId) return;
    await this.store.runTransaction(async (tx) => {
      this.writeEvent(tx, `completed:${operationId}`, {
        name: 'reading_completed',
        feature: null,
        productId: null,
        proposedTryMinor: null,
        atMs,
      });
    });
  }

  private async restoreHold(holdId: string, ownerUserId: string): Promise<boolean> {
    return this.store.runTransaction(async (tx) => {
      const holdRef = this.store.collection(HOLDS).doc(holdId);
      const hold = await tx.get(holdRef);
      const data = hold.data();
      if (!hold.exists || !data || data.ownerUserId !== ownerUserId) return false;
      if (data.state === 'restored') return false;
      if (data.state !== 'held' || (data.feature !== 'coffee' && data.feature !== 'palm')) return false;
      const balanceRef = this.store.collection(BALANCES).doc(docId(ownerUserId));
      const balance = readBalance((await tx.get(balanceRef)).data());
      tx.set(balanceRef, add(balance, data.feature, 1));
      tx.set(holdRef, { ...data, state: 'restored' });
      this.writeEvent(tx, `restored:${holdId}:${randomBytes(4).toString('hex')}`, {
        name: 'entitlement_restored',
        feature: data.feature,
        productId: null,
        proposedTryMinor: null,
        atMs: Date.now(),
      });
      return true;
    });
  }

  private writeEvent(
    tx: FirestoreTransactionLike,
    key: string,
    event: {
      name: string;
      feature: ReadingCommerceFeature | null;
      productId: string | null;
      proposedTryMinor: number | null;
      atMs: number;
    },
  ): void {
    tx.set(this.store.collection(EVENTS).doc(docId(key)), {
      name: event.name,
      feature: event.feature,
      productId: event.productId,
      proposedTryMinor: event.proposedTryMinor,
      storeCutKnown: false,
      storeCutMicros: null,
      aiCostMicros: null,
      atMs: event.atMs,
    });
  }
}

function add(balance: BalanceDoc, feature: ReadingCommerceFeature, delta: number): BalanceDoc {
  return { ...balance, [feature]: balance[feature] + delta };
}

function readBalance(data: Record<string, unknown> | undefined): BalanceDoc {
  return {
    coffee: count(data, 'coffee'),
    palm: count(data, 'palm'),
    coffeePurchases: count(data, 'coffeePurchases'),
    palmPurchases: count(data, 'palmPurchases'),
  };
}

function count(data: Record<string, unknown> | undefined, key: string): number {
  const value = data?.[key];
  return typeof value === 'number' && Number.isInteger(value) && value > 0 ? value : 0;
}

function numberField(data: Record<string, unknown> | undefined, key: string): number {
  const value = data?.[key];
  return typeof value === 'number' && Number.isInteger(value) && value >= 0 ? value : 0;
}

function docId(value: string): string {
  return createHash('sha256').update(value).digest('hex');
}
