/**
 * Google Play one-time product read and consume. No credentials live here.
 * purchaseState 0 is the only completed purchase. Pending and canceled grant nothing.
 */
export type PlayConsumableDecision =
  | { ok: true; transactionId: string; alreadyConsumed: boolean }
  | { ok: false; reason: 'pending' | 'canceled' | 'invalid' | 'product_mismatch'; transactionId?: string };

export function interpretPlayConsumable(
  body: Record<string, unknown>,
  productId: string,
): PlayConsumableDecision {
  if (typeof body.productId === 'string' && body.productId !== productId) {
    return { ok: false, reason: 'product_mismatch' };
  }
  const state = Number(body.purchaseState);
  const orderId = typeof body.orderId === 'string' ? body.orderId.trim() : '';
  if (state === 2) return { ok: false, reason: 'pending', transactionId: orderId || undefined };
  if (state === 1) return { ok: false, reason: 'canceled', transactionId: orderId || undefined };
  if (state !== 0 || !orderId) return { ok: false, reason: 'invalid' };
  return {
    ok: true,
    transactionId: orderId,
    alreadyConsumed: Number(body.consumptionState) === 1,
  };
}

export function playProductUrl(packageName: string, productId: string, token: string): string {
  return 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/'
    + `${encodeURIComponent(packageName)}/purchases/products/`
    + `${encodeURIComponent(productId)}/tokens/${encodeURIComponent(token)}`;
}

export async function readPlayConsumable(input: {
  fetchImpl: typeof fetch;
  packageName: string;
  productId: string;
  purchaseToken: string;
  accessToken: string;
}): Promise<PlayConsumableDecision | { ok: false; reason: 'provider_unavailable' }> {
  const response = await input.fetchImpl(
    playProductUrl(input.packageName, input.productId, input.purchaseToken),
    { headers: { authorization: `Bearer ${input.accessToken}` } },
  );
  if (response.status === 404 || response.status === 410) return { ok: false, reason: 'invalid' };
  if (!response.ok) return { ok: false, reason: 'provider_unavailable' };
  const body = (await response.json()) as Record<string, unknown>;
  return interpretPlayConsumable(body, input.productId);
}

/** 204 consumed, 409 already consumed. Anything else stays retryable. */
export async function consumePlayPurchase(input: {
  fetchImpl: typeof fetch;
  packageName: string;
  productId: string;
  purchaseToken: string;
  accessToken: string;
}): Promise<'done' | 'pending'> {
  const response = await input.fetchImpl(
    `${playProductUrl(input.packageName, input.productId, input.purchaseToken)}:consume`,
    { method: 'POST', headers: { authorization: `Bearer ${input.accessToken}` } },
  );
  if (response.status === 200 || response.status === 204 || response.status === 409) return 'done';
  return 'pending';
}
