export const PURCHASE_ATTEMPT_KEY = 'oracly_coffee_purchase_attempt_v1';

export type PurchaseAttempt = { idempotencyKey: string; orderId?: string };
type StorageLike = Pick<Storage, 'getItem' | 'setItem' | 'removeItem'>;

export function readPurchaseAttempt(storage: StorageLike): PurchaseAttempt | null {
  const raw = storage.getItem(PURCHASE_ATTEMPT_KEY);
  if (!raw) return null;
  try {
    const value = JSON.parse(raw) as Record<string, unknown>;
    if (typeof value.idempotencyKey !== 'string' || !/^[A-Za-z0-9_-]{16,80}$/u.test(value.idempotencyKey)) return null;
    if (value.orderId !== undefined && (typeof value.orderId !== 'string' || !/^ord_[A-Za-z0-9-]{8,80}$/u.test(value.orderId))) return null;
    return { idempotencyKey: value.idempotencyKey, ...(value.orderId ? { orderId: value.orderId } : {}) };
  } catch { return null; }
}

export function getOrCreatePurchaseAttempt(storage: StorageLike, createId = () => crypto.randomUUID().replaceAll('-', '_')): PurchaseAttempt {
  const current = readPurchaseAttempt(storage);
  if (current) return current;
  const created = { idempotencyKey: createId() };
  storage.setItem(PURCHASE_ATTEMPT_KEY, JSON.stringify(created));
  return created;
}

export function bindPurchaseOrder(storage: StorageLike, attempt: PurchaseAttempt, orderId: string): PurchaseAttempt {
  const bound = { idempotencyKey: attempt.idempotencyKey, orderId };
  storage.setItem(PURCHASE_ATTEMPT_KEY, JSON.stringify(bound));
  return bound;
}

export function clearPurchaseAttempt(storage: StorageLike, orderId?: string): boolean {
  const current = readPurchaseAttempt(storage);
  if (!current || (orderId && current.orderId !== orderId)) return false;
  storage.removeItem(PURCHASE_ATTEMPT_KEY);
  return true;
}

export function isTerminalOrder(status: string, providerPaymentStatus?: string): boolean {
  return providerPaymentStatus === 'failed' || providerPaymentStatus === 'refunded' || ['failed', 'refunded', 'entitlement_granted', 'entitlement_consumed'].includes(status);
}
