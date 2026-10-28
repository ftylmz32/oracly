/**
 * App Store Server Notifications V2 for reading credits. Apple posts a
 * signed payload when it refunds or revokes a consumable; the reading
 * bought with it is then taken back from the account that owns the
 * purchase record (never from the caller — Apple is the caller). Both the
 * notification and the transaction inside it are verified with the same
 * Apple root chain the purchase verify uses; anything unverifiable changes
 * nothing.
 */
import {
  Environment,
  SignedDataVerifier,
  type JWSTransactionDecodedPayload,
} from '@apple/app-store-server-library';
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import type { AppConfig } from '../config.js';
import { readingCommerceProduct } from './reading-commerce-catalog.js';
import { purchaseIdentityId } from './reading-entitlement-ids.js';
import { PURCHASES } from './reading-entitlement-purchase-record.js';
import { noteReadingPurchaseRefund } from './reading-entitlement-refund.js';

export type AppleReadingNotification = {
  notificationType: string;
  transaction: JWSTransactionDecodedPayload;
};

export type AppleNotificationDecoder = (
  signedPayload: string,
) => Promise<AppleReadingNotification | null>;

/** Production first (only with the app's Apple ID), then Sandbox. */
export function createAppleNotificationDecoder(config: AppConfig): AppleNotificationDecoder | null {
  const bundleId = config.appleBundleId?.trim();
  if (!bundleId || config.appleRootCertificates.length === 0) return null;
  const environments: Environment[] = [];
  if (config.appleAppAppleId != null) environments.push(Environment.PRODUCTION);
  environments.push(Environment.SANDBOX);
  return async (signedPayload) => {
    for (const environment of environments) {
      try {
        const verifier = new SignedDataVerifier(
          config.appleRootCertificates,
          true,
          environment,
          bundleId,
          config.appleAppAppleId ?? undefined,
        );
        const notification = await verifier.verifyAndDecodeNotification(signedPayload);
        const signedTransaction = notification.data?.signedTransactionInfo;
        if (!notification.notificationType || !signedTransaction) return null;
        return {
          notificationType: String(notification.notificationType),
          transaction: await verifier.verifyAndDecodeTransaction(signedTransaction),
        };
      } catch {
        // Not valid for this environment; try the next.
      }
    }
    return null;
  };
}

const TAKE_BACK = new Set(['REFUND', 'REVOKE']);

export async function applyAppleReadingNotification(input: {
  store: FirestoreLike;
  bundleId: string;
  notification: AppleReadingNotification;
  atMs: number;
}): Promise<'noted' | 'already' | 'absent' | 'ignored'> {
  const { notificationType, transaction } = input.notification;
  if (!TAKE_BACK.has(notificationType)) return 'ignored';
  const productId = transaction.productId ?? '';
  const transactionId = transaction.transactionId?.trim() ?? '';
  if (!readingCommerceProduct(productId) || !transactionId) return 'ignored';
  if (transaction.bundleId && transaction.bundleId !== input.bundleId) return 'ignored';
  const snap = await input.store.collection(PURCHASES)
    .doc(purchaseIdentityId('ios', input.bundleId, transactionId))
    .get();
  const data = snap.data();
  const ownerUserId = typeof data?.ownerUserId === 'string' ? data.ownerUserId : '';
  // Not granted yet: a later verify sees the revocation in the JWS itself.
  if (!snap.exists || !data || data.alias === true || !ownerUserId) return 'absent';
  return noteReadingPurchaseRefund(input.store, {
    ownerUserId,
    platform: 'ios',
    appId: input.bundleId,
    purchaseToken: '',
    transactionId,
    atMs: input.atMs,
  });
}
