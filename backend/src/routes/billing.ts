import type { FastifyInstance } from 'fastify';

/**
 * Billing verify stub — client contract only.
 * Does NOT validate Apple/Google receipts. Never returns active.
 */
export async function registerBillingRoutes(
  app: FastifyInstance,
): Promise<void> {
  app.post('/v1/billing/verify', async () => ({
    status: 'unverified',
    reason: 'provider_not_configured',
  }));
}