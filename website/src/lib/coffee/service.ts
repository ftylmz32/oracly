import { buildCoffeeV3CreateBody, createSourceRequestId, fileToBase64, WEB_SLOT_TO_SERVER_SLOT, type WebCoffeeSlot } from './contracts';
import { getFirebaseRequestTokens, hasFirebaseWebConfiguration } from '../firebase/client';

export type CoffeeFlowPhase = 'preparing' | 'uploading' | 'waiting' | 'processing' | 'ready' | 'failed';
export type CoffeeFlowUpdate = { phase: CoffeeFlowPhase; message: string; uploaded?: number; failureCode?: string };
export type CoffeeFlowResult = { kind: 'demo'; resultId: string } | { kind: 'live-result-unavailable'; resultId: string };
export type CoffeeRunInput = {
  files: Record<WebCoffeeSlot, File>;
  intention: string;
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

export class LiveCoffeeService implements CoffeeService {
  constructor(private readonly baseUrl: string) {}

  async run(input: CoffeeRunInput): Promise<CoffeeFlowResult> {
    input.onUpdate({ phase: 'preparing', message: 'Güvenli oturum hazırlanıyor.' });
    const sourceRequestId = createSourceRequestId();
    const operation = await this.request<PublicOperation>('/v1/reading-operations', {
      method: 'POST',
      body: JSON.stringify(buildCoffeeV3CreateBody(sourceRequestId, input.intention)),
    });
    const orderedSlots = Object.entries(WEB_SLOT_TO_SERVER_SLOT) as Array<[WebCoffeeSlot, string]>;
    for (let index = 0; index < orderedSlots.length; index += 1) {
      const [webSlot, serverSlot] = orderedSlots[index];
      const file = input.files[webSlot];
      input.onUpdate({ phase: 'uploading', message: `${index + 1}/3 fotoğraf güvenli alana hazırlanıyor.`, uploaded: index });
      await this.request(`/v1/reading-operations/${operation.operationId}/staged-image`, {
        method: 'POST',
        body: JSON.stringify({ mimeType: file.type, imageBase64: await fileToBase64(file), slot: serverSlot }),
      });
    }
    input.onUpdate({ phase: 'waiting', message: 'Fotoğraflar hazır. İşlem sırası bekleniyor.', uploaded: 3 });
    for (let attempt = 0; attempt < 90; attempt += 1) {
      const status = await this.request<PublicOperation>(`/v1/reading-operations/${operation.operationId}`);
      if (status.status === 'failed') {
        input.onUpdate({ phase: 'failed', message: 'İşlem güvenli biçimde tamamlanamadı.', failureCode: status.failureCode });
        throw new Error(status.failureCode ?? 'operation_failed');
      }
      if (status.status === 'processing') input.onUpdate({ phase: 'processing', message: 'Fincan görüntüleri işleniyor.' });
      if (status.resultReady && status.resultId) {
        input.onUpdate({ phase: 'ready', message: 'İşlem tamamlandı; sonuç teslim sözleşmesi bekleniyor.' });
        return { kind: 'live-result-unavailable', resultId: status.resultId };
      }
      await wait(Math.min(Math.max(status.remainingMs, 1200), 4000));
    }
    throw new Error('operation_timeout');
  }

  private async request<T>(path: string, init: RequestInit = {}): Promise<T> {
    const tokens = await getFirebaseRequestTokens();
    const response = await fetch(`${this.baseUrl}${path}`, {
      ...init,
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokens.authToken}`,
        'X-Firebase-AppCheck': tokens.appCheckToken,
        ...init.headers,
      },
    });
    const payload = await response.json() as SuccessEnvelope<T> | { success: false; error?: { code?: string } };
    if (!response.ok || !payload.success) throw new Error(!payload.success ? payload.error?.code ?? 'request_failed' : 'request_failed');
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
    input.onUpdate({ phase: 'ready', message: 'Demo akışı tamamlandı.' });
    return { kind: 'demo', resultId: 'demo_coffee_result' };
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
    return { mode: 'live', service: new LiveCoffeeService(baseUrl), canRun: false, reason: 'Firebase hazır; doğrulanmış ödeme ve sonuç teslim route’u bekleniyor.' };
  }
  return { mode: 'unavailable', service: null, canRun: false, reason: 'Firebase Web App, App Check ve API yapılandırması tamamlanmadı.' };
}
