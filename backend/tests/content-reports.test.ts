import { describe, expect, it } from 'vitest';
import { StaticAppCheckVerifier } from '../src/auth/app-check.js';
import { identityKeyFromOpaqueToken } from '../src/auth/identity.js';
import type {
  ContentReportCreateResult,
  ContentReportRecord,
  ContentReportRepository,
} from '../src/content-reports/content-report-repository.js';
import { FirestoreContentReportRepository } from '../src/content-reports/content-report-repository.js';
import { accountDeletionReceiptId } from '../src/account/deletion-barrier.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import type { ReadingOperationRepository } from '../src/reading/operation-repository.js';
import { MemorySharedWindowStore } from '../src/rate-limit/shared-window-store.js';
import { appCheckHeader, authHeader, testApp, testConfig } from './helpers.js';

class MemoryReports implements ContentReportRepository {
  readonly records = new Map<string, ContentReportRecord>();
  async createIfAbsent(record: ContentReportRecord): Promise<ContentReportCreateResult> {
    const key = `${record.ownerUserId}\0${record.reportId}`;
    const existing = this.records.get(key);
    if (existing) return { created: false, record: existing };
    this.records.set(key, structuredClone(record));
    return { created: true, record };
  }
}

function operations(owner: string): ReadingOperationRepository {
  return {
    async getById(operationId) {
      if (operationId === 'owned_op_123') return { operationId, ownerUserId: owner } as never;
      if (operationId === 'other_op_123') return { operationId, ownerUserId: 'other-owner' } as never;
      return null;
    },
    async createIfAbsent() { throw new Error('unused'); },
    async mutate() { throw new Error('unused'); },
  };
}

const token = 'report-user-token';
const owner = identityKeyFromOpaqueToken(token);
const headers = { ...authHeader(token), ...appCheckHeader('good-app-check') };
const body = {
  reportId: 'report_0123456789abcdef',
  feature: 'coffee',
  category: 'harmful',
  contentRef: 'owned_op_123',
};

async function app(reports = new MemoryReports(), max = '20') {
  return {
    reports,
    server: await testApp(testConfig({ AI_RATE_LIMIT_MAX: max }), undefined, {
      appCheck: new StaticAppCheckVerifier('good-app-check'),
      readingOperationRepository: operations(owner),
      contentReportRepository: reports,
      sharedWindowStore: new MemorySharedWindowStore(),
    }),
  };
}

describe('AI content reports', () => {
  it('authenticates, owner-checks and durably accepts metadata only', async () => {
    const h = await app();
    const response = await h.server.inject({ method: 'POST', url: '/v1/content-reports', headers, payload: body });
    expect(response.statusCode).toBe(201);
    expect(response.json().data).toEqual({ reportId: body.reportId, accepted: true, duplicate: false });
    expect(h.reports.records.size).toBe(1);
    const stored = [...h.reports.records.values()][0]!;
    expect(stored).toMatchObject({ ownerUserId: owner, feature: 'coffee', category: 'harmful', contentRef: 'owned_op_123', status: 'open' });
    expect(stored.expiresAtMs - stored.createdAtMs).toBe(30 * 24 * 60 * 60 * 1_000);
    expect(Object.keys(stored).sort()).toEqual([
      'category', 'contentRef', 'contentSource', 'createdAtMs', 'expiresAtMs', 'feature', 'ownerUserId', 'reportId', 'reportedContent', 'status',
    ]);
    await h.server.close();
  });

  it('requires both authentication and App Check', async () => {
    const h = await app();
    const noAuth = await h.server.inject({ method: 'POST', url: '/v1/content-reports', headers: appCheckHeader('good-app-check'), payload: body });
    expect(noAuth.statusCode).toBe(401);
    expect(noAuth.json().error.code).toBe('unauthorized');
    const noAppCheck = await h.server.inject({ method: 'POST', url: '/v1/content-reports', headers: authHeader(token), payload: body });
    expect(noAppCheck.statusCode).toBe(401);
    expect(noAppCheck.json().error.code).toBe('app_check_required');
    await h.server.close();
  });

  it('rejects another owner content reference without storing', async () => {
    const h = await app();
    const response = await h.server.inject({ method: 'POST', url: '/v1/content-reports', headers, payload: { ...body, contentRef: 'other_op_123' } });
    expect(response.statusCode).toBe(403);
    expect(h.reports.records.size).toBe(0);
    await h.server.close();
  });

  it('rejects private or unknown fields and invalid enums', async () => {
    const h = await app();
    for (const payload of [
      { ...body, content: 'private AI answer' },
      { ...body, question: 'private user question' },
      { ...body, feature: 'unknown' },
      { ...body, category: 'generic' },
    ]) {
      const response = await h.server.inject({ method: 'POST', url: '/v1/content-reports', headers, payload });
      expect(response.statusCode).toBe(400);
    }
    expect(h.reports.records.size).toBe(0);
    await h.server.close();
  });

  it('stores only explicitly consented, bounded selected AI output and labels it unverified', async () => {
    const h = await app();
    const response = await h.server.inject({
      method: 'POST', url: '/v1/content-reports', headers,
      payload: { ...body, contentRef: null, selectedContent: ' selected AI answer ', contentConsent: true },
    });
    expect(response.statusCode).toBe(201);
    expect([...h.reports.records.values()][0]).toMatchObject({
      reportedContent: 'selected AI answer',
      contentSource: 'user_selected_unverified',
      contentRef: null,
    });
    for (const payload of [
      { ...body, selectedContent: 'private', contentConsent: false },
      { ...body, selectedContent: 'private' },
      { ...body, contentConsent: true },
      { ...body, selectedContent: 'x'.repeat(2001), contentConsent: true },
    ]) {
      expect((await h.server.inject({ method: 'POST', url: '/v1/content-reports', headers, payload })).statusCode).toBe(400);
    }
    await h.server.close();
  });

  it('replays the same report id without a second record', async () => {
    const h = await app();
    const first = await h.server.inject({ method: 'POST', url: '/v1/content-reports', headers, payload: body });
    const second = await h.server.inject({ method: 'POST', url: '/v1/content-reports', headers, payload: body });
    expect(first.statusCode).toBe(201);
    expect(second.statusCode).toBe(200);
    expect(second.json().data.duplicate).toBe(true);
    expect(h.reports.records.size).toBe(1);
    await h.server.close();
  });

  it('rate-limits report spam independently', async () => {
    const h = await app(new MemoryReports(), '2');
    const statuses = [];
    for (let i = 0; i < 3; i++) {
      const response = await h.server.inject({ method: 'POST', url: '/v1/content-reports', headers, payload: { ...body, reportId: `report_0123456789abcde${i}` } });
      statuses.push(response.statusCode);
    }
    expect(statuses).toEqual([201, 201, 429]);
    expect(h.reports.records.size).toBe(2);
    await h.server.close();
  });

  it('account-deletion barrier prevents a late durable report write', async () => {
    const store = new MemoryDocumentStore();
    store.docs.set(`accountDeletionReceipts/${accountDeletionReceiptId(owner)}`, {
      status: 'deleting',
    });
    const repository = new FirestoreContentReportRepository(store);
    const h = await app(repository as never);
    const response = await h.server.inject({ method: 'POST', url: '/v1/content-reports', headers, payload: body });
    expect(response.statusCode).toBe(503);
    expect([...store.docs.keys()].some((key) => key.startsWith('aiContentReports/'))).toBe(false);
    await h.server.close();
  });
});
