import type { CoffeeOrder, PaymentResult } from './types';

export type ConfirmOutcome = 'granted' | 'already_applied' | 'payment_reused' | 'mismatch' | 'not_found';
export type ConsumeOutcome = 'consumed' | 'already_consumed' | 'wrong_owner' | 'not_entitled' | 'not_found';
export interface OrderRepository {
  create(order: CoffeeOrder): Promise<'created' | 'duplicate'>;
  get(orderId: string): Promise<CoffeeOrder | null>;
  attachCheckout(orderId: string, ownerUserId: string, token: string, nowMs: number): Promise<boolean>;
  confirmAndGrant(orderId: string, result: PaymentResult, nowMs: number): Promise<ConfirmOutcome>;
  markProviderState(orderId: string, result: PaymentResult, nowMs: number): Promise<void>;
  consume(orderId: string, ownerUserId: string, operationId: string, nowMs: number): Promise<ConsumeOutcome>;
}

export class InMemoryOrderRepository implements OrderRepository {
  private readonly orders = new Map<string, CoffeeOrder>();
  private readonly paymentOwners = new Map<string, string>();
  private queue: Promise<unknown> = Promise.resolve();
  async create(order: CoffeeOrder): Promise<'created' | 'duplicate'> { return this.atomic(() => { if (this.orders.has(order.orderId)) return 'duplicate'; this.orders.set(order.orderId, structuredClone(order)); return 'created'; }); }
  async get(orderId: string): Promise<CoffeeOrder | null> { const order = this.orders.get(orderId); return order ? structuredClone(order) : null; }
  async attachCheckout(orderId: string, ownerUserId: string, token: string, nowMs: number): Promise<boolean> {
    return this.atomic(() => { const order = this.orders.get(orderId); if (!order || order.ownerUserId !== ownerUserId || (order.checkoutToken && order.checkoutToken !== token) || (order.status !== 'created' && order.status !== 'payment_pending')) return false; order.checkoutToken = token; order.status = 'payment_pending'; order.updatedAtMs = nowMs; if (order.events.at(-1)?.status !== 'payment_pending') order.events.push({ status: 'payment_pending', atMs: nowMs }); return true; });
  }
  async confirmAndGrant(orderId: string, result: PaymentResult, nowMs: number): Promise<ConfirmOutcome> {
    return this.atomic(() => { const order = this.orders.get(orderId); if (!order) return 'not_found'; if (result.conversationId !== order.orderId || result.priceMinor !== order.priceMinor || result.currency !== order.currency || !result.providerPaymentId) return 'mismatch'; if (order.providerPaymentId === result.providerPaymentId && (order.status === 'entitlement_granted' || order.status === 'entitlement_consumed')) return 'already_applied'; const paymentOwner = this.paymentOwners.get(result.providerPaymentId); if (paymentOwner && paymentOwner !== orderId) return 'payment_reused'; if (order.status !== 'payment_pending' && order.status !== 'created') return 'mismatch'; this.paymentOwners.set(result.providerPaymentId, orderId); order.providerPaymentId = result.providerPaymentId; order.status = 'payment_verified'; order.events.push({ status: 'payment_verified', atMs: nowMs }); order.status = 'entitlement_granted'; order.updatedAtMs = nowMs; order.events.push({ status: 'entitlement_granted', atMs: nowMs }); return 'granted'; });
  }
  async markProviderState(orderId: string, result: PaymentResult, nowMs: number): Promise<void> {
    await this.atomic(() => { const order = this.orders.get(orderId); if (!order || result.conversationId !== orderId) return; const next = result.status === 'refunded' ? 'refunded' : result.status === 'failed' ? 'failed' : null; if (!next || order.status === next) return; order.status = next; order.updatedAtMs = nowMs; order.events.push({ status: next, atMs: nowMs, reason: result.reason }); });
  }
  async consume(orderId: string, ownerUserId: string, operationId: string, nowMs: number): Promise<ConsumeOutcome> {
    return this.atomic(() => { const order = this.orders.get(orderId); if (!order) return 'not_found'; if (order.ownerUserId !== ownerUserId) return 'wrong_owner'; if (order.status === 'entitlement_consumed') return order.readingOperationId === operationId ? 'already_consumed' : 'not_entitled'; if (order.status !== 'entitlement_granted') return 'not_entitled'; order.status = 'entitlement_consumed'; order.readingOperationId = operationId; order.updatedAtMs = nowMs; order.events.push({ status: 'entitlement_consumed', atMs: nowMs }); return 'consumed'; });
  }
  private atomic<T>(work: () => T): Promise<T> { const run = this.queue.then(work, work); this.queue = run.then(() => undefined, () => undefined); return run; }
}
