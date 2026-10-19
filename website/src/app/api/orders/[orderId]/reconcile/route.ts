import { createCheckoutRuntime } from '@/server/orders/runtime';
import { RequestAuthError } from '@/server/orders/auth';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function POST(request: Request, context: { params: Promise<{ orderId: string }> }): Promise<Response> {
  try {
    const { orderId } = await context.params; const dependencies = createCheckoutRuntime();
    const { uid } = await dependencies.verifier.verify(request);
    const order = await dependencies.store.getOwned(orderId, uid);
    if (!order) return json(404, { error: 'order_not_found' });
    if (!order.checkoutToken) return json(202, { state: 'checkout_not_bound' });
    const result = await dependencies.checkout.reconcile(order.checkoutToken);
    if (result.orderId !== order.orderId) return json(409, { error: 'order_mismatch' });
    return json(result.outcome === 'not_granted' ? 202 : 200, { state: result.outcome });
  } catch (error) {
    if (error instanceof RequestAuthError) return json(error.code === 'unauthorized' ? 401 : 403, { error: error.code });
    return json(503, { error: 'reconciliation_unavailable' });
  }
}

function json(status: number, body: unknown) { return Response.json(body, { status, headers: { 'Cache-Control': 'no-store' } }); }
