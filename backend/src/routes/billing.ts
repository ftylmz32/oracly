/** POST /v1/billing/verify — authoritative Google / Apple entitlement check. */

import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import type { BillingProviders, BillingVerifyResult } from '../billing/types.js';
import {
  createEntitlementRepository,
  purchaseBindingKey,
  type EntitlementBindingRepository,
  type EntitlementStatusMeta,
} from '../billing/entitlement-repository.js';
import { productKind } from '../billing/catalog.js';
import { billingResult } from '../billing/types.js';
import { createBillingProviders, verifyPurchase } from '../billing/verify.js';
import { createAuthenticationService } from '../auth/create-auth.js';
import type { AppConfig } from '../config.js';
import { ErrorCode, errorEnvelope } from '../errors.js';
import { logSafe } from '../logging.js';
import { requireAuth } from '../middleware/auth.js';
import { createSharedWindowStore, type SharedWindowStore } from '../rate-limit/shared-window-store.js';

const PRODUCT_ID_MAX = 128;
const TRANSACTION_ID_MAX = 128;
const PURCHASE_TOKEN_MAX = 64 * 1024;

const verifyBodySchema = {
  type: 'object',
  additionalProperties: false,
  required: ['platform', 'productId', 'purchaseToken'],
  properties: {
    platform: { type: 'string', enum: ['android', 'ios'] },
    productId: { type: 'string', minLength: 1, maxLength: PRODUCT_ID_MAX },
    purchaseToken: {
      type: 'string',
      minLength: 1,
      maxLength: PURCHASE_TOKEN_MAX,
    },
    transactionId: {
      type: 'string',
      minLength: 1,
      maxLength: TRANSACTION_ID_MAX,
    },
  },
} as const;

type VerifyBody = {
  platform: 'android' | 'ios';
  productId: string;
  purchaseToken: string;
  transactionId?: string;
};

