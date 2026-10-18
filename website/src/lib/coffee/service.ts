import { buildCoffeeV3CreateBody, createSourceRequestId, fileToBase64, WEB_SLOT_TO_SERVER_SLOT, type WebCoffeeSlot } from './contracts';
import { getFirebaseRequestTokens, hasFirebaseWebConfiguration } from '../firebase/client';
import { BrowserCoffeeRecoveryStore, type CoffeeRecoveryRecord, type CoffeeRecoveryStore } from './recovery';
import { parseCoffeeResultDelivery, type CoffeeResultDelivery, type CoffeeV3PublicResult } from './result';

export type CoffeeFlowPhase = 'preparing' | 'uploading' | 'waiting' | 'processing' | 'delivering' | 'ready' | 'failed';
export type CoffeeFlowUpdate = { phase: CoffeeFlowPhase; message: string; uploaded?: number; failureCode?: string };
export type CoffeeFlowResult = { kind: 'demo' | 'live'; delivery: CoffeeResultDelivery };
export type CoffeeRunInput = {
  files: Record<WebCoffeeSlot, File>;
  intention: string;
  /** Server-created, Firebase UID-owned paid order. Required only by live mode. */
  orderId?: string;
  onUpdate(update: CoffeeFlowUpdate): void;
};

export interface CoffeeService {
  run(input: CoffeeRunInput): Promise<CoffeeFlowResult>;
}

type PublicOperation = {
  operationId: string;
  status: 'waiting' | 'processing' | 'ready' | 'failed';
  remainingMs: number;
  resultReady: boolean;
  resultId: string | null;
  failureCode?: string;
};

type SuccessEnvelope<T> = { success: true; data: T };

async function wait(ms: number) { await new Promise((resolve) => setTimeout(resolve, ms)); }

type RequestTokens = { authToken: string; appCheckToken: string };
type LiveCoffeeServiceOptions = {
  fetchImpl?: typeof fetch;
  getTokens?: () => Promise<RequestTokens>;
  recovery?: CoffeeRecoveryStore;
  sleep?: (ms: number) => Promise<void>;
  statusAttempts?: number;
  resultAttempts?: number;
};

class CoffeeHttpError extends Error {
  constructor(readonly status: number, readonly code: string) { super(code); }
}

export class LiveCoffeeService implements CoffeeService {
  private readonly fetchImpl: typeof fetch;
  private readonly getTokens: () => Promise<RequestTokens>;
  private readonly recovery: CoffeeRecoveryStore;
  private readonly sleep: (ms: number) => Promise<void>;
  private readonly statusAttempts: number;
  private readonly resultAttempts: number;

  constructor(private readonly baseUrl: string, options: LiveCoffeeServiceOptions = {}) {
    this.fetchImpl = options.fetchImpl ?? fetch;
    this.getTokens = options.getTokens ?? getFirebaseRequestTokens;
    this.recovery = options.recovery ?? new BrowserCoffeeRecoveryStore();
    this.sleep = options.sleep ?? wait;
    this.statusAttempts = options.statusAttempts ?? 90;
    this.resultAttempts = options.resultAttempts ?? 8;
  }

