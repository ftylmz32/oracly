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
const OPEN = 'readingEntitlementOpen';
const HOLD_LEASE_MS = 120_000;

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
          refunded: false,
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
    operationId: string;
    atMs: number;
  }): Promise<{ ok: true; holdId: string } | { ok: false; reason: 'none' | 'closed' }> {
    const holdId = docId(`${input.ownerUserId}\0${input.sourceRequestId}`);
    return this.store.runTransaction(async (tx) => {
      const holdRef = this.store.collection(HOLDS).doc(holdId);
      const balanceRef = this.store.collection(BALANCES).doc(docId(input.ownerUserId));
      const openRef = this.store.collection(OPEN).doc(docId(input.ownerUserId));
      const hold = await tx.get(holdRef);
      const current = hold.data();
      const open = readOpen((await tx.get(openRef)).data());
      const item = {
        sourceRequestId: input.sourceRequestId,
        feature: input.feature,
        operationId: input.operationId,
        atMs: input.atMs,
      };
      if (hold.exists && current?.ownerUserId === input.ownerUserId && current.feature === input.feature) {
        if (current.state === 'held') {
          tx.set(openRef, { items: upsertOpen(open, item) });
          return { ok: true as const, holdId };
        }
        return { ok: false as const, reason: 'closed' as const };
      }
      const balance = readBalance((await tx.get(balanceRef)).data());
      if (balance[input.feature] < 1) return { ok: false as const, reason: 'none' as const };
      tx.set(balanceRef, add(balance, input.feature, -1));
      tx.set(holdRef, {
        ownerUserId: input.ownerUserId,
        feature: input.feature,
        sourceRequestId: input.sourceRequestId,
        operationId: input.operationId,
        atMs: input.atMs,
        state: 'held',
      });
      tx.set(openRef, { items: upsertOpen(open, item) });
      return { ok: true as const, holdId };
    });
  }

  /**
   * A hold with no operation is an interrupted create. After the lease,
   * bind it when the operation exists, otherwise return the credit.
   * This is not a store refund.
   */
  async reconcile(input: {
    ownerUserId: string;
    nowMs: number;
    leaseMs?: number;
    lookup: (operationId: string) => Promise<{ ownerUserId: string } | null>;
  }): Promise<{ restored: number; bound: number }> {
    const lease = input.leaseMs ?? HOLD_LEASE_MS;
    const snap = await this.store.collection(OPEN).doc(docId(input.ownerUserId)).get();
    let restored = 0;
    let bound = 0;
    for (const item of readOpen(snap.data())) {
      if (input.nowMs - item.atMs < lease) continue;
      const operation = await input.lookup(item.operationId);
      if (operation?.ownerUserId === input.ownerUserId) {
        await this.bind(docId(`${input.ownerUserId}\0${item.sourceRequestId}`), item.operationId);
        bound += 1;
      } else if (await this.restoreBySource(input.ownerUserId, item.sourceRequestId)) {
        restored += 1;
      }
    }
    return { restored, bound };
  }

  /**
   * The store reversed the charge. Unused credits drop. A reading already
   * opened from this purchase is left alone. Not `entitlement_restored`.
   */
  async noteStoreRefund(input: {
    ownerUserId: string;
    platform: 'android' | 'ios';
    purchaseToken: string;
    atMs: number;
  }): Promise<'noted' | 'absent' | 'already'> {
    const purchaseId = docId(`${input.platform}\0${input.purchaseToken.trim()}`);
    return this.store.runTransaction(async (tx) => {
      const purchaseRef = this.store.collection(PURCHASES).doc(purchaseId);
      const purchase = await tx.get(purchaseRef);
      const data = purchase.data();
      if (!purchase.exists || !data) return 'absent' as const;
      if (data.ownerUserId !== input.ownerUserId) throw new ReadingEntitlementError('owned_by_other');
      if (data.refunded === true) return 'already' as const;
      const feature = data.feature === 'palm' ? 'palm' : 'coffee';
      const units = numberField(data, 'units');
      const balanceRef = this.store.collection(BALANCES).doc(docId(input.ownerUserId));
      const balance = readBalance((await tx.get(balanceRef)).data());
      const drop = Math.min(units, balance[feature]);
      tx.set(balanceRef, add(balance, feature, -drop));
      tx.set(purchaseRef, { ...data, refunded: true });
      this.writeEvent(tx, `store-refund:${purchaseId}`, {
        name: 'store_refund',
        feature,
        productId: typeof data.productId === 'string' ? data.productId : null,
        proposedTryMinor: null,
        atMs: input.atMs,
      });
      return 'noted' as const;
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
      if (typeof data.ownerUserId === 'string' && typeof data.sourceRequestId === 'string') {
        const openRef = this.store.collection(OPEN).doc(docId(data.ownerUserId));
        const open = readOpen((await tx.get(openRef)).data());
        tx.set(openRef, {
          items: open.filter((item) => item.sourceRequestId !== data.sourceRequestId),
        });
      }
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
      const openRef = this.store.collection(OPEN).doc(docId(ownerUserId));
      const open = readOpen((await tx.get(openRef)).data());
      tx.set(openRef, {
        items: open.filter((item) => item.sourceRequestId !== data.sourceRequestId),
      });
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

type OpenItem = {
  sourceRequestId: string;
  feature: ReadingCommerceFeature;
  operationId: string;
  atMs: number;
};

function readOpen(data: Record<string, unknown> | undefined): OpenItem[] {
  const items = data?.items;
  if (!Array.isArray(items)) return [];
  return items.flatMap((raw) => {
    if (!raw || typeof raw !== 'object') return [];
    const item = raw as Record<string, unknown>;
    if (typeof item.sourceRequestId !== 'string' || typeof item.operationId !== 'string') return [];
    if (item.feature !== 'coffee' && item.feature !== 'palm') return [];
    if (typeof item.atMs !== 'number') return [];
    return [{
      sourceRequestId: item.sourceRequestId,
      feature: item.feature,
      operationId: item.operationId,
      atMs: item.atMs,
    }];
  });
}

function upsertOpen(items: OpenItem[], next: OpenItem): OpenItem[] {
  return [...items.filter((item) => item.sourceRequestId !== next.sourceRequestId), next];
}

function docId(value: string): string {
  return createHash('sha256').update(value).digest('hex');
}
