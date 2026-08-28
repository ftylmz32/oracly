import type { FastifyInstance } from 'fastify';
import type { AppCheckVerifier } from '../auth/app-check.js';
import type { AppConfig } from '../config.js';

export async function registerHealth(
  app: FastifyInstance,
  config: AppConfig,
  appCheck?: AppCheckVerifier,
): Promise<void> {
  app.get('/health', async () => ({ status: 'ok' }));

  app.get('/ready', async (_request, reply) => {
    const verifierReady =
      config.authMode === 'hs256' ||
      config.authMode === 'jwks' ||
      config.appEnv === 'development';
    // App Check attestation is never required on these routes.
    // If production requires App Check but the verifier cannot start, not ready.
    const appCheckReady =
      !config.appCheckRequired ||
      (appCheck != null && appCheck.mode !== 'fail_closed');
    const ready =
      Boolean(config.openaiApiKey) && verifierReady && appCheckReady;
    if (!ready) {
      return reply.code(503).send({ status: 'not_ready' });
    }
    return { status: 'ready' };
  });
}
