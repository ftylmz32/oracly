/**
 * Dark reading-credit catalog, trial, and consumable verification.
 * Closed unless the commerce flag is on. The live store verifier grants
 * nothing until products are admitted. Client prices are rejected.
 */
import { createHash } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import type { AppCheckVerifier } from '../auth/app-check.js';
import { createAppCheckVerifier } from '../auth/app-check.js';
import { createAuthenticationService } from '../auth/create-auth.js';
import type { FirestoreLike } from '../billing/entitlement-repository.js';
import type { AppConfig } from '../config.js';
import { ErrorCode, errorEnvelope, successEnvelope } from '../errors.js';
import { requireAppCheck } from '../middleware/app-check.js';
import { requireAuth } from '../middleware/auth.js';
import { systemClock, toEpochMs, type ServerClock } from '../reading/clock.js';
import {
  readingCommerceProduct,
  readingCommerceProposals,
  type ReadingCommerceProductId,
} from '../reading/reading-commerce-catalog.js';
import { billingQaRejectsPurchase, catalogPurchasable } from '../reading/reading-billing-qa.js';
import { readingOwnerToken } from '../reading/reading-owner-token.js';
import {
  applyAppleReadingNotification,
  createAppleNotificationDecoder,
  type AppleNotificationDecoder,
} from '../reading/reading-apple-notifications.js';
import { syncVoidedReadingPurchases } from '../reading/reading-voided-sync.js';
import { readingBudgetOpen, readingFulfillmentOpen } from '../reading/reading-commerce-gate.js';
import {
  ReadingEntitlementError,
  ReadingEntitlementLedger,
} from '../reading/reading-entitlement-ledger.js';
import {
  createClosedConsumableVerifier,
  type ConsumableVerifier,
} from '../reading/reading-commerce-verify.js';

const PRICE_KEYS = ['price', 'priceMinor', 'amount', 'currency', 'grants', 'cost'];

/**
 * The store names the buyer; the authenticated subject is authoritative.
 * StoreKit 2 always carries the app's owner token, so an iOS purchase
 * without one, or for another account, is refused. Play purchases launched
 * before owner tags carry none and stay accepted; a Play tag for another
 * account is refused.
 */
export function readingOwnerRefusal(
  platform: 'android' | 'ios',
  accountTag: string | null | undefined,
  authSubject: string | undefined,
): 'owner_unproven' | 'purchase_bound_to_other_account' | null {
  const subject = authSubject?.trim() ?? '';
  if (platform === 'ios') {
    if (!subject || !accountTag) return 'owner_unproven';
    return accountTag === readingOwnerToken(subject)
      ? null
      : 'purchase_bound_to_other_account';
  }
  if (accountTag && subject && accountTag !== readingOwnerToken(subject)) {
    return 'purchase_bound_to_other_account';
  }
  return null;
}

function commerceAppId(config: AppConfig, platform: 'android' | 'ios'): string {
  const bundle = platform === 'ios' ? config.appleBundleId?.trim() : '';
  return bundle || config.playPackageName.trim();
}

export type ReadingCommerceRouteOptions = {
  appCheck?: AppCheckVerifier;
  store?: FirestoreLike;
  clock?: ServerClock;
  verifier?: ConsumableVerifier;
  lookupOperation?: (ownerUserId: string, operationId: string) => Promise<{ ownerUserId: string } | null>;
  /** Verifies App Store Server Notifications; `null` = not configured. */
  appleNotifications?: AppleNotificationDecoder | null;
};

