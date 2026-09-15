import { createPublicKey, verify as cryptoVerify } from 'node:crypto';

export type AdMobSsvInput = {
  signedContent: string;
  signature: string;
  keyId: string;
};

export interface AdMobSsvVerifier { verify(input: AdMobSsvInput): Promise<boolean>; }

type KeyResponse = { keys?: Array<{ keyId?: number; pem?: string; base64?: string }> };

/** Google rotates SSV keys. Cache briefly, and always fail closed. */
export class GoogleAdMobSsvVerifier implements AdMobSsvVerifier {
  private keys = new Map<string, string>();
  private fetchedAt = 0;
  constructor(private readonly fetchImpl: typeof fetch = fetch) {}

  async verify(input: AdMobSsvInput): Promise<boolean> {
    if (!/^\d{1,20}$/.test(input.keyId) || !input.signature || input.signedContent.length > 8192) return false;
    try {
      if (Date.now() - this.fetchedAt > 60 * 60_000 || !this.keys.has(input.keyId)) await this.refresh();
      const pem = this.keys.get(input.keyId);
      if (!pem) return false;
      const signature = Buffer.from(input.signature.replace(/-/g, '+').replace(/_/g, '/'), 'base64');
      return cryptoVerify('sha256', Buffer.from(input.signedContent), createPublicKey(pem), signature);
    } catch { return false; }
  }

  private async refresh(): Promise<void> {
    const response = await this.fetchImpl('https://www.gstatic.com/admob/reward/verifier-keys.json', { signal: AbortSignal.timeout(5000) });
    if (!response.ok) throw new Error('ssv_keys_unavailable');
    const body = await response.json() as KeyResponse;
    const next = new Map<string, string>();
    for (const key of body.keys ?? []) {
      if (key.keyId == null) continue;
      const pem = key.pem ?? (key.base64 ? `-----BEGIN PUBLIC KEY-----\n${key.base64}\n-----END PUBLIC KEY-----` : null);
      if (pem) next.set(String(key.keyId), pem);
    }
    if (next.size === 0) throw new Error('ssv_keys_empty');
    this.keys = next; this.fetchedAt = Date.now();
  }
}

export function parseAdMobSsv(rawUrl: string): (AdMobSsvInput & { transactionId: string; customData: string }) | null {
  const queryAt = rawUrl.indexOf('?');
  if (queryAt < 0) return null;
  const rawQuery = rawUrl.slice(queryAt + 1);
  const signatureMarker = rawQuery.indexOf('&signature=');
  if (signatureMarker < 1) return null;
  const params = new URLSearchParams(rawQuery);
  const signature = params.get('signature'); const keyId = params.get('key_id');
  const transactionId = params.get('transaction_id'); const customData = params.get('custom_data');
  if (!signature || !keyId || !transactionId || !customData || transactionId.length > 256) return null;
  return { signedContent: rawQuery.slice(0, signatureMarker), signature, keyId, transactionId, customData };
}
