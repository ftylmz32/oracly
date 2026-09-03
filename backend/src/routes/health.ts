import type { FastifyInstance } from 'fastify';
import type { AppCheckVerifier } from '../auth/app-check.js';
import type { AppConfig } from '../config.js';

export type ReadinessCapabilities = {
  alive: true;
  authenticationConfigured: boolean;
  appCheckConfigured: boolean;
  textProviderConfigured: boolean;
  visionConfigured: boolean;
  imageGenerationConfigured: boolean;
};

/**
 * Liveness vs readiness. Never expose secret values — only booleans.
 */
export async function registerHealth(
  app: FastifyInstance,
  config: AppConfig,
  appCheck?: AppCheckVerifier,
): Promise<void> {
  app.get('/health', async () => ({ status: 'ok' }));

  app.get('/ready', async (_request, reply) => {
    const capabilities = readinessCapabilities(config, appCheck);
    const ready =
      capabilities.authenticationConfigured &&
      capabilities.appCheckConfigured &&
      capabilities.textProviderConfigured;
    if (!ready) {
      return reply.code(503).send({
        status: 'not_ready',
        capabilities,
      });
    }
    return { status: 'ready', capabilities };
  });
}

export function readinessCapabilities(
  config: AppConfig,
  appCheck?: AppCheckVerifier,
): ReadinessCapabilities {
  const authenticationConfigured =
    config.authMode === 'hs256' ||
    config.authMode === 'jwks' ||
    config.authMode === 'bypass' ||
    (config.appEnv === 'development' && config.authMode === 'opaque');
  const appCheckConfigured =
    !config.appCheckRequired ||
    (appCheck != null && appCheck.mode !== 'fail_closed');
  const textProviderConfigured = Boolean(config.openaiApiKey);
  const visionConfigured =
    textProviderConfigured && config.openaiVision === true;
  const imageGenerationConfigured =
    textProviderConfigured && Boolean(config.openaiImageModel.trim());
  return {
    alive: true,
    authenticationConfigured,
    appCheckConfigured,
    textProviderConfigured,
    visionConfigured,
    imageGenerationConfigured,
  };
}