  async run(input: CoffeeRunInput): Promise<CoffeeFlowResult> {
    if (!input.orderId) throw new Error('verified_order_required');
    input.onUpdate({ phase: 'preparing', message: 'Güvenli oturum hazırlanıyor.' });
    let recovery = this.recovery.load();
    if (!recovery) {
      recovery = { version: 1, sourceRequestId: createSourceRequestId(), stagedSlots: [], createdAtMs: Date.now() };
      this.recovery.save(recovery);
    }
    let operationId = recovery.operationId;
    if (!operationId) {
      const operation = await this.request<PublicOperation>(`/v1/web/coffee-orders/${encodeURIComponent(input.orderId)}/reading-operation`, {
        method: 'POST', body: JSON.stringify(buildCoffeeV3CreateBody(recovery.sourceRequestId, input.intention)),
      });
      operationId = operation.operationId;
      recovery = { ...recovery, operationId };
      this.recovery.save(recovery);
    }

    const orderedSlots = Object.entries(WEB_SLOT_TO_SERVER_SLOT) as Array<[WebCoffeeSlot, CoffeeRecoveryRecord['stagedSlots'][number]]>;
    for (let index = 0; index < orderedSlots.length; index += 1) {
      const [webSlot, serverSlot] = orderedSlots[index];
      if (recovery.stagedSlots.includes(serverSlot)) continue;
      input.onUpdate({ phase: 'uploading', message: `${index + 1}/3 fotoğraf güvenli alana hazırlanıyor.`, uploaded: index });
      const file = input.files[webSlot];
      await this.request(`/v1/reading-operations/${operationId}/staged-image`, {
        method: 'POST', body: JSON.stringify({ mimeType: file.type, imageBase64: await fileToBase64(file), slot: serverSlot }),
      });
      recovery = { ...recovery, stagedSlots: [...recovery.stagedSlots, serverSlot] };
      this.recovery.save(recovery);
    }

    input.onUpdate({ phase: 'waiting', message: 'Fotoğraflar hazır. İşlem sırası bekleniyor.', uploaded: 3 });
    for (let attempt = 0; attempt < this.statusAttempts; attempt += 1) {
      const status = await this.request<PublicOperation>(`/v1/reading-operations/${operationId}`);
      if (status.status === 'failed') {
        input.onUpdate({ phase: 'failed', message: 'İşlem güvenli biçimde tamamlanamadı.', failureCode: status.failureCode });
        throw new Error(status.failureCode ?? 'operation_failed');
      }
      if (status.status === 'processing') input.onUpdate({ phase: 'processing', message: 'Fincan görüntüleri işleniyor.' });
      if (status.resultReady && status.resultId) {
        input.onUpdate({ phase: 'delivering', message: 'Sonuç güvenli biçimde teslim alınıyor.' });
        const delivery = await this.fetchResult(operationId, status.resultId);
        this.recovery.clear();
        input.onUpdate({ phase: 'ready', message: 'Fal sonucu güvenli biçimde teslim edildi.' });
        return { kind: 'live', delivery };
      }
      await this.sleep(Math.min(Math.max(status.remainingMs, 1200), 4000));
    }
    throw new Error('operation_timeout');
  }

  private async fetchResult(operationId: string, resultId: string): Promise<CoffeeResultDelivery> {
    for (let attempt = 0; attempt < this.resultAttempts; attempt += 1) {
      try {
        const payload = await this.request<unknown>(`/v1/reading-operations/${operationId}/result`);
        return parseCoffeeResultDelivery(payload, { operationId, resultId });
      } catch (error) {
        const retryable = error instanceof TypeError || (error instanceof CoffeeHttpError && (error.status === 404 || error.status === 503));
        if (!retryable || attempt === this.resultAttempts - 1) throw error;
        await this.sleep(Math.min(500 * (2 ** attempt), 4000));
      }
    }
    throw new Error('result_delivery_timeout');
  }

