import { createCheckoutRuntime } from '@/server/orders/runtime';

export const runtime = 'nodejs'; export const dynamic = 'force-dynamic';
export async function POST(request: Request): Promise<Response> {
  try {
    if (request.headers.has('x-iyz-signature') || request.headers.has('x-iyz-signature-v2')) return Response.json({ error: 'legacy_signature_rejected' }, { status: 401 });
    const signature = request.headers.get('x-iyz-signature-v3'); if (!signature) return Response.json({ error: 'signature_required' }, { status: 401 });
    const raw = await request.text(); const runtimeDependencies = createCheckoutRuntime();
    const notification = runtimeDependencies.provider.verifyWebhook(raw, signature);
    const order = await runtimeDependencies.store.getByCheckoutToken(notification.checkoutToken);
    if (!order || order.orderId !== notification.orderId) return Response.json({ error: 'notification_mismatch' }, { status: 400 });
    const result = await runtimeDependencies.checkout.reconcile(notification.checkoutToken);
    if (result.outcome !== 'granted' && result.outcome !== 'already_applied') return Response.json({ error: 'verification_pending' }, { status: 503 });
    return Response.json({ received: true }, { status: 200 });
  } catch { return Response.json({ error: 'webhook_rejected' }, { status: 401 }); }
}
