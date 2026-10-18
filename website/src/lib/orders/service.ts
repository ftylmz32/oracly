import type { CheckoutProvider, CheckoutSession } from './provider';
import type { ConsumeOutcome, OrderRepository } from './repository';
import { COFFEE_READING_PRODUCT_ID, type CoffeeOrder, type PaymentResult } from './types';

// Executable test catalog only. Production price must live in the durable backend catalog.
const TEST_ONLY_CATALOG = { [COFFEE_READING_PRODUCT_ID]: { priceMinor: 14900, currency: 'TRY' as const } };
export class CoffeeOrderService {
  constructor(private readonly repository: OrderRepository, private readonly provider: CheckoutProvider, private readonly now = () => Date.now()) {}
  async create(ownerUserId: string, input: { requestId: string; productId: typeof COFFEE_READING_PRODUCT_ID; price?: unknown; paid?: unknown }): Promise<CoffeeOrder> {
    if (!ownerUserId.trim()) throw new Error('unauthorized');
    if (input.productId !== COFFEE_READING_PRODUCT_ID || !/^[A-Za-z0-9_-]{8,80}$/.test(input.requestId)) throw new Error('invalid_order_request');
    if (input.price !== undefined || input.paid !== undefined) throw new Error('client_authority_rejected');
    const product = TEST_ONLY_CATALOG[input.productId]; const now = this.now();
    const order: CoffeeOrder = { orderId: input.requestId, ownerUserId, productId: input.productId, ...product, status: 'created', createdAtMs: now, updatedAtMs: now, events: [{ status: 'created', atMs: now }] };
    const outcome = await this.repository.create(order);
    if (outcome === 'duplicate') { const existing = await this.repository.get(order.orderId); if (!existing || existing.ownerUserId !== ownerUserId) throw new Error('order_conflict'); return existing; }
    return order;
  }
  async beginCheckout(ownerUserId: string, orderId: string): Promise<CheckoutSession> {
    const order = await this.owned(orderId, ownerUserId); if (order.checkoutToken) throw new Error('checkout_already_initialized');
    const session = await this.provider.initialize(order); if (!await this.repository.attachCheckout(orderId, ownerUserId, session.token, this.now())) throw new Error('checkout_state_conflict'); return session;
  }
  async retrieveAndApply(ownerUserId: string, orderId: string): Promise<CoffeeOrder> {
    const order = await this.owned(orderId, ownerUserId); if (!order.checkoutToken) throw new Error('checkout_not_initialized'); return this.apply(orderId, await this.provider.retrieve(order.checkoutToken));
  }
  async applyWebhook(orderId: string, rawBody: string, signature: string | null): Promise<CoffeeOrder> { return this.apply(orderId, await this.provider.verifyWebhook(rawBody, signature)); }
  async consume(ownerUserId: string, orderId: string, operationId: string): Promise<ConsumeOutcome> { if (!ownerUserId.trim() || !operationId.trim()) throw new Error('invalid_consume_request'); return this.repository.consume(orderId, ownerUserId, operationId, this.now()); }
  private async apply(orderId: string, result: PaymentResult): Promise<CoffeeOrder> {
    if (result.status === 'paid') { const outcome = await this.repository.confirmAndGrant(orderId, result, this.now()); if (outcome !== 'granted' && outcome !== 'already_applied') throw new Error(`payment_${outcome}`); }
    else if (result.status === 'failed' || result.status === 'refunded') await this.repository.markProviderState(orderId, result, this.now());
    const order = await this.repository.get(orderId); if (!order) throw new Error('order_not_found'); return order;
  }
  private async owned(orderId: string, ownerUserId: string): Promise<CoffeeOrder> { const order = await this.repository.get(orderId); if (!order || order.ownerUserId !== ownerUserId) throw new Error('order_not_found'); return order; }
}
