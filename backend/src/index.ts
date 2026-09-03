import { loadConfig } from './config.js';
import { loadEnvFile } from './load-env.js';
import { buildServer } from './server.js';

loadEnvFile();
const config = loadConfig();
const app = await buildServer({ config, logger: true });

async function shutdown(signal: string): Promise<void> {
  app.log.info({ signal }, 'oracly-ai-proxy shutting down');
  try {
    await app.close();
  } catch (error) {
    app.log.error(error);
  }
  process.exit(0);
}

process.on('SIGTERM', () => {
  void shutdown('SIGTERM');
});
process.on('SIGINT', () => {
  void shutdown('SIGINT');
});

try {
  await app.listen({ host: config.host, port: config.port });
  const locked = config.appEnv === 'production' || config.appEnv === 'staging';
  const trafficReady =
    Boolean(config.openaiApiKey) &&
    (config.authMode === 'jwks' || config.authMode === 'hs256');
  app.log.info(
    {
      env: config.appEnv,
      host: config.host,
      port: config.port,
      authRequired: config.authRequired,
      authMode: config.authMode,
      vision: config.openaiVision,
      model: config.openaiModel,
      openaiConfigured: Boolean(config.openaiApiKey),
      trafficReady: locked ? trafficReady : undefined,
    },
    'oracly-ai-proxy listening',
  );
  if (locked && !trafficReady) {
    app.log.warn(
      {
        authMode: config.authMode,
        openaiConfigured: Boolean(config.openaiApiKey),
      },
      'oracly-ai-proxy not ready — set OPENAI_API_KEY and FIREBASE_PROJECT_ID (or JWKS)',
    );
  }
  if (locked && !config.openaiVision) {
    app.log.warn(
      { vision: false },
      'oracly-ai-proxy vision disabled — coffee_analysis and palm_analysis return image_analysis_unavailable',
    );
  }
} catch (error) {
  app.log.error(error);
  process.exit(1);
}
