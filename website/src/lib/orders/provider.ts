import type { CoffeeOrder, PaymentResult } from './types';

export type CheckoutSession = { token: string; paymentPageUrl: string };
export interface CheckoutProvider {
  initialize(order: Readonly<CoffeeOrder>): Promise<CheckoutSession>;
  retrieve(token: string): Promise<PaymentResult>;
  verifyWebhook(rawBody: string, signature: string | null): Promise<PaymentResult>;
}

export class FakeCheckoutProvider implements CheckoutProvider {
  private readonly results = new Map<string, PaymentResult>();
  constructor(private readonly webhookSecret = 'test-only-signature') {}
  async initialize(order: Readonly<CoffeeOrder>): Promise<CheckoutSession> {
    return { token: `fake_${order.orderId}`, paymentPageUrl: `https://sandbox.invalid/checkout/${order.orderId}` };
  }
  setResult(token: string, result: PaymentResult): void { this.results.set(token, result); }
  async retrieve(token: string): Promise<PaymentResult> {
    const result = this.results.get(token); if (!result) throw new Error('provider_result_unavailable'); return result;
  }
  async verifyWebhook(rawBody: string, signature: string | null): Promise<PaymentResult> {
    if (signature !== this.webhookSecret) throw new Error('invalid_webhook_signature');
    const parsed = JSON.parse(rawBody) as { token?: unknown };
    if (typeof parsed.token !== 'string') throw new Error('invalid_webhook_payload');
    return this.retrieve(parsed.token);
  }
}
