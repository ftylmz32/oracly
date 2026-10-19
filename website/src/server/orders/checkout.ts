import { randomUUID } from 'node:crypto';
import { COFFEE_READING_PRODUCT_ID } from '../../lib/orders/types';
import { IyzicoError, type IyzicoCheckoutClient } from './iyzico';
import type { IyzicoPaymentResult } from './iyzico';
import { validateBuyer } from './iyzico';
import type { CheckoutOrderStore, StoredCoffeeOrder } from './store';

export class CheckoutService {
  constructor(private readonly store: CheckoutOrderStore, private readonly provider: IyzicoCheckoutClient, private readonly now = () => Date.now(), private readonly attempt = () => `chk_${randomUUID()}`) {}
  async start(request: Request, order: StoredCoffeeOrder) {
    let body: unknown; try { body = await request.json(); } catch { throw new Error('invalid_request'); }
    const details = validateBuyer(body); if (!details) throw new Error('invalid_request');
    const reservation = await this.store.reserveCheckout({ orderId: order.orderId, ownerUserId: order.ownerUserId, attemptId: this.attempt(), nowMs: this.now() });
    if (reservation.outcome === 'existing') return { state: 'ready' as const, paymentPageUrl: reservation.order.checkoutPageUrl };
    if (reservation.outcome !== 'reserved') return { state: reservation.outcome as 'in_progress' | 'not_available' | 'not_found' };
    let initialized;
    try { initialized = await this.provider.initialize(reservation.order, details.buyer, details.billingAddress); }
    catch (error) {
      if (error instanceof IyzicoError && error.message === 'initialize_rejected') await this.store.failCheckoutReservation({ orderId: order.orderId, attemptId: reservation.order.checkoutAttemptId!, nowMs: this.now() });
      throw error;
    }
    const bound = await this.store.bindCheckout({ orderId: order.orderId, attemptId: reservation.order.checkoutAttemptId!, token: initialized.token, conversationId: initialized.conversationId, paymentPageUrl: initialized.paymentPageUrl, nowMs: this.now() });
    if (bound !== 'bound' && bound !== 'already_bound') throw new Error('checkout_binding_failed');
    return { state: 'sandbox_ready' as const, paymentPageUrl: initialized.paymentPageUrl };
  }
  async reconcile(token: string) {
    const order = await this.store.getByCheckoutToken(token); if (!order || order.checkoutToken !== token) throw new Error('checkout_not_found');
    const result = await this.provider.retrieve(token, order.orderId);
    verifyResult(order, result);
    if (result.status === 'failed' || result.status === 'refunded') {
      await this.store.recordCheckoutState({ orderId: order.orderId, checkoutToken: token, status: result.status, providerPaymentId: result.providerPaymentId, paymentTransactionId: result.paymentTransactionId, transactionStatus: result.transactionStatus, nowMs: this.now() });
      return { outcome: 'not_granted' as const, orderId: order.orderId };
    }
    if (result.status !== 'paid' || !result.providerPaymentId || !result.paymentTransactionId || result.fraudStatus !== 1 || result.transactionStatus !== 2) return { outcome: 'not_granted' as const, orderId: order.orderId };
    const outcome = await this.store.confirmCheckoutPayment({ orderId: order.orderId, checkoutToken: token, providerPaymentId: result.providerPaymentId, paymentTransactionId: result.paymentTransactionId, transactionStatus: result.transactionStatus, priceMinor: result.priceMinor, currency: 'TRY', nowMs: this.now() });
    return { outcome, orderId: order.orderId };
  }
}

export function verifyResult(order: StoredCoffeeOrder, result: IyzicoPaymentResult) {
  if (result.checkoutToken !== order.checkoutToken || result.conversationId !== order.orderId || result.basketId !== order.orderId || result.currency !== order.currency || result.priceMinor !== order.priceMinor || result.paidPriceMinor !== order.priceMinor || result.itemProductId !== COFFEE_READING_PRODUCT_ID || result.itemPriceMinor !== order.priceMinor) throw new Error('payment_mismatch');
}
