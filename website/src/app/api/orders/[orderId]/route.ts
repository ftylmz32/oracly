import { createOrderApi } from '@/server/orders/api';
import { createOrderRuntime } from '@/server/orders/runtime';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function GET(request: Request, context: RouteContext<'/api/orders/[orderId]'>): Promise<Response> {
  try {
    const { orderId } = await context.params;
    const runtimeDependencies = createOrderRuntime();
    return createOrderApi(runtimeDependencies).get(request, orderId);
  } catch {
    return Response.json({ error: 'order_service_unavailable' }, { status: 503, headers: { 'Cache-Control': 'no-store' } });
  }
}
