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
    const purchasable = verifier.admitted && budgetOpen;
    if (options.lookupOperation) {
      await ledger.reconcile({
        ownerUserId: owner,
        nowMs,
        lookup: (operationId) => options.lookupOperation!(owner, operationId),
      });
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
