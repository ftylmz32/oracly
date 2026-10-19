import { createCheckoutRuntime } from '@/server/orders/runtime';
import { RequestAuthError } from '@/server/orders/auth';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function POST(request: Request, context: { params: Promise<{ orderId: string }> }): Promise<Response> {
  try {
    const { orderId } = await context.params; const dependencies = createCheckoutRuntime();
    const { uid } = await dependencies.verifier.verifyPermanent(request);
    const order = await dependencies.store.getOwned(orderId, uid);
    if (!order) return json(404, { error: 'order_not_found' });
    const result = await dependencies.checkout.start(request, order);
    if (result.state === 'sandbox_ready') return json(200, { state: 'sandbox_ready', paymentPageUrl: result.paymentPageUrl, notice: 'sandbox_only_no_real_payment' });
    if (result.state === 'ready') return json(200, { state: 'sandbox_session_exists', paymentPageUrl: result.paymentPageUrl, notice: 'sandbox_only_no_real_payment' });
    if (result.state === 'in_progress') return json(409, { error: 'checkout_in_progress' });
    return json(409, { error: 'checkout_not_available' });
  } catch (error) {
    if (error instanceof RequestAuthError) return json(error.code === 'unauthorized' ? 401 : 403, { error: error.code });
    return json(error instanceof Error && error.message === 'invalid_request' ? 400 : 503, { error: error instanceof Error && error.message === 'invalid_request' ? 'invalid_request' : 'checkout_unavailable' });
  }
}
function json(status: number, body: unknown) { return Response.json(body, { status, headers: { 'Cache-Control': 'no-store' } }); }
