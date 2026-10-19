import { createCheckoutRuntime } from '@/server/orders/runtime';

export const runtime = 'nodejs'; export const dynamic = 'force-dynamic';
export async function POST(request: Request): Promise<Response> {
  try {
    const form = await request.formData(); const token = form.get('token');
    if (typeof token !== 'string' || token.length < 8 || token.length > 200) return reply(400, 'invalid_callback');
    const outcome = await createCheckoutRuntime().checkout.reconcile(token);
    return reply(200, outcome === 'granted' || outcome === 'already_applied' ? 'sandbox_payment_verified' : 'sandbox_payment_not_verified');
  } catch { return reply(503, 'sandbox_payment_verification_pending'); }
}
function reply(status: number, state: string) { return Response.json({ state, notice: 'sandbox_only_no_real_payment' }, { status, headers: { 'Cache-Control': 'no-store' } }); }
