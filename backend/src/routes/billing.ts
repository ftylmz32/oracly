/** POST /v1/billing/verify — authoritative Google / Apple entitlement check. */

import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import type { BillingProviders } from '../billing/types.js';
import {
  checkPurchaseBinding,
  purchaseBindingKey,
  recordPurchaseBinding,
} from '../billing/entitlement-binding.js';
import { createBillingProviders, verifyPurchase } from '../billing/verify.js';
import { createAuthenticationService } from '../auth/create-auth.js';
import type { AppConfig } from '../config.js';
import { ErrorCode, errorEnvelope } from '../errors.js';
import { logSafe } from '../logging.js';
import { requireAuth } from '../middleware/auth.js';

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
): Promise<void> {
  const providers = createBillingProviders(config, providersOverride);
  const rateLimit = createBillingIpRateLimit(
    config.billingRateLimitMax,
    config.billingRateLimitWindowMs,
  );
  const authHook =
    config.authRequired && config.authMode !== 'fail_closed'
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
      if (identityKey) {
        const bound = checkPurchaseBinding(bindingKey, identityKey);
        if (bound) {
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
        const result = await verifyPurchase(
          {
            platform: body.platform,
            productId: body.productId.trim(),
            purchaseToken: body.purchaseToken,
            transactionId: body.transactionId?.trim(),
          },
          providers,
        );
        if (identityKey && result.status === 'active') {
          recordPurchaseBinding(bindingKey, identityKey, true);
        }
        logSafe(request.log, 'info', 'billing_verify', {
          requestId: request.requestId || String(request.id),
          operation: 'billing_verify',
          status: mapLogStatus(result.status),
          errorCode: result.reason,
          identityPresent: Boolean(request.authSubject),
        });
        return reply.code(200).send(result);
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
function createBillingIpRateLimit(max: number, windowMs: number) {
  const hits = new Map<string, number[]>();
  return async function billingRateLimit(
    request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<void> {
    const key = `billing:${request.ip || 'unknown'}`;
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