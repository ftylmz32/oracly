/**
 * POST /v1/review-access/activate — Google Play / App Store closed-test
 * reviewer entitlement. Stateless: compares a SHA-256 hash of the submitted
 * code against `config.reviewAccessCodeHash` (server config only — the raw
 * code is never stored server-side or shipped in the app). Never touches
 * `billing/*`, never records a purchase-token binding, never fakes a store
 * receipt. Distinguishable from real paid entitlement by construction: this
 * route has no relationship to catalog product IDs, Apple/Google, or
 * `entitlement-binding.ts`.
 */

import { createHash, timingSafeEqual } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { createAuthenticationService } from '../auth/create-auth.js';
import type { AppConfig } from '../config.js';
import { ErrorCode, errorEnvelope } from '../errors.js';
import { logSafe } from '../logging.js';
import { createIdentityRateLimit } from '../middleware/rate-limit.js';
import { requireAuth } from '../middleware/auth.js';

const CODE_MAX = 128;

const activateBodySchema = {
  type: 'object',
  additionalProperties: false,
  required: ['code'],
  properties: {
    code: { type: 'string', minLength: 1, maxLength: CODE_MAX },
  },
} as const;

type ActivateBody = { code: string };

export async function registerReviewAccessRoutes(
  app: FastifyInstance,
  config: AppConfig,
): Promise<void> {
  // Mirrors /v1/billing/verify: attach the hook whenever auth is required,
  // regardless of authMode, so a missing/invalid Firebase configuration
  // fails closed (401) instead of silently accepting unauthenticated
  // requests.
  const authHook = config.authRequired
    ? requireAuth(createAuthenticationService(config))
    : null;
  const rateLimit = createIdentityRateLimit(
    config.reviewAccessRateLimitMax,
    config.reviewAccessRateLimitWindowMs,
  );

  app.post<{ Body: ActivateBody }>(
    '/v1/review-access/activate',
    {
      schema: { body: activateBodySchema },
      preHandler: authHook ? [authHook, rateLimit] : [rateLimit],
      attachValidation: true,
    },
    async (request, reply) => {
      if (request.validationError) {
        return reply.code(200).send({
          granted: false,
          reason: 'invalid_request',
        });
      }
      const identityKey = request.identityKey?.trim() ?? '';
      if (authHook && !identityKey) {
        return reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
      }
      if (!config.reviewAccessCodeHash) {
        return reply.code(200).send({
          granted: false,
          reason: 'not_configured',
        });
      }
      const granted = matchesConfiguredCode(
        request.body.code,
        config.reviewAccessCodeHash,
      );
      // Never log the raw code — only the boolean outcome and identity
      // presence, matching the billing_verify logging convention.
      logSafe(request.log, 'info', 'review_access_activate', {
        requestId: request.requestId || String(request.id),
        operation: 'review_access_activate',
        status: granted ? 200 : 422,
        identityPresent: Boolean(request.authSubject),
      });
      return reply.code(200).send(
        granted
          ? { granted: true }
          : { granted: false, reason: 'invalid_code' },
      );
    },
  );
}

function matchesConfiguredCode(
  submitted: string,
  configuredHash: string,
): boolean {
  const submittedHash = createHash('sha256')
    .update(submitted.trim())
    .digest('hex');
  const a = Buffer.from(submittedHash, 'hex');
  const b = Buffer.from(configuredHash, 'hex');
  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}
