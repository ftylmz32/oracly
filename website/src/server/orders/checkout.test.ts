import { describe, expect, it, vi } from 'vitest';
import { COFFEE_READING_PRODUCT_ID } from '../../lib/orders/types';
import { CheckoutService, verifyResult } from './checkout';
import type { IyzicoCheckoutClient, IyzicoPaymentResult } from './iyzico';
import type { CheckoutOrderStore, StoredCoffeeOrder } from './store';

const order: StoredCoffeeOrder = { orderId: 'ord_12345678', ownerUserId: 'uid-a', productId: COFFEE_READING_PRODUCT_ID, catalogVersion: 'v1', priceMinor: 7250, currency: 'TRY', status: 'payment_pending', checkoutToken: 'token-12345678', createdAtMs: 1, updatedAtMs: 2, events: [{ status: 'created', atMs: 1 }, { status: 'payment_pending', atMs: 2 }] };
const paid = (extra: Partial<IyzicoPaymentResult> = {}): IyzicoPaymentResult => ({ status: 'paid', conversationId: order.orderId, checkoutToken: order.checkoutToken!, basketId: order.orderId, providerPaymentId: 'pay-1', paymentTransactionId: 'txn-1', transactionStatus: 2, priceMinor: 7250, paidPriceMinor: 7250, currency: 'TRY', fraudStatus: 1, itemProductId: COFFEE_READING_PRODUCT_ID, itemPriceMinor: 7250, ...extra });

describe('checkout reconciliation', () => {
  it.each([
    { conversationId: 'ord_other' }, { checkoutToken: 'other-token' }, { basketId: 'other-basket' },
    { priceMinor: 1 }, { paidPriceMinor: 1 }, { currency: 'USD' }, { itemProductId: 'other' }, { itemPriceMinor: 1 },
  ])('rejects mismatched provider authority %#', (change) => expect(() => verifyResult(order, paid(change))).toThrow('payment_mismatch'));

  it('requires paid + approved fraud status and makes duplicate callbacks idempotent', async () => {
    const confirm = vi.fn().mockResolvedValueOnce('granted').mockResolvedValueOnce('already_applied');
    const store = { getByCheckoutToken: vi.fn(async () => order), confirmCheckoutPayment: confirm, recordCheckoutState: vi.fn() } as unknown as CheckoutOrderStore;
    const provider = { retrieve: vi.fn(async () => paid()) } as unknown as IyzicoCheckoutClient;
    const service = new CheckoutService(store, provider, () => 10);
    await expect(service.reconcile(order.checkoutToken!)).resolves.toEqual({ outcome: 'granted', orderId: order.orderId });
    await expect(service.reconcile(order.checkoutToken!)).resolves.toEqual({ outcome: 'already_applied', orderId: order.orderId });
    expect(confirm).toHaveBeenCalledTimes(2);
  });

  it.each([
    paid({ status: 'pending' }), paid({ status: 'failed' }), paid({ status: 'refunded' }), paid({ fraudStatus: 0 }), paid({ fraudStatus: -1 }), paid({ transactionStatus: 0 }), paid({ transactionStatus: -1 }), paid({ transactionStatus: 1 }), paid({ paymentTransactionId: undefined }),
  ])('does not grant pending, failed, refunded, review, or rejected result %#', async (result) => {
    const confirm = vi.fn();
    const store = { getByCheckoutToken: vi.fn(async () => order), confirmCheckoutPayment: confirm, recordCheckoutState: vi.fn(async () => 'recorded') } as unknown as CheckoutOrderStore;
    const provider = { retrieve: vi.fn(async () => result) } as unknown as IyzicoCheckoutClient;
    await expect(new CheckoutService(store, provider).reconcile(order.checkoutToken!)).resolves.toEqual({ outcome: 'not_granted', orderId: order.orderId });
    expect(confirm).not.toHaveBeenCalled();
  });

  it('fails closed on retrieve timeout/network failure so a later callback can retry safely', async () => {
    const store = { getByCheckoutToken: vi.fn(async () => order), confirmCheckoutPayment: vi.fn(), recordCheckoutState: vi.fn() } as unknown as CheckoutOrderStore;
    const provider = { retrieve: vi.fn(async () => { throw new Error('timeout'); }) } as unknown as IyzicoCheckoutClient;
    await expect(new CheckoutService(store, provider).reconcile(order.checkoutToken!)).rejects.toThrow('timeout');
    expect(store.confirmCheckoutPayment).not.toHaveBeenCalled();
  });

  it('recovers a delayed payment on the same order without creating another checkout session', async () => {
    const confirm = vi.fn(async () => 'granted' as const);
    const store = { getByCheckoutToken: vi.fn(async () => order), confirmCheckoutPayment: confirm, recordCheckoutState: vi.fn() } as unknown as CheckoutOrderStore;
    const provider = { retrieve: vi.fn().mockResolvedValueOnce(paid({ status: 'pending', fraudStatus: 0, transactionStatus: 0 })).mockResolvedValueOnce(paid()) } as unknown as IyzicoCheckoutClient;
    const service = new CheckoutService(store, provider);
    await expect(service.reconcile(order.checkoutToken!)).resolves.toEqual({ outcome: 'not_granted', orderId: order.orderId });
    await expect(service.reconcile(order.checkoutToken!)).resolves.toEqual({ outcome: 'granted', orderId: order.orderId });
    expect(store.getByCheckoutToken).toHaveBeenCalledTimes(2); expect(confirm).toHaveBeenCalledOnce();
  });

  it('records a signed definitive failure even when nothing was captured', async () => {
    const record = vi.fn(async () => 'recorded' as const);
    const store = { getByCheckoutToken: vi.fn(async () => order), confirmCheckoutPayment: vi.fn(), recordCheckoutState: record } as unknown as CheckoutOrderStore;
    const provider = { retrieve: vi.fn(async () => paid({ status: 'failed', paidPriceMinor: 0, transactionStatus: -1, fraudStatus: -1 })) } as unknown as IyzicoCheckoutClient;
    await expect(new CheckoutService(store, provider).reconcile(order.checkoutToken!)).resolves.toEqual({ outcome: 'not_granted', orderId: order.orderId });
    expect(record).toHaveBeenCalledOnce(); expect(store.confirmCheckoutPayment).not.toHaveBeenCalled();
  });
});