export async function registerReadingCommerceRoutes(
  app: FastifyInstance,
  config: AppConfig,
  options: ReadingCommerceRouteOptions = {},
): Promise<void> {
  const auth = requireAuth(createAuthenticationService(config));
  const appCheck = requireAppCheck(options.appCheck ?? createAppCheckVerifier(config));
  const clock = options.clock ?? systemClock();
  const verifier = options.verifier ?? createClosedConsumableVerifier();
  const ledger = options.store ? new ReadingEntitlementLedger(options.store) : null;

  app.get('/v1/reading-entitlements/catalog', { preHandler: [auth, appCheck] }, async (request, reply) => {
    const owner = request.identityKey;
    if (!owner) return reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
    if (!config.readingCommerceEnabled || !options.store || !ledger) {
      return reply.code(200).send(successEnvelope({ commerce: 'closed', purchasable: false, storeAdmitted: false }));
    }
    const nowMs = toEpochMs(clock.now());
    const budgetOpen = await readingBudgetOpen(options.store, config, nowMs);
    const purchasable = catalogPurchasable({
      admitted: verifier.admitted,
      budgetOpen,
      billingQa: config.readingBillingQa,
    });
    if (options.lookupOperation) {
      await ledger.reconcile({
        ownerUserId: owner,
        nowMs,
        lookup: (operationId) => options.lookupOperation!(owner, operationId),
      });
    }
    if (verifier.listVoided) {
      try {
        const voided = await verifier.listVoided();
        if (voided) {
          await syncVoidedReadingPurchases({
            store: options.store,
            ownerUserId: owner,
            appId: commerceAppId(config, 'android'),
            atMs: nowMs,
            voided,
          });
        }
      } catch {
        // A missed voided list must not change a balance.
      }
    }
    const store = options.store;
    await store.runTransaction(async (tx) => {
      tx.set(store.collection('readingCommerceEvents').doc(createHash('sha256').update(`shown\0${owner}\0${nowMs}`).digest('hex')), {
        name: 'price_shown',
        feature: null,
        productId: null,
        proposedTryMinor: null,
        storeCutKnown: false,
        storeCutMicros: null,
        aiCostMicros: null,
        atMs: nowMs,
      });
    });
    return reply.code(200).send(successEnvelope({
      commerce: 'open',
      purchasable,
      storeAdmitted: verifier.admitted,
      androidAdmitted: verifier.androidAdmitted === true,
      iosAdmitted: verifier.iosAdmitted === true,
      fulfillmentOpen: readingFulfillmentOpen(config) && budgetOpen,
      billingQa: config.readingBillingQa,
      proposals: readingCommerceProposals(),
      balance: await ledger.balance(owner),
    }));
  });

  app.post('/v1/reading-entitlements/verify', { preHandler: [auth, appCheck] }, async (request, reply) => {
    const owner = request.identityKey;
    if (!owner) return reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
    const body = request.body;
    if (!body || typeof body !== 'object' || Array.isArray(body)) {
      return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
    }
    const record = body as Record<string, unknown>;
    if (PRICE_KEYS.some((key) => Object.prototype.hasOwnProperty.call(record, key))) {
      return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
    }
    if (!config.readingCommerceEnabled || !ledger) {
      return reply.code(200).send(successEnvelope({ granted: false, reason: 'commerce_closed' }));
    }
    const productId = typeof record.productId === 'string' ? record.productId.trim() : '';
    const product = readingCommerceProduct(productId);
    const platform = record.platform === 'android' || record.platform === 'ios' ? record.platform : null;
    const purchaseToken = typeof record.purchaseToken === 'string' ? record.purchaseToken.trim() : '';
    if (!product || !platform || !purchaseToken) {
      return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
    }
    const verified = await verifier.verify({
      platform,
      productId: productId as ReadingCommerceProductId,
      purchaseToken,
    });
    if (verified.ok) {
      const refusal = readingOwnerRefusal(platform, verified.accountTag, request.authSubject);
      if (refusal) {
        // Nothing is bound or consumed, so the real owner can still claim it.
        return reply.code(200).send(successEnvelope({ granted: false, reason: refusal }));
      }
    }
    if (verified.ok && billingQaRejectsPurchase(config.readingBillingQa, verified.licenseTest)) {
      return reply.code(200).send(successEnvelope({ granted: false, reason: 'not_license_test' }));
    }
    if (!verified.ok) {
      if (verified.reason === 'canceled' || verified.reason === 'revoked') {
        try {
          await ledger.noteStoreRefund({
            ownerUserId: owner,
            platform,
            appId: commerceAppId(config, platform),
            purchaseToken,
            transactionId: verified.transactionId,
            atMs: toEpochMs(clock.now()),
          });
        } catch (error) {
          if (error instanceof ReadingEntitlementError && error.code === 'owned_by_other') {
            return reply.code(200).send(successEnvelope({
              granted: false,
              reason: 'purchase_bound_to_other_account',
            }));
          }
          return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
        }
      }
      return reply.code(200).send(successEnvelope({ granted: false, reason: verified.reason }));
    }
    try {
      const granted = await ledger.grantPurchase({
        ownerUserId: owner,
        platform,
        appId: commerceAppId(config, platform),
        productId: productId as ReadingCommerceProductId,
        purchaseToken,
        transactionId: verified.transactionId,
        atMs: toEpochMs(clock.now()),
      });
      const consumeState = platform === 'android' && verifier.consume
        ? await verifier.consume({
            platform,
            productId: productId as ReadingCommerceProductId,
            purchaseToken,
          })
        : 'skipped';
      return reply.code(200).send(successEnvelope({
        granted: true,
        idempotent: granted.idempotent,
        balance: granted.balance,
        consumeState,
      }));
    } catch (error) {
      if (error instanceof ReadingEntitlementError && error.code === 'owned_by_other') {
        return reply.code(200).send(successEnvelope({ granted: false, reason: 'purchase_bound_to_other_account' }));
      }
      if (error instanceof ReadingEntitlementError && error.code === 'invalid') {
        return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
      }
      return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
    }
  });

  // App Store Server Notifications V2. Apple is the caller: no user auth or
  // App Check; the signed payload is the proof. Unverifiable → 400 and
  // nothing changes; a verified notification is always acknowledged.
  const appleNotifications = options.appleNotifications === undefined
    ? createAppleNotificationDecoder(config)
    : options.appleNotifications;
  app.post('/v1/reading-entitlements/apple-notifications', async (request, reply) => {
    const body = request.body;
    const signedPayload = body && typeof body === 'object' && !Array.isArray(body)
      ? (body as Record<string, unknown>).signedPayload
      : undefined;
    if (typeof signedPayload !== 'string' || !signedPayload.trim()) {
      return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
    }
    const bundleId = config.appleBundleId?.trim();
    if (!appleNotifications || !bundleId || !options.store) {
      return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
    }
    const notification = await appleNotifications(signedPayload.trim());
    if (!notification) return reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
    try {
      const outcome = await applyAppleReadingNotification({
        store: options.store,
        bundleId,
        notification,
        atMs: toEpochMs(clock.now()),
      });
      return reply.code(200).send(successEnvelope({ outcome }));
    } catch {
      // Apple retries a non-200; the ledger change is idempotent.
      return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
    }
  });

  app.post('/v1/reading-entitlements/trial', { preHandler: [auth, appCheck] }, async (request, reply) => {
    const owner = request.identityKey;
    if (!owner) return reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
    if (!config.readingCommerceEnabled || !config.readingTrialEnabled || !options.store || !ledger) {
      return reply.code(200).send(successEnvelope({ granted: false, reason: 'trial_closed' }));
    }
    const nowMs = toEpochMs(clock.now());
    if (!(await readingBudgetOpen(options.store, config, nowMs))) {
      return reply.code(503).send(errorEnvelope(ErrorCode.spendGuard));
    }
    const outcome = await ledger.grantTrial({ ownerUserId: owner, atMs: nowMs });
    return reply.code(200).send(successEnvelope({
      granted: outcome === 'granted',
      reason: outcome,
      balance: await ledger.balance(owner),
    }));
  });
}
