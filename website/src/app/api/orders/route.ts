import { createOrderApi } from '@/server/orders/api';
import { createOrderRuntime } from '@/server/orders/runtime';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function POST(request: Request): Promise<Response> {
  try {
    const runtimeDependencies = createOrderRuntime();
    return createOrderApi(runtimeDependencies).create(request);
  } catch {
    return Response.json({ error: 'order_service_unavailable' }, { status: 503, headers: { 'Cache-Control': 'no-store' } });
  }
}
