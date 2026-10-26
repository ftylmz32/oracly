/**
 * Server-owned Coffee / Palm credits. Gems never convert into these.
 * A purchase token binds to the first account. Replay does not grant again.
 */
import { randomBytes } from 'node:crypto';
import type { FirestoreLike, FirestoreTransactionLike } from '../billing/entitlement-repository.js';
import { ReadingEntitlementError } from './reading-entitlement-error.js';
import { readingDocId } from './reading-entitlement-ids.js';
import { ENTITLEMENT_LOTS, giveLot, readLots, takeLot } from './reading-entitlement-lots.js';
import { grantReadingPurchase } from './reading-entitlement-purchase.js';
import { noteReadingPurchaseRefund } from './reading-entitlement-refund.js';
import {
  READING_TRIAL_DAILY_CAP,
  type ReadingCommerceFeature,
  type ReadingCommerceProductId,
} from './reading-commerce-catalog.js';

const BALANCES = 'readingEntitlementBalances';
const HOLDS = 'readingEntitlementHolds';
const BY_OPERATION = 'readingEntitlementByOperation';
const TRIALS = 'readingEntitlementTrials';
const TRIAL_DAYS = 'readingEntitlementTrialDays';
const EVENTS = 'readingCommerceEvents';
const OPEN = 'readingEntitlementOpen';
const HOLD_LEASE_MS = 120_000;

export { ReadingEntitlementError } from './reading-entitlement-error.js';

type BalanceDoc = {
  coffee: number;
  palm: number;
  coffeePurchases: number;
  palmPurchases: number;
};

export class ReadingEntitlementLedger {
  constructor(private readonly store: FirestoreLike) {}

  async balance(ownerUserId: string): Promise<BalanceDoc> {
    const snap = await this.store.collection(BALANCES).doc(readingDocId(ownerUserId)).get();
    return readBalance(snap.data());
  }