export async function registerBillingRoutes(
  app: FastifyInstance,
  config: AppConfig,
  providersOverride: BillingProviders = {},
  repositoryOverride?: EntitlementBindingRepository,
  sharedWindowOverride?: SharedWindowStore,
): Promise<void> {
  const providers = createBillingProviders(config, providersOverride);
  const repository = repositoryOverride ?? createEntitlementRepository(config);
  const rateLimit = createBillingIpRateLimit(
    config.billingRateLimitMax,
    config.billingRateLimitWindowMs,
    sharedWindowOverride ?? createSharedWindowStore(config),
  );
  // Must mirror /v1/ai/complete: attach the hook whenever auth is required,
  // regardless of authMode. authMode === 'fail_closed' resolves to
  // FailClosedAuthenticationService, which rejects every request with 401 —
  // omitting the hook here would silently let requests bypass auth instead.
  const authHook = config.authRequired
    ? requireAuth(createAuthenticationService(config))
    : null;

  app.post<{ Body: VerifyBody }>(
    '/v1/billing/verify',
    {
      schema: {
        body: verifyBodySchema,
      },
      preHandler: authHook ? [authHook, rateLimit] : [rateLimit],
      attachValidation: true,
    },
    async (request, reply) => {
      if (request.validationError) {
        return reply.code(200).send({
          status: 'unverified',
          reason: 'invalid_request',
        });
      }
      const body = request.body;
      const identityKey = request.identityKey?.trim() ?? '';
      if (authHook && !identityKey) {
        return reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
      }
      const bindingKey = purchaseBindingKey(body.platform, body.purchaseToken);
      let owner: string | null = null;
      if (identityKey) {
        // Fast, non-authoritative pre-check only — skips a redundant
        // Apple/Google call when clearly owned by someone else already.
        // The actual security decision happens in the atomic claim below.
        owner = await repository.peekOwner(bindingKey);
        if (owner && owner !== identityKey) {
          const bound = billingResult(
            'unverified',
            'purchase_bound_to_other_account',
          );
          logSafe(request.log, 'info', 'billing_verify', {
            requestId: request.requestId || String(request.id),
            operation: 'billing_verify',
            status: 422,
            errorCode: bound.reason,
          });
          return reply.code(200).send(bound);
        }
      }
      try {
        let result = await verifyPurchase(
          {
            platform: body.platform,
            productId: body.productId.trim(),
            purchaseToken: body.purchaseToken,
            transactionId: body.transactionId?.trim(),
          },
          providers,
        );
        // SMD1-E1 — the verifier's `expiryAtMs` is an internal-only field
        // used to persist a real authoritative expiry snapshot; it must
        // never reach the client response (see BillingVerifyResult).
        const verifiedAtMs = Date.now();
        const kind = productKind(body.productId.trim());
        const entitlement: EntitlementStatusMeta | undefined = kind
          ? {
              status: result.status,
              expiryAtMs: result.expiryAtMs ?? null,
              verifiedAtMs,
              kind,
            }
          : undefined;
        if (identityKey && result.status === 'active') {
          // Authoritative and atomic — the store confirming "active" is not
          // enough on its own; two concurrent requests for the same token
          // from different accounts must never both be told they own it.
          const outcome = await repository.claim(bindingKey, identityKey, {
            platform: body.platform,
            productId: body.productId.trim(),
            transactionId: body.transactionId?.trim(),
            entitlement,
          });
          if (outcome === 'owned_by_other') {
            result = billingResult(
              'unverified',
              'purchase_bound_to_other_account',
            );
          } else if (outcome === 'error') {
            // Storage failure must never silently grant an entitlement.
            result = billingResult('error', 'entitlement_binding_unavailable');
          }
        } else if (identityKey && owner === identityKey && entitlement) {
          // SMD1-E1 — a non-active outcome (expired/revoked/inactive/etc.)
          // for a binding this identity already owns must be reflected,
          // never left showing the last-known `active` snapshot forever.
          // Ownership itself is untouched — ownership can only ever be
          // granted by `claim()` above.
          await repository.recordStatus(bindingKey, identityKey, entitlement);
        }
        logSafe(request.log, 'info', 'billing_verify', {
          requestId: request.requestId || String(request.id),
          operation: 'billing_verify',
          status: mapLogStatus(result.status),
          errorCode: result.reason,
          identityPresent: Boolean(request.authSubject),
        });
        // Allowlisted response — `expiryAtMs` (and any future internal-only
        // field) never reaches the client, by construction.
        const wire: BillingVerifyResult = result.reason
          ? { status: result.status, reason: result.reason }
          : { status: result.status };
        return reply.code(200).send(wire);
      } catch {
        logSafe(request.log, 'error', 'billing_verify_error', {
          requestId: request.requestId || String(request.id),
          operation: 'billing_verify',
          errorCode: 'internal_error',
        });
        return reply.code(200).send({
          status: 'error',
          reason: 'internal_error',
        });
      }
    },
  );
}

function mapLogStatus(status: string): number {
  switch (status) {
    case 'active':
      return 200;
    case 'pending':
      return 202;
    case 'expired':
    case 'inactive':
      return 403;
    default:
      return 422;
  }
}

/** IP sliding-window limiter — billing uses Firebase identity when configured. */
function createBillingIpRateLimit(max: number, windowMs: number, shared?: SharedWindowStore) {
  const hits = new Map<string, number[]>();
  return async function billingRateLimit(
    request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<void> {
    const key = `billing:${request.ip || 'unknown'}`;
    if (shared && !(await shared.consume('billing', key, max, windowMs))) {
      await reply.code(200).send({ status: 'error', reason: 'rate_limited' }); return;
    }
    if (shared) return;
    const now = Date.now();
    const recent = (hits.get(key) ?? []).filter((at) => now - at < windowMs);
    if (recent.length >= max) {
      await reply.code(200).send({
        status: 'error',
        reason: 'rate_limited',
      });
      return;
    }
    recent.push(now);
    hits.set(key, recent);
  };
}
