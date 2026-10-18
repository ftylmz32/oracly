import { describe, expect, it } from 'vitest';
import { FakeCheckoutProvider } from './provider';
import { InMemoryOrderRepository } from './repository';
import { CoffeeOrderService } from './service';
import { COFFEE_READING_PRODUCT_ID, type PaymentResult } from './types';

const paid = (orderId: string, paymentId = 'payment-1'): PaymentResult => ({ status: 'paid', conversationId: orderId, providerPaymentId: paymentId, priceMinor: 1, currency: 'TRY' });

function fixture() {
  const repository = new InMemoryOrderRepository(); const provider = new FakeCheckoutProvider();
  return { repository, provider, service: new CoffeeOrderService(repository, provider, () => 1_800_000_000_000) };
}

async function pending(owner = 'uid-a', orderId = 'order_12345678') {
  const value = fixture();
  await value.service.create(owner, { requestId: orderId, productId: COFFEE_READING_PRODUCT_ID });
  const checkout = await value.service.beginCheckout(owner, orderId);
  return { ...value, owner, orderId, checkout };
}

describe('secure coffee order foundation', () => {
  it('forbids the fake payment provider in production', () => {
    expect(() => new FakeCheckoutProvider('test', 'production')).toThrow('fake_checkout_provider_forbidden');
  });

  it('uses the server catalog and rejects client price/payment claims', async () => {
    const { service } = fixture();
    await expect(service.create('uid-a', { requestId: 'order_12345678', productId: COFFEE_READING_PRODUCT_ID, price: 1 })).rejects.toThrow('client_authority_rejected');
    await expect(service.create('uid-a', { requestId: 'order_12345679', productId: COFFEE_READING_PRODUCT_ID, paid: true })).rejects.toThrow('client_authority_rejected');
    const order = await service.create('uid-a', { requestId: 'order_12345680', productId: COFFEE_READING_PRODUCT_ID });
    expect(order).toMatchObject({ priceMinor: 1, currency: 'TRY', ownerUserId: 'uid-a' });
  });

  it('makes duplicate notifications idempotent and grants only one entitlement', async () => {
    const { service, provider, orderId, checkout } = await pending(); provider.setResult(checkout.token, paid(orderId));
    const first = await service.applyWebhook(orderId, JSON.stringify({ token: checkout.token }), 'test-only-signature');
    const duplicate = await service.applyWebhook(orderId, JSON.stringify({ token: checkout.token }), 'test-only-signature');
    expect(first.status).toBe('entitlement_granted'); expect(duplicate.status).toBe('entitlement_granted');
    expect(duplicate.events.filter((event) => event.status === 'entitlement_granted')).toHaveLength(1);
  });

  it('serializes concurrent consumption so only one operation spends the right', async () => {
    const { service, provider, orderId, owner, checkout } = await pending(); provider.setResult(checkout.token, paid(orderId));
    await service.retrieveAndApply(owner, orderId);
    const outcomes = await Promise.all([service.consume(owner, orderId, 'operation-a'), service.consume(owner, orderId, 'operation-b')]);
    expect(outcomes.sort()).toEqual(['consumed', 'not_entitled']);
  });

  it('rejects forged webhooks and leaves the order pending', async () => {
    const { service, provider, repository, orderId, checkout } = await pending(); provider.setResult(checkout.token, paid(orderId));
    await expect(service.applyWebhook(orderId, JSON.stringify({ token: checkout.token }), 'forged')).rejects.toThrow('invalid_webhook_signature');
    expect((await repository.get(orderId))?.status).toBe('payment_pending');
  });

  it('rejects use from another account without revealing the order', async () => {
    const { service, provider, orderId, checkout } = await pending(); provider.setResult(checkout.token, paid(orderId)); await service.retrieveAndApply('uid-a', orderId);
    expect(await service.consume('uid-b', orderId, 'operation-a')).toBe('wrong_owner');
    await expect(service.retrieveAndApply('uid-b', orderId)).rejects.toThrow('order_not_found');
  });

  it('cannot reuse one provider payment for two orders, including concurrently', async () => {
    const { service, provider } = fixture();
    for (const orderId of ['order_12345678', 'order_12345679']) { await service.create('uid-a', { requestId: orderId, productId: COFFEE_READING_PRODUCT_ID }); const session = await service.beginCheckout('uid-a', orderId); provider.setResult(session.token, paid(orderId, 'same-payment')); }
    const outcomes = await Promise.allSettled([service.retrieveAndApply('uid-a', 'order_12345678'), service.retrieveAndApply('uid-a', 'order_12345679')]);
    expect(outcomes.filter((item) => item.status === 'fulfilled')).toHaveLength(1); expect(outcomes.filter((item) => item.status === 'rejected')).toHaveLength(1);
  });

  it('rejects amount/currency mismatches and records failed/refunded terminal states', async () => {
    const mismatch = await pending(); mismatch.provider.setResult(mismatch.checkout.token, { ...paid(mismatch.orderId), priceMinor: 2 });
    await expect(mismatch.service.retrieveAndApply(mismatch.owner, mismatch.orderId)).rejects.toThrow('payment_mismatch');
    const failed = await pending('uid-a', 'order_12345679'); failed.provider.setResult(failed.checkout.token, { status: 'failed', conversationId: failed.orderId, priceMinor: 1, currency: 'TRY', reason: 'declined' });
    expect((await failed.service.retrieveAndApply(failed.owner, failed.orderId)).status).toBe('failed');
    const refunded = await pending('uid-a', 'order_12345680'); refunded.provider.setResult(refunded.checkout.token, paid(refunded.orderId)); await refunded.service.retrieveAndApply(refunded.owner, refunded.orderId);
    refunded.provider.setResult(refunded.checkout.token, { status: 'refunded', conversationId: refunded.orderId, providerPaymentId: 'payment-1', priceMinor: 1, currency: 'TRY' });
    expect((await refunded.service.retrieveAndApply(refunded.owner, refunded.orderId)).status).toBe('refunded');
    expect(await refunded.service.consume(refunded.owner, refunded.orderId, 'operation-a')).toBe('not_entitled');
  });

  it('keeps a provider-pending payment pending without granting a right', async () => {
    const value = await pending();
    value.provider.setResult(value.checkout.token, { status: 'pending', conversationId: value.orderId, priceMinor: 1, currency: 'TRY' });
    expect((await value.service.retrieveAndApply(value.owner, value.orderId)).status).toBe('payment_pending');
    expect(await value.service.consume(value.owner, value.orderId, 'operation-a')).toBe('not_entitled');
  });
});
