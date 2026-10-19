import { RequestAuthError } from '@/server/orders/auth';
import { createOrderRuntime } from '@/server/orders/runtime';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function GET(request: Request): Promise<Response> {
  try {
    const dependencies = createOrderRuntime();
    const { uid } = await dependencies.verifier.verifyPermanent(request);
    const url = new URL(request.url);
    const limit = Math.min(25, Math.max(1, Number(url.searchParams.get('limit') ?? '10') || 10));
    const cursor = decodeCursor(url.searchParams.get('cursor'));
    if (url.searchParams.has('cursor') && !cursor) return json(400, { error: 'invalid_cursor' });
    const result = await dependencies.store.listOwned(uid, { limit, ...(cursor ? { cursor } : {}) });
    return json(200, { orders: result.orders.map(toDto), ...(result.nextCursor ? { nextCursor: encodeCursor(result.nextCursor) } : {}) });
  } catch (error) {
    if (error instanceof RequestAuthError) return json(error.code === 'unauthorized' ? 401 : 403, { error: error.code });
    return json(503, { error: 'order_service_unavailable' });
  }
}

function toDto(order: Awaited<ReturnType<ReturnType<typeof createOrderRuntime>['store']['getOwned']>>) {
  if (!order) return null;
  return { orderId: order.orderId, productId: order.productId, priceMinor: order.priceMinor, currency: order.currency, status: order.status, providerPaymentStatus: order.providerPaymentStatus, financialReviewRequired: order.financialReviewRequired === true, createdAtMs: order.createdAtMs, updatedAtMs: order.updatedAtMs };
}
function encodeCursor(value: { createdAtMs: number; orderId: string }) { return Buffer.from(JSON.stringify(value)).toString('base64url'); }
function decodeCursor(value: string | null): { createdAtMs: number; orderId: string } | undefined {
  if (!value || value.length > 256) return undefined;
  try { const parsed = JSON.parse(Buffer.from(value, 'base64url').toString('utf8')) as Record<string, unknown>; return Number.isSafeInteger(parsed.createdAtMs) && typeof parsed.orderId === 'string' && /^ord_[A-Za-z0-9-]{8,80}$/u.test(parsed.orderId) ? { createdAtMs: parsed.createdAtMs as number, orderId: parsed.orderId } : undefined; } catch { return undefined; }
}
function json(status: number, body: unknown) { return Response.json(body, { status, headers: { 'Cache-Control': 'private, no-store' } }); }
