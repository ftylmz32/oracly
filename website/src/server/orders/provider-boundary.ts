import type { PaymentResult } from '../../lib/orders/types';
import type { PersistentOrderStore } from './store';

export interface ServerPaymentProvider {
  verifyWebhookSignature(rawBody: string, signature: string): Promise<{ orderId: string; checkoutToken: string }>;
  retrieveCheckoutResult(checkoutToken: string): Promise<PaymentResult>;
}

export class VerifiedPaymentBoundary {
  constructor(private readonly provider: ServerPaymentProvider, private readonly store: PersistentOrderStore, private readonly now = () => Date.now()) {}
  async handle(rawBody: string, signature: string | null): Promise<'granted' | 'already_applied'> {
    if (!signature) throw new Error('webhook_signature_required');
    const notification = await this.provider.verifyWebhookSignature(rawBody, signature);
    const result = await this.provider.retrieveCheckoutResult(notification.checkoutToken);
    if (result.status !== 'paid' || result.conversationId !== notification.orderId || !result.providerPaymentId || result.currency !== 'TRY') throw new Error('payment_not_verified');
    const outcome = await this.store.confirmVerifiedPayment({ orderId: notification.orderId, providerPaymentId: result.providerPaymentId, priceMinor: result.priceMinor, currency: 'TRY', nowMs: this.now() });
    if (outcome !== 'granted' && outcome !== 'already_applied') throw new Error(`payment_${outcome}`);
    return outcome;
  }
}
