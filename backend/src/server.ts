import Fastify from 'fastify';
import helmet from '@fastify/helmet';
import './types.js';
import { AiProxyService } from './ai/service.js';
import type { AppCheckVerifier } from './auth/app-check.js';
import { createAppCheckVerifier } from './auth/app-check.js';
import type { AppConfig } from './config.js';
import { ErrorCode, ProxyError, errorEnvelope } from './errors.js';
import { createRequestId, logSafe } from './logging.js';
import { registerAiRoutes } from './routes/ai.js';
import { registerHealth } from './routes/health.js';
import { registerBillingRoutes } from './routes/billing.js';
import type { BillingProviders } from './billing/types.js';
import type { OpenAiFetch } from './types.js';

export type BuildOptions = {
  config: AppConfig;
  fetchImpl?: OpenAiFetch;
  logger?: boolean;
  /** Override App Check verifier (tests). */
  appCheck?: AppCheckVerifier;
  /** Override billing store verifiers (tests). */
  billing?: BillingProviders;
};

export async function buildServer(options: BuildOptions) {
  const { config } = options;
  const appCheck = options.appCheck ?? createAppCheckVerifier(config);
  const app = Fastify({
    logger: options.logger
      ? {
          level: 'info',
          redact: {
            paths: [
              'req.headers.authorization',
              'req.headers.Authorization',
              'req.headers.cookie',
              'req.headers["x-firebase-appcheck"]',
              'req.headers["X-Firebase-AppCheck"]',
              '*.accessToken',
              '*.refreshToken',
              '*.openaiApiKey',
              '*.purchaseToken',
              'req.body.purchaseToken',
            ],
            censor: '[redacted]',
          },
        }
      : false,
    bodyLimit: config.maxBodyBytes,
    // Must cover Soulmate GPT Image latency (~120s app + buffer). Cloud Run
    // request timeout should be >= this value (deploy script uses 180s).
    requestTimeout:
      Math.max(config.openaiTimeoutMs, config.openaiImageTimeoutMs) + 15_000,
    genReqId: createRequestId,
  });

  app.decorateRequest('requestId', '');
  app.decorateRequest('identityKey', '');
  app.decorateRequest('authSubject', '');

  app.addHook('onRequest', async (request, reply) => {
    request.requestId = String(request.id);
    reply.header('x-request-id', request.requestId);
    reply.header('x-content-type-options', 'nosniff');
    reply.header('cache-control', 'no-store');
  });

  await app.register(helmet, {
    global: true,
    contentSecurityPolicy: false,
    crossOriginEmbedderPolicy: false,
  });

  app.setErrorHandler((error, request, reply) => {
    if (error instanceof ProxyError) {
      return reply.code(error.httpStatus).send(errorEnvelope(error.code));
    }
    const code = (error as { code?: string }).code;
    const status = (error as { statusCode?: number }).statusCode;
    if (code === 'FST_ERR_CTP_BODY_TOO_LARGE' || status === 413) {
      return reply.code(200).send(errorEnvelope(ErrorCode.invalidRequest));
    }
    if (code === 'FST_ERR_CTP_INVALID_MEDIA_TYPE' || status === 415) {
      return reply.code(200).send(errorEnvelope(ErrorCode.invalidRequest));
    }
    logSafe(request.log, 'error', 'unhandled_error', {
      requestId: request.requestId || String(request.id),
      status: 200,
      errorCode: ErrorCode.internalError,
    });
    return reply.code(200).send(errorEnvelope(ErrorCode.internalError));
  });

  await registerHealth(app, config, appCheck);
  await registerBillingRoutes(app, config, options.billing ?? {});
  const service = new AiProxyService(config, options.fetchImpl);
  await registerAiRoutes(app, config, service, { appCheck });
  return app;
}
