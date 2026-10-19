import { randomUUID } from 'node:crypto';
import { COFFEE_READING_PRODUCT_ID } from '../../lib/orders/types';
import { RequestAuthError, type OrderRequestVerifier } from './auth';
import type { PersistentOrderStore, StoredCoffeeOrder } from './store';

export type OrderApiDependencies = {
  verifier: OrderRequestVerifier; store: PersistentOrderStore;
  config: { catalogVersion: string; priceMinor: number; currency: 'TRY' };
  createOrderId?: () => string; now?: () => number;
};

export function createOrderApi(dependencies: OrderApiDependencies) {
  const now = dependencies.now ?? (() => Date.now());
  const createOrderId = dependencies.createOrderId ?? (() => `ord_${randomUUID()}`);
  return {
    create: async (request: Request): Promise<Response> => {
      try {
        const { uid } = await dependencies.verifier.verify(request);
        const body = await readCreateBody(request);
        if (!body) return response(400, { error: 'invalid_request' });
        const result = await dependencies.store.createIdempotent({ ownerUserId: uid, idempotencyKey: body.idempotencyKey, orderId: createOrderId(), catalogVersion: dependencies.config.catalogVersion, priceMinor: dependencies.config.priceMinor, currency: dependencies.config.currency, nowMs: now() });
        return response(result.created ? 201 : 200, { order: toOrderDto(result.order), idempotentReplay: !result.created });
      } catch (error) { return apiError(error); }
    },
    get: async (request: Request, orderId: string): Promise<Response> => {
      try {
        const { uid } = await dependencies.verifier.verify(request);
        if (!/^ord_[A-Za-z0-9-]{8,80}$/u.test(orderId)) return response(404, { error: 'order_not_found' });
        const order = await dependencies.store.getOwned(orderId, uid);
        return order ? response(200, { order: toOrderDto(order) }) : response(404, { error: 'order_not_found' });
      } catch (error) { return apiError(error); }
    },
  };
}

async function readCreateBody(request: Request): Promise<{ idempotencyKey: string } | null> {
  let body: unknown;
  try { body = await request.json(); } catch { return null; }
  if (!body || typeof body !== 'object' || Array.isArray(body)) return null;
  const value = body as Record<string, unknown>;
  if (Object.keys(value).some((key) => key !== 'productId' && key !== 'idempotencyKey')) return null;
  if (value.productId !== COFFEE_READING_PRODUCT_ID || typeof value.idempotencyKey !== 'string' || !/^[A-Za-z0-9_-]{16,80}$/u.test(value.idempotencyKey)) return null;
  return { idempotencyKey: value.idempotencyKey };
}

function toOrderDto(order: StoredCoffeeOrder) {
  return { orderId: order.orderId, productId: order.productId, priceMinor: order.priceMinor, currency: order.currency, status: order.status, providerPaymentStatus: order.providerPaymentStatus, financialReviewRequired: order.financialReviewRequired === true, createdAtMs: order.createdAtMs, updatedAtMs: order.updatedAtMs };
}
function response(status: number, body: unknown): Response { return Response.json(body, { status, headers: { 'Cache-Control': 'no-store' } }); }
function apiError(error: unknown): Response {
  if (error instanceof RequestAuthError) return response(error.code === 'unauthorized' ? 401 : 403, { error: error.code });
  return response(503, { error: 'order_service_unavailable' });
}
