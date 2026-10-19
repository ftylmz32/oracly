import { createHmac } from 'node:crypto';
import { describe, expect, it, vi } from 'vitest';
import { COFFEE_READING_PRODUCT_ID } from '../../lib/orders/types';
import { IyzicoCheckoutClient } from './iyzico';

const config = { environment: 'sandbox' as const, apiKey: 'sandbox-key', secretKey: 'sandbox-secret', callbackUrl: 'https://example.test/api/payments/iyzico/callback', baseUrl: 'https://sandbox-api.iyzipay.com' };

describe('iyzico Checkout Form adapter', () => {
  it('creates the official IYZWSv2 signature and takes commercial fields only from the order', async () => {
    const http = vi.fn(async (_url: string | URL | Request, init?: RequestInit) => {
      const body = JSON.parse(String(init?.body));
      expect(body).toMatchObject({ conversationId: 'ord_12345678', basketId: 'ord_12345678', price: '72.50', paidPrice: '72.50', currency: 'TRY', basketItems: [{ id: COFFEE_READING_PRODUCT_ID, price: '72.50', itemType: 'VIRTUAL' }] });
      const random = new Headers(init?.headers).get('x-iyzi-rnd')!;
      const signature = createHmac('sha256', config.secretKey).update(random + '/payment/iyzipos/checkoutform/initialize/auth/ecom' + String(init?.body)).digest('hex');
      expect(Buffer.from(new Headers(init?.headers).get('authorization')!.slice(8), 'base64').toString()).toBe(`apiKey:${config.apiKey}&randomKey:${random}&signature:${signature}`);
      const token = 'checkout-token-123';
      const responseSignature = createHmac('sha256', config.secretKey).update(`${body.conversationId}:${token}`).digest('hex');
      return Response.json({ status: 'success', conversationId: body.conversationId, token, paymentPageUrl: 'https://sandbox-cpp.iyzipay.com?token=checkout-token-123', signature: responseSignature });
    });
    const client = new IyzicoCheckoutClient(config, http as typeof fetch, () => 'fixed-random');
    const result = await client.initialize({ orderId: 'ord_12345678', ownerUserId: 'uid-a', priceMinor: 7250, currency: 'TRY', productId: COFFEE_READING_PRODUCT_ID }, buyer(), billing());
    expect(result.token).toBe('checkout-token-123'); expect(http).toHaveBeenCalledOnce();
  });

  it('retrieves and normalizes a complete paid result without making the callback token authoritative', async () => {
    const value = { status: 'success', paymentStatus: 'SUCCESS', conversationId: 'ord_12345678', token: 'checkout-token-123', basketId: 'ord_12345678', paymentId: 'pay-1', price: 72.5, paidPrice: 72.5, currency: 'TRY', fraudStatus: 1, itemTransactions: [{ itemId: COFFEE_READING_PRODUCT_ID, price: 72.5, paymentTransactionId: 'txn-1', transactionStatus: 2 }] };
    const signature = createHmac('sha256', config.secretKey).update('SUCCESS:pay-1:TRY:ord_12345678:ord_12345678:72.5:72.5:checkout-token-123').digest('hex');
    const http = vi.fn(async () => Response.json({ ...value, signature }));
    const result = await new IyzicoCheckoutClient(config, http as typeof fetch).retrieve('checkout-token-123', 'ord_12345678');
    expect(result).toMatchObject({ status: 'paid', providerPaymentId: 'pay-1', paymentTransactionId: 'txn-1', transactionStatus: 2, priceMinor: 7250, paidPriceMinor: 7250, fraudStatus: 1, itemProductId: COFFEE_READING_PRODUCT_ID });
  });

  it('validates HPP Signature V3 in constant time and rejects tampering, legacy shape, and wrong event type', () => {
    const client = new IyzicoCheckoutClient(config);
    const payload = { iyziEventType: 'CHECKOUT_FORM_AUTH', iyziPaymentId: 12345, token: 'token-1', paymentConversationId: 'ord_12345678', status: 'SUCCESS' };
    const raw = JSON.stringify(payload);
    const signature = createHmac('sha256', config.secretKey).update(config.secretKey + payload.iyziEventType + payload.iyziPaymentId + payload.token + payload.paymentConversationId + payload.status).digest('hex');
    expect(client.verifyWebhook(raw, signature)).toMatchObject({ orderId: 'ord_12345678', checkoutToken: 'token-1' });
    expect(() => client.verifyWebhook(raw.replace('SUCCESS', 'FAILURE'), signature)).toThrow('invalid_signature');
    expect(() => client.verifyWebhook(raw, 'bad')).toThrow('invalid_signature');
    expect(() => client.verifyWebhook(JSON.stringify({ ...payload, iyziEventType: 'PAYMENT_API' }), signature)).toThrow('invalid_webhook');
  });

  it('rejects a successful provider response with a missing or changed response signature', async () => {
    const http = vi.fn(async () => Response.json({ status: 'success', conversationId: 'ord_12345678', token: 'checkout-token-123', paymentPageUrl: 'https://sandbox-cpp.iyzipay.com?token=checkout-token-123', signature: '0'.repeat(64) }));
    const client = new IyzicoCheckoutClient(config, http as typeof fetch);
    await expect(client.initialize({ orderId: 'ord_12345678', ownerUserId: 'uid-a', priceMinor: 7250, currency: 'TRY', productId: COFFEE_READING_PRODUCT_ID }, buyer(), billing())).rejects.toThrow('invalid_response_signature');
  });
});

function buyer() { return { name: 'Test', surname: 'User', identityNumber: '11111111111', email: 'test@example.test', gsmNumber: '+905000000000', registrationAddress: 'Sandbox address', city: 'Istanbul', country: 'Turkey' }; }
function billing() { return { address: 'Sandbox address', contactName: 'Test User', city: 'Istanbul', country: 'Turkey' }; }
