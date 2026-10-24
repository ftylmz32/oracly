/**
 * Play Console refunds do not return to a consumed purchase.
 * The next catalog read applies Voided Purchases once per order.
 */
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import { purchaseIdentityId } from './reading-entitlement-ids.js';
import { noteReadingPurchaseRefund } from './reading-entitlement-refund.js';
import { PURCHASES } from './reading-entitlement-purchase-record.js';
import { playVoidedPurchasesUrl, readVoidedPurchases } from './reading-consumable-play.js';

export type VoidedReadingPurchase = { orderId: string; purchaseToken: string };

export async function listPlayVoidedPurchases(input: {
  fetchImpl: typeof fetch;
  packageName: string;
  accessToken: string;
}): Promise<VoidedReadingPurchase[] | null> {
  const rows: VoidedReadingPurchase[] = [];
  let pageToken = '';
  for (let page = 0; page < 3; page += 1) {
    const response = await input.fetchImpl(
      playVoidedPurchasesUrl(input.packageName, pageToken),
      { headers: { authorization: `Bearer ${input.accessToken}` } },
    );
    if (!response.ok) return null;
    const body = await response.json() as { tokenPagination?: { nextPageToken?: string } };
    rows.push(...readVoidedPurchases(body));
    pageToken = body.tokenPagination?.nextPageToken ?? '';
    if (!pageToken) break;
  }
  return rows;
}

export async function syncVoidedReadingPurchases(input: {
  store: FirestoreLike;
  ownerUserId: string;
  appId: string;
  atMs: number;
  voided: VoidedReadingPurchase[];
}): Promise<{ noted: number; already: number; skipped: number }> {
  let noted = 0;
  let already = 0;
  let skipped = 0;
  const seen = new Set<string>();
  for (const item of input.voided) {
    const orderId = item.orderId.trim();
    if (!orderId || seen.has(orderId)) {
      skipped += 1;
      continue;
    }
    seen.add(orderId);
    const snap = await input.store.collection(PURCHASES).doc(
      purchaseIdentityId('android', input.appId, orderId),
    ).get();
    const data = snap.data();
    if (!snap.exists || !data || data.alias === true || data.ownerUserId !== input.ownerUserId) {
      skipped += 1;
      continue;
    }
    const result = await noteReadingPurchaseRefund(input.store, {
      ownerUserId: input.ownerUserId,
      platform: 'android',
      appId: input.appId,
      purchaseToken: item.purchaseToken,
      transactionId: orderId,
      atMs: input.atMs,
    });
    if (result === 'noted') noted += 1;
    else if (result === 'already') already += 1;
    else skipped += 1;
  }
  return { noted, already, skipped };
}
