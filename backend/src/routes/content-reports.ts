import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import type { AppCheckVerifier } from '../auth/app-check.js';
import { createAuthenticationService } from '../auth/create-auth.js';
import type { AppConfig } from '../config.js';
import { ErrorCode, errorEnvelope, successEnvelope } from '../errors.js';
import { requireAppCheck } from '../middleware/app-check.js';
import { requireAuth } from '../middleware/auth.js';
import { createIdentityRateLimit } from '../middleware/rate-limit.js';
import type { SharedWindowStore } from '../rate-limit/shared-window-store.js';
import type { ReadingOperationRepository } from '../reading/operation-repository.js';
import {
  CONTENT_REPORT_RETENTION_MS,
  ContentReportStorageUnavailable,
  createContentReportRepository,
  type ContentReportRepository,
} from '../content-reports/content-report-repository.js';
import { AccountDeletedError } from '../account/deletion-barrier.js';

const FEATURES = new Set(['coffee', 'palm', 'tarot', 'astrology', 'starMap', 'dream', 'soulmate', 'companion']);
const CATEGORIES = new Set(['harmful', 'inappropriate', 'misleading', 'other']);
const EXACT_KEYS = new Set(['reportId', 'feature', 'category', 'contentRef', 'selectedContent', 'contentConsent']);
const MAX_SELECTED_CONTENT_LENGTH = 2_000;

export type ContentReportRouteOptions = {
  appCheck: AppCheckVerifier;
  repository?: ContentReportRepository;
  readingOperations: ReadingOperationRepository;
  sharedWindowStore?: SharedWindowStore;
  now?: () => number;
};

export async function registerContentReportRoutes(
  app: FastifyInstance,
  config: AppConfig,
  options: ContentReportRouteOptions,
): Promise<void> {
  const auth = requireAuth(createAuthenticationService(config));
  const appCheck = requireAppCheck(options.appCheck);
  const rateLimit = createIdentityRateLimit(
    Math.min(config.rateLimitMax, 10),
    config.rateLimitWindowMs,
    options.sharedWindowStore,
    'content-report',
  );
  const repository = options.repository ?? createContentReportRepository(config);
  const now = options.now ?? Date.now;

  app.post('/v1/content-reports', {
    preHandler: [validateContentReportBody, auth, appCheck, rateLimit],
  }, async (request, reply) => {
    const body = parseBody(request.body)!;
    const ownerUserId = request.identityKey;
    if (body.contentRef) {
      const operation = await options.readingOperations.getById(body.contentRef);
      if (!operation || operation.ownerUserId !== ownerUserId) {
        return reply.code(403).send(errorEnvelope(ErrorCode.forbidden));
      }
    }
    const createdAtMs = now();
    try {
      const saved = await repository.createIfAbsent({
        reportId: body.reportId,
        ownerUserId,
        feature: body.feature,
        category: body.category,
        contentRef: body.contentRef,
        reportedContent: body.selectedContent,
        contentSource: body.selectedContent == null ? null : 'user_selected_unverified',
        createdAtMs,
        expiresAtMs: createdAtMs + CONTENT_REPORT_RETENTION_MS,
        status: 'open',
      });
      return reply.code(saved.created ? 201 : 200).send(successEnvelope({
        reportId: saved.record.reportId,
        accepted: true,
        duplicate: !saved.created,
      }));
    } catch (error) {
      if (error instanceof ContentReportStorageUnavailable || error instanceof AccountDeletedError) {
        return reply.code(503).send(errorEnvelope(ErrorCode.internalError));
      }
      throw error;
    }
  });
}

async function validateContentReportBody(request: FastifyRequest, reply: FastifyReply): Promise<void> {
  const parsed = parseBody(request.body);
  if (!parsed) await reply.code(400).send(errorEnvelope(ErrorCode.invalidRequest));
}

function parseBody(value: unknown): {
  reportId: string;
  feature: string;
  category: string;
  contentRef: string | null;
  selectedContent: string | null;
} | null {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null;
  const body = value as Record<string, unknown>;
  if (Object.keys(body).some((key) => !EXACT_KEYS.has(key))) return null;
  if (typeof body.reportId !== 'string' || !/^[A-Za-z0-9_-]{16,80}$/.test(body.reportId)) return null;
  if (typeof body.feature !== 'string' || !FEATURES.has(body.feature)) return null;
  if (typeof body.category !== 'string' || !CATEGORIES.has(body.category)) return null;
  const contentRef = body.contentRef;
  if (contentRef != null && (typeof contentRef !== 'string' || !/^[A-Za-z0-9_-]{8,128}$/.test(contentRef))) return null;
  const selectedContent = body.selectedContent;
  if (selectedContent != null) {
    if (typeof selectedContent !== 'string' || selectedContent.trim().length === 0 || selectedContent.length > MAX_SELECTED_CONTENT_LENGTH) return null;
    if (body.contentConsent !== true) return null;
  } else if (body.contentConsent != null) {
    return null;
  }
  return {
    reportId: body.reportId,
    feature: body.feature,
    category: body.category,
    contentRef: contentRef ?? null,
    selectedContent: typeof selectedContent === 'string' ? selectedContent.trim() : null,
  };
}