  private async request<T>(path: string, init: RequestInit = {}): Promise<T> {
    const tokens = await this.getTokens();
    const response = await this.fetchImpl(`${this.baseUrl}${path}`, {
      ...init,
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${tokens.authToken}`, 'X-Firebase-AppCheck': tokens.appCheckToken, ...init.headers },
    });
    const payload = await response.json() as SuccessEnvelope<T> | { success: false; error?: { code?: string } };
    if (!response.ok || !payload.success) throw new CoffeeHttpError(response.status, !payload.success ? payload.error?.code ?? 'request_failed' : 'request_failed');
    return payload.data;
  }
}

export class MockCoffeeService implements CoffeeService {
  private shouldFail: boolean;
  constructor(scenario: 'success' | 'fail-once' = 'success', private readonly stepDelayMs = 20) {
    this.shouldFail = scenario === 'fail-once';
  }
  async run(input: CoffeeRunInput): Promise<CoffeeFlowResult> {
    input.onUpdate({ phase: 'preparing', message: 'Demo isteği hazırlanıyor.' });
    buildCoffeeV3CreateBody('web_mock_request_1234', input.intention);
    await wait(this.stepDelayMs);
    for (let index = 0; index < 3; index += 1) {
      input.onUpdate({ phase: 'uploading', message: `${index + 1}/3 demo fotoğraf hazırlanıyor.`, uploaded: index });
      await wait(this.stepDelayMs);
    }
    input.onUpdate({ phase: 'waiting', message: 'Demo işlem sırası bekleniyor.', uploaded: 3 });
    await wait(this.stepDelayMs);
    input.onUpdate({ phase: 'processing', message: 'Demo işlem durumu canlandırılıyor.' });
    await wait(this.stepDelayMs);
    if (this.shouldFail) {
      this.shouldFail = false;
      input.onUpdate({ phase: 'failed', message: 'Demo bağlantısı kesildi.', failureCode: 'network' });
      throw new Error('network');
    }
    input.onUpdate({ phase: 'delivering', message: 'Demo sonucu teslim ediliyor.' });
    const result: CoffeeV3PublicResult = {
      coffeeResultContract: 'm2_public_v1', visualObservation: '',
      overall: 'Bu, sonuç teslim ekranını doğrulamak için hazırlanmış demo metnidir. Gerçek bir fal veya AI yorumu değildir.\n\nGerçek servis etkinleştirilmeden hiçbir ödeme alınmaz ve yeni fal işlemi başlatılmaz.',
      love: '', career: '', money: '', nearFuture: '', takeaway: '', symbols: [],
    };
    const delivery: CoffeeResultDelivery = {
      operationId: 'demo_operation', resultId: 'demo_coffee_result', readingType: 'coffee',
      persistedAt: new Date(0).toISOString(), result,
    };
    input.onUpdate({ phase: 'ready', message: 'Demo akışı tamamlandı.' });
    return { kind: 'demo', delivery };
  }
}

export type CoffeeRuntime = { mode: 'mock' | 'live' | 'unavailable'; service: CoffeeService | null; canRun: boolean; reason: string };

function safeApiBaseUrl(value: string | undefined): string | null {
  if (!value) return null;
  try {
    const parsed = new URL(value);
    const localDevelopment = process.env.NODE_ENV !== 'production' && parsed.protocol === 'http:' && ['localhost', '127.0.0.1'].includes(parsed.hostname);
    if (parsed.protocol !== 'https:' && !localDevelopment) return null;
    return parsed.toString().replace(/\/$/, '');
  } catch { return null; }
}

export function getCoffeeRuntime(): CoffeeRuntime {
  const requested = process.env.NEXT_PUBLIC_ORACLY_COFFEE_SERVICE?.trim();
  const query = typeof window !== 'undefined' ? new URLSearchParams(window.location.search) : null;
  const localMockRequested = requested === 'mock' || query?.get('mockMode') === '1';
  if (process.env.NODE_ENV !== 'production' && localMockRequested) {
    const scenario = query?.get('mockScenario') === 'fail-once' ? 'fail-once' : 'success';
    return { mode: 'mock', service: new MockCoffeeService(scenario), canRun: true, reason: 'Yerel demo sağlayıcısı etkin.' };
  }
  const baseUrl = safeApiBaseUrl(process.env.NEXT_PUBLIC_ORACLY_API_BASE_URL?.trim());
  const liveFlag = process.env.NEXT_PUBLIC_ORACLY_COFFEE_LIVE_ENABLED === 'true';
  if (liveFlag && baseUrl && hasFirebaseWebConfiguration()) {
    return { mode: 'live', service: new LiveCoffeeService(baseUrl), canRun: false, reason: 'Firebase hazır; sunucu tarafında doğrulanmış ödeme yetkisi bekleniyor.' };
  }
  return { mode: 'unavailable', service: null, canRun: false, reason: 'Firebase Web App, App Check ve API yapılandırması tamamlanmadı.' };
}
