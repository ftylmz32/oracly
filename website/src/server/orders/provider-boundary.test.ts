import { describe, expect, it, vi } from 'vitest';
import type { PaymentResult } from '../../lib/orders/types';
import type { PersistentOrderStore } from './store';
import { VerifiedPaymentBoundary, type ServerPaymentProvider } from './provider-boundary';

describe('future iyzico server verification boundary', () => {
  it('requires signature verification and a provider retrieve before granting', async () => {
    const provider: ServerPaymentProvider = {
      verifyWebhookSignature: vi.fn(async () => ({ orderId: 'ord_test-order-1', checkoutToken: 'token-1' })),
      retrieveCheckoutResult: vi.fn(async (): Promise<PaymentResult> => ({ status: 'paid', conversationId: 'ord_test-order-1', providerPaymentId: 'payment-1', priceMinor: 7250, currency: 'TRY' })),
    };
    const store = { confirmVerifiedPayment: vi.fn(async () => 'granted') } as unknown as PersistentOrderStore;
    const boundary = new VerifiedPaymentBoundary(provider, store, () => 123);
    await expect(boundary.handle('{}', null)).rejects.toThrow('webhook_signature_required');
    await expect(boundary.handle('{}', 'signature')).resolves.toBe('granted');
    expect(provider.verifyWebhookSignature).toHaveBeenCalledTimes(1);
    expect(provider.retrieveCheckoutResult).toHaveBeenCalledWith('token-1');
    expect(store.confirmVerifiedPayment).toHaveBeenCalledWith(expect.objectContaining({ providerPaymentId: 'payment-1', priceMinor: 7250 }));
  });

  it('does not grant when the independently retrieved result is pending or mismatched', async () => {
    const store = { confirmVerifiedPayment: vi.fn() } as unknown as PersistentOrderStore;
    const provider: ServerPaymentProvider = {
      verifyWebhookSignature: async () => ({ orderId: 'ord_test-order-1', checkoutToken: 'token-1' }),
      retrieveCheckoutResult: async () => ({ status: 'pending', conversationId: 'ord_test-order-1', priceMinor: 7250, currency: 'TRY' }),
    };
    await expect(new VerifiedPaymentBoundary(provider, store).handle('{}', 'signature')).rejects.toThrow('payment_not_verified');
    expect(store.confirmVerifiedPayment).not.toHaveBeenCalled();
  });
});
