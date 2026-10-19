import { describe, expect, it } from 'vitest';
import { bindPurchaseOrder, clearPurchaseAttempt, getOrCreatePurchaseAttempt, isTerminalOrder, readPurchaseAttempt } from './purchase-attempt';

class MemoryStorage {
  private value = new Map<string, string>();
  getItem(key: string) { return this.value.get(key) ?? null; }
  setItem(key: string, value: string) { this.value.set(key, value); }
  removeItem(key: string) { this.value.delete(key); }
}

describe('coffee purchase attempt lifecycle', () => {
  it('reuses one key through refresh and binds only a non-sensitive order id', () => {
    const storage = new MemoryStorage();
    const first = getOrCreatePurchaseAttempt(storage, () => 'attempt_123456789');
    expect(getOrCreatePurchaseAttempt(storage, () => 'different_123456')).toEqual(first);
    bindPurchaseOrder(storage, first, 'ord_12345678');
    expect(readPurchaseAttempt(storage)).toEqual({ idempotencyKey: 'attempt_123456789', orderId: 'ord_12345678' });
  });

  it('clears only the matching terminal order so a later purchase gets a new key', () => {
    const storage = new MemoryStorage(); const first = getOrCreatePurchaseAttempt(storage, () => 'attempt_123456789');
    bindPurchaseOrder(storage, first, 'ord_12345678');
    expect(clearPurchaseAttempt(storage, 'ord_other123')).toBe(false);
    expect(clearPurchaseAttempt(storage, 'ord_12345678')).toBe(true);
    expect(getOrCreatePurchaseAttempt(storage, () => 'attempt_987654321').idempotencyKey).toBe('attempt_987654321');
  });

  it.each([
    ['entitlement_granted', undefined], ['entitlement_consumed', undefined], ['failed', undefined], ['refunded', undefined], ['payment_pending', 'failed'], ['entitlement_consumed', 'refunded'],
  ])('recognizes terminal order state %s/%s', (status, provider) => expect(isTerminalOrder(status, provider)).toBe(true));
  it('keeps created and pending attempts recoverable', () => { expect(isTerminalOrder('created')).toBe(false); expect(isTerminalOrder('payment_pending')).toBe(false); });
});