  grantPurchase(input: {
    ownerUserId: string;
    platform: 'android' | 'ios';
    appId: string;
    productId: ReadingCommerceProductId;
    purchaseToken: string;
    transactionId: string;
    atMs: number;
  }): Promise<{ balance: BalanceDoc; idempotent: boolean }> {
    return grantReadingPurchase(this.store, input);
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
        const trialRef = this.store.collection(TRIALS).doc(readingDocId(input.ownerUserId));
        const dayRef = this.store.collection(TRIAL_DAYS).doc(day);
        const balanceRef = this.store.collection(BALANCES).doc(readingDocId(input.ownerUserId));
        if ((await tx.get(trialRef)).exists) return 'already';
        const count = numberField((await tx.get(dayRef)).data(), 'count');
        if (count >= cap) return 'capped';
        const balance = readBalance((await tx.get(balanceRef)).data());
        tx.set(dayRef, { count: count + 1 });
        tx.set(trialRef, { grantedAtMs: input.atMs });
        tx.set(balanceRef, add(balance, 'coffee', 1));
        this.writeEvent(tx, `trial:${readingDocId(input.ownerUserId)}`, {
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
    const holdId = readingDocId(`${input.ownerUserId}\0${input.sourceRequestId}`);
    return this.store.runTransaction(async (tx) => {
      const holdRef = this.store.collection(HOLDS).doc(holdId);
      const balanceRef = this.store.collection(BALANCES).doc(readingDocId(input.ownerUserId));
      const openRef = this.store.collection(OPEN).doc(readingDocId(input.ownerUserId));
      const lotsRef = this.store.collection(ENTITLEMENT_LOTS).doc(readingDocId(input.ownerUserId));
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
      const assigned = takeLot(readLots((await tx.get(lotsRef)).data()), input.feature);
      tx.set(balanceRef, add(balance, input.feature, -1));
      tx.set(lotsRef, { items: assigned.lots });
      tx.set(holdRef, {
        ownerUserId: input.ownerUserId,
        feature: input.feature,
        sourceRequestId: input.sourceRequestId,
        operationId: input.operationId,
        atMs: input.atMs,
        state: 'held',
        purchaseId: assigned.purchaseId,
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
    const snap = await this.store.collection(OPEN).doc(readingDocId(input.ownerUserId)).get();
    let restored = 0;
    let bound = 0;
    for (const item of readOpen(snap.data())) {
      if (input.nowMs - item.atMs < lease) continue;
      const operation = await input.lookup(item.operationId);
      if (operation?.ownerUserId === input.ownerUserId) {
        await this.bind(readingDocId(`${input.ownerUserId}\0${item.sourceRequestId}`), item.operationId);
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
  noteStoreRefund(input: {
    ownerUserId: string;
    platform: 'android' | 'ios';
    appId: string;
    purchaseToken: string;
    transactionId?: string;
    atMs: number;
  }): Promise<'noted' | 'absent' | 'already'> {
    return noteReadingPurchaseRefund(this.store, input);
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
        const openRef = this.store.collection(OPEN).doc(readingDocId(data.ownerUserId));
        const open = readOpen((await tx.get(openRef)).data());
        tx.set(openRef, {
          items: open.filter((item) => item.sourceRequestId !== data.sourceRequestId),
        });
      }
    });
  }

  async restoreBySource(ownerUserId: string, sourceRequestId: string): Promise<boolean> {
    return this.restoreHold(readingDocId(`${ownerUserId}\0${sourceRequestId}`), ownerUserId);
  }

  async restoreByOperation(ownerUserId: string, operationId: string): Promise<boolean> {
    const pointer = await this.store.collection(BY_OPERATION).doc(operationId).get();
    const holdId = pointer.data()?.holdId;
    if (typeof holdId !== 'string' || pointer.data()?.ownerUserId !== ownerUserId) return false;
    return this.restoreHold(holdId, ownerUserId);
  }

  /**
   * True only when this operation still holds a credit of this feature,
   * bound by the server and taken from a verified store purchase (a lot
   * with a purchaseId). Trial credits, restored or forfeited holds and
   * pointers to another account's hold are not paid proof.
   */
  async purchasedHoldFor(
    ownerUserId: string,
    operationId: string,
    feature: ReadingCommerceFeature,
  ): Promise<boolean> {
    const pointer = (await this.store.collection(BY_OPERATION).doc(operationId).get()).data();
    if (typeof pointer?.holdId !== 'string' || pointer.ownerUserId !== ownerUserId) return false;
    const hold = (await this.store.collection(HOLDS).doc(pointer.holdId).get()).data();
    return hold?.ownerUserId === ownerUserId &&
      hold.state === 'held' &&
      hold.operationId === operationId &&
      hold.feature === feature &&
      typeof hold.purchaseId === 'string' && hold.purchaseId.length > 0;
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
      if (data.state === 'restored' || data.state === 'forfeited') return false;
      if (data.state !== 'held' || (data.feature !== 'coffee' && data.feature !== 'palm')) return false;
      const balanceRef = this.store.collection(BALANCES).doc(readingDocId(ownerUserId));
      const lotsRef = this.store.collection(ENTITLEMENT_LOTS).doc(readingDocId(ownerUserId));
      const lots = readLots((await tx.get(lotsRef)).data());
      const purchaseId = typeof data.purchaseId === 'string' ? data.purchaseId : '';
      const returned = purchaseId ? giveLot(lots, purchaseId) : { lots, refunded: false };
      if (returned.refunded) {
        tx.set(holdRef, { ...data, state: 'forfeited' });
        const openRef = this.store.collection(OPEN).doc(readingDocId(ownerUserId));
        const open = readOpen((await tx.get(openRef)).data());
        tx.set(openRef, {
          items: open.filter((item) => item.sourceRequestId !== data.sourceRequestId),
        });
        return false;
      }
      tx.set(lotsRef, { items: returned.lots });
      const balance = readBalance((await tx.get(balanceRef)).data());
      tx.set(balanceRef, add(balance, data.feature, 1));
      tx.set(holdRef, { ...data, state: 'restored' });
      const openRef = this.store.collection(OPEN).doc(readingDocId(ownerUserId));
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
    tx.set(this.store.collection(EVENTS).doc(readingDocId(key)), {
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
