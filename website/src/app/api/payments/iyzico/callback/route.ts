import { createCheckoutRuntime } from '@/server/orders/runtime';

export const runtime = 'nodejs'; export const dynamic = 'force-dynamic';
export async function POST(request: Request): Promise<Response> {
  const destination = new URL('/kahve-fali/odeme', request.url);
  try {
    const form = await request.formData(); const token = form.get('token');
    if (typeof token !== 'string' || token.length < 8 || token.length > 200) { destination.searchParams.set('state', 'invalid'); return Response.redirect(destination, 303); }
    const result = await createCheckoutRuntime().checkout.reconcile(token);
    destination.searchParams.set('orderId', result.orderId);
    destination.searchParams.set('state', result.outcome === 'granted' || result.outcome === 'already_applied' ? 'verified' : 'pending');
    return Response.redirect(destination, 303);
  } catch { destination.searchParams.set('state', 'pending'); return Response.redirect(destination, 303); }
}
