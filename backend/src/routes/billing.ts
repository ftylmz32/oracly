/** POST /v1/billing/verify — authoritative Google / Apple entitlement check. */

import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import type {
  BillingProviders,
  BillingVerifyRequest,
  BillingVerifyResult,
  StoreVerifier,
} from '../billing/types.js';
import {
  createEntitlementRepository,
  purchaseBindingKey,
  type EntitlementBindingRepository,
  type EntitlementStatusMeta,
} from '../billing/entitlement-repository.js';
import { productKind } from '../billing/catalog.js';
import { billingResult } from '../billing/types.js';
import { premiumOwnerTag } from '../billing/purchase-owner-tag.js';
import { createBillingProviders, verifyPurchase } from '../billing/verify.js';
import {
  ACK_LOST_GRACE_MS,
  ACK_OVERDUE_MS,
  ACK_RETRY_DELAYS_MS,
  ackOutboxId,
  createAckOutbox,
  createAckRetryScheduler,
  type BillingAckOptions,
} from '../billing/ack-outbox.js';
import { verifyBillingTask } from '../billing/billing-task-auth.js';
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
  ackOptions: BillingAckOptions = {},
): Promise<void> {
  const providers = createBillingProviders(config, providersOverride);
  const repository = repositoryOverride ?? createEntitlementRepository(config);
  const outbox =
    ackOptions.outbox === undefined ? createAckOutbox(config) : ackOptions.outbox;
  const ackScheduler = ackOptions.scheduler ?? createAckRetryScheduler(config);
  const verifyTask = ackOptions.verifyTask ?? verifyBillingTask(config);
  const now = ackOptions.now ?? Date.now;
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
        // A purchase the app launched names its buyer (obfuscated account
        // tag). When it names another account, the caller is refused and
        // nothing is bound, so its real owner can still claim it. The
        // authenticated subject is authoritative, never the client body.
        const subject = request.authSubject?.trim() ?? '';
        if (
          result.accountTag &&
          subject &&
          result.accountTag !== premiumOwnerTag(subject)
        ) {
          result = billingResult('unverified', 'purchase_bound_to_other_account');
        }
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
          } else if (
            result.acknowledgementPending &&
            body.platform === 'android'
          ) {
            // Verified at Play, bound to this caller: acknowledge it here so
            // the purchase no longer depends on the app's next store query
            // to escape Play's automatic refund. A failure changes nothing
            // (the binding stands); the next verify sees it still pending
            // at Play and retries. Play acknowledgement is idempotent.
            const acknowledged = await acknowledgeSafely(providers.google, {
              platform: body.platform,
              productId: body.productId.trim(),
              purchaseToken: body.purchaseToken,
            });
            await keepForRetry({
              acknowledged,
              productId: body.productId.trim(),
              purchaseToken: body.purchaseToken,
              owner: identityKey,
            });
            logSafe(request.log, acknowledged ? 'info' : 'warn', 'billing_acknowledge', {
              requestId: request.requestId || String(request.id),
              operation: 'billing_acknowledge',
              status: acknowledged ? 200 : 503,
            });
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

  /**
   * A failed inline acknowledgement goes to the durable outbox and a
   * delayed task; a successful one closes any earlier entry. Never affects
   * the verify answer: storage or scheduling failures are only logged.
   */
  async function keepForRetry(input: {
    acknowledged: boolean;
    productId: string;
    purchaseToken: string;
    owner: string;
  }): Promise<void> {
    if (!outbox) return;
    const id = ackOutboxId('android', input.purchaseToken);
    try {
      if (input.acknowledged) {
        const existing = await outbox.get(id);
        if (existing?.status === 'pending') {
          await outbox.update(id, {
            status: 'done',
            lastReason: 'acknowledged_inline',
            updatedAtMs: now(),
          });
        }
        return;
      }
      const at = now();
      const due = at + ACK_RETRY_DELAYS_MS[0]!;
      const created = await outbox.create({
        id,
        platform: 'android',
        productId: input.productId,
        purchaseToken: input.purchaseToken,
        ownerIdentityKey: input.owner,
        attempts: 0,
        status: 'pending',
        createdAtMs: at,
        updatedAtMs: at,
        nextAttemptAtMs: due,
      });
      if (created) await scheduleOrMark(id, 0, due);
    } catch {
      app.log.error({ operation: 'billing_ack_outbox', errorCode: 'outbox_unavailable' });
    }
  }

  /**
   * Creates the retry task; when that fails the entry is marked and an
   * error is logged (alertable), and the sweep re-creates it later.
   */
  async function scheduleOrMark(id: string, attempt: number, atMs: number, key?: string) {
    if (!outbox) return;
    try {
      await ackScheduler.schedule({ id, attempt, atMs, key });
      await outbox.update(id, { nextAttemptAtMs: atMs, scheduleFailed: false });
    } catch {
      await outbox.update(id, { nextAttemptAtMs: atMs, scheduleFailed: true });
      app.log.error({
        operation: 'billing_ack_schedule',
        errorCode: 'billing_ack_schedule_failed',
      });
    }
  }

  /**
   * Cloud Task retry of a failed acknowledgement. Re-reads Play and
   * acknowledges only a purchase that is still active (PURCHASED), still
   * unacknowledged and still bound to the same account. Refunded,
   * cancelled, expired or rebound purchases are closed, never acknowledged.
   */
  app.post<{ Body: { id?: unknown } }>(
    '/internal/billing/acknowledge-retry',
    async (request, reply) => {
      if (!(await verifyTask(request))) {
        return reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
      }
      const id = typeof request.body?.id === 'string' ? request.body.id : '';
      const entry = id && outbox ? await outbox.get(id) : null;
      if (!outbox || !entry || entry.status !== 'pending') {
        return reply.code(200).send({ ok: true });
      }
      const finish = async (status: 'done' | 'closed', reason: string) => {
        await outbox.update(id, { status, lastReason: reason, updatedAtMs: now() });
        logSafe(request.log, reason === 'gave_up' ? 'error' : status === 'done' ? 'info' : 'warn', 'billing_ack_retry', {
          requestId: request.requestId || String(request.id),
          operation: 'billing_ack_retry',
          status: status === 'done' ? 200 : 410,
          errorCode: reason,
        });
      };
      const retryLater = async (reason: string) => {
        const attempts = entry.attempts + 1;
        if (attempts >= ACK_RETRY_DELAYS_MS.length) {
          await finish('closed', 'gave_up');
          return;
        }
        await outbox.update(id, { attempts, lastReason: reason, updatedAtMs: now() });
        await scheduleOrMark(id, attempts, now() + ACK_RETRY_DELAYS_MS[attempts]!);
      };
      const purchase = {
        platform: entry.platform,
        productId: entry.productId,
        purchaseToken: entry.purchaseToken,
      };
      let verdict: BillingVerifyResult;
      try {
        verdict = await verifyPurchase(purchase, providers);
      } catch {
        verdict = billingResult('error', 'provider_unavailable');
      }
      if (verdict.status === 'inactive' || verdict.status === 'expired') {
        await finish('closed', verdict.reason ?? verdict.status);
        return reply.code(200).send({ ok: true });
      }
      if (verdict.status !== 'active') {
        await retryLater(verdict.reason ?? verdict.status);
        return reply.code(200).send({ ok: true });
      }
      const owner = await repository.peekOwner(
        purchaseBindingKey(entry.platform, entry.purchaseToken),
      );
      if (owner !== entry.ownerIdentityKey) {
        await finish('closed', 'owner_mismatch');
        return reply.code(200).send({ ok: true });
      }
      if (!verdict.acknowledgementPending) {
        await finish('done', 'already_acknowledged');
        return reply.code(200).send({ ok: true });
      }
      if (await acknowledgeSafely(providers.google, purchase)) {
        await finish('done', 'acknowledged');
      } else {
        await retryLater('acknowledge_failed');
      }
      return reply.code(200).send({ ok: true });
    },
  );

  /**
   * Cloud Scheduler sweep (billing identity only). Re-creates the task of
   * any pending entry whose retry is overdue by more than the lost-task
   * grace (task creation failed, or the task never ran), and reports
   * entries pending past the overdue limit as an alertable error. Counts
   * only, never tokens.
   */
  app.post('/internal/billing/acknowledge-sweep', async (request, reply) => {
    if (!(await verifyTask(request))) {
      return reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
    }
    if (!outbox) return reply.code(200).send({ pending: 0, rescheduled: 0, overdue: 0 });
    const pending = await outbox.listPending(500);
    const at = now();
    let rescheduled = 0;
    let overdue = 0;
    for (const entry of pending) {
      if (at - entry.createdAtMs > ACK_OVERDUE_MS) overdue++;
      const due = entry.nextAttemptAtMs ?? entry.createdAtMs;
      if (entry.scheduleFailed || at - due > ACK_LOST_GRACE_MS) {
        await scheduleOrMark(entry.id, entry.attempts, at, `s${at}`);
        rescheduled++;
      }
    }
    logSafe(request.log, overdue > 0 ? 'error' : 'info', 'billing_ack_sweep', {
      requestId: request.requestId || String(request.id),
      operation: 'billing_ack_sweep',
      status: overdue > 0 ? 500 : 200,
      errorCode: overdue > 0 ? 'billing_ack_overdue' : undefined,
    });
    return reply.code(200).send({ pending: pending.length, rescheduled, overdue });
  });
}

async function acknowledgeSafely(
  verifier: StoreVerifier,
  request: BillingVerifyRequest,
): Promise<boolean> {
  if (!verifier.acknowledge) return false;
  try {
    return await verifier.acknowledge(request);
  } catch {
    return false;
  }
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
