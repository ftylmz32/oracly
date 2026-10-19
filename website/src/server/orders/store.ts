import { createHash } from 'node:crypto';
import type { Firestore } from 'firebase-admin/firestore';
import { COFFEE_READING_PRODUCT_ID, type OrderEvent, type OrderStatus } from '../../lib/orders/types';

const ORDERS = 'webCoffeeOrders';
const REQUESTS = 'webCoffeeOrderRequests';
const PAYMENTS = 'webCoffeePaymentBindings';

export type StoredCoffeeOrder = {
  orderId: string; ownerUserId: string; productId: typeof COFFEE_READING_PRODUCT_ID;
  catalogVersion: string; priceMinor: number; currency: 'TRY'; status: OrderStatus;
  checkoutAttemptId?: string; checkoutToken?: string; checkoutConversationId?: string; checkoutPageUrl?: string;
  providerPaymentId?: string; readingOperationId?: string; createdAtMs: number; updatedAtMs: number; events: OrderEvent[];
};

export type CheckoutReservation =
  | { outcome: 'reserved'; order: StoredCoffeeOrder }
  | { outcome: 'existing'; order: StoredCoffeeOrder }
  | { outcome: 'in_progress'; order: StoredCoffeeOrder }
  | { outcome: 'not_found' | 'not_available' };

export interface PersistentOrderStore {
  createIdempotent(input: { ownerUserId: string; idempotencyKey: string; orderId: string; catalogVersion: string; priceMinor: number; currency: 'TRY'; nowMs: number }): Promise<{ order: StoredCoffeeOrder; created: boolean }>;
  getOwned(orderId: string, ownerUserId: string): Promise<StoredCoffeeOrder | null>;
  confirmVerifiedPayment(input: { orderId: string; providerPaymentId: string; priceMinor: number; currency: 'TRY'; nowMs: number }): Promise<'granted' | 'already_applied' | 'payment_reused' | 'mismatch'>;
  consumeEntitlement(input: { orderId: string; ownerUserId: string; operationId: string; nowMs: number }): Promise<'consumed' | 'already_consumed' | 'wrong_owner' | 'not_entitled'>;
}
export interface CheckoutOrderStore extends PersistentOrderStore {
  reserveCheckout(input: { orderId: string; ownerUserId: string; attemptId: string; nowMs: number }): Promise<CheckoutReservation>;
  bindCheckout(input: { orderId: string; attemptId: string; token: string; conversationId: string; paymentPageUrl: string; nowMs: number }): Promise<'bound' | 'already_bound' | 'token_reused' | 'mismatch'>;
  failCheckoutReservation(input: { orderId: string; attemptId: string; nowMs: number }): Promise<'failed' | 'mismatch'>;
  getByCheckoutToken(token: string): Promise<StoredCoffeeOrder | null>;
  confirmCheckoutPayment(input: { orderId: string; checkoutToken: string; providerPaymentId: string; priceMinor: number; currency: 'TRY'; nowMs: number }): Promise<'granted' | 'already_applied' | 'payment_reused' | 'mismatch'>;
  recordCheckoutState(input: { orderId: string; checkoutToken: string; status: 'failed' | 'refunded'; nowMs: number }): Promise<'recorded' | 'already_consumed' | 'mismatch'>;
}

export class FirestoreOrderStore implements PersistentOrderStore {
  constructor(private readonly firestore: Firestore) {}

  async createIdempotent(input: { ownerUserId: string; idempotencyKey: string; orderId: string; catalogVersion: string; priceMinor: number; currency: 'TRY'; nowMs: number }) {
    const requestRef = this.firestore.collection(REQUESTS).doc(digest(`${input.ownerUserId}\0${input.idempotencyKey}`));
    const newOrderRef = this.firestore.collection(ORDERS).doc(input.orderId);
    return this.firestore.runTransaction(async (tx) => {
      const request = await tx.get(requestRef);
      if (request.exists) {
        const existingId = request.data()?.orderId;
        if (typeof existingId !== 'string') throw new Error('order_storage_corrupt');
        const existing = parseOrder((await tx.get(this.firestore.collection(ORDERS).doc(existingId))).data());
        if (!existing || existing.ownerUserId !== input.ownerUserId) throw new Error('order_storage_corrupt');
        return { order: existing, created: false };
      }
      const order: StoredCoffeeOrder = {
        orderId: input.orderId, ownerUserId: input.ownerUserId, productId: COFFEE_READING_PRODUCT_ID,
        catalogVersion: input.catalogVersion, priceMinor: input.priceMinor, currency: input.currency,
        status: 'created', createdAtMs: input.nowMs, updatedAtMs: input.nowMs,
        events: [{ status: 'created', atMs: input.nowMs }],
      };
      tx.create(newOrderRef, order);
      tx.create(requestRef, { ownerUserId: input.ownerUserId, orderId: input.orderId, createdAtMs: input.nowMs });
      return { order, created: true };
    });
  }

  async getOwned(orderId: string, ownerUserId: string): Promise<StoredCoffeeOrder | null> {
    const order = parseOrder((await this.firestore.collection(ORDERS).doc(orderId).get()).data());
    return order?.ownerUserId === ownerUserId ? order : null;
  }

  async reserveCheckout(input: { orderId: string; ownerUserId: string; attemptId: string; nowMs: number }): Promise<CheckoutReservation> {
    const ref = this.firestore.collection(ORDERS).doc(input.orderId);
    return this.firestore.runTransaction(async (tx) => {
      const order = parseOrder((await tx.get(ref)).data());
      if (!order || order.ownerUserId !== input.ownerUserId) return { outcome: 'not_found' as const };
      if (order.checkoutToken) return { outcome: 'existing' as const, order };
      if (order.status === 'payment_pending') return { outcome: 'in_progress' as const, order };
      if (order.status !== 'created' && order.status !== 'failed') return { outcome: 'not_available' as const };
      const reserved = { ...order, checkoutAttemptId: input.attemptId, checkoutConversationId: input.orderId, status: 'payment_pending' as const, updatedAtMs: input.nowMs, events: [...order.events, { status: 'payment_pending' as const, atMs: input.nowMs }] };
      tx.update(ref, reserved);
      return { outcome: 'reserved' as const, order: reserved };
    });
  }

  async bindCheckout(input: { orderId: string; attemptId: string; token: string; conversationId: string; paymentPageUrl: string; nowMs: number }) {
    const orderRef = this.firestore.collection(ORDERS).doc(input.orderId);
    const tokenRef = this.firestore.collection('webCoffeeCheckoutTokens').doc(digest(input.token));
    return this.firestore.runTransaction(async (tx) => {
      const [orderSnap, tokenSnap] = await Promise.all([tx.get(orderRef), tx.get(tokenRef)]);
      const order = parseOrder(orderSnap.data());
      if (!order || order.checkoutAttemptId !== input.attemptId || input.conversationId !== input.orderId) return 'mismatch' as const;
      if (order.checkoutToken === input.token) return 'already_bound' as const;
      if (order.checkoutToken || tokenSnap.exists) return 'token_reused' as const;
      tx.create(tokenRef, { orderId: input.orderId, createdAtMs: input.nowMs });
      tx.update(orderRef, { checkoutToken: input.token, checkoutConversationId: input.conversationId, checkoutPageUrl: input.paymentPageUrl, updatedAtMs: input.nowMs });
      return 'bound' as const;
    });
  }

  async failCheckoutReservation(input: { orderId: string; attemptId: string; nowMs: number }) {
    const ref = this.firestore.collection(ORDERS).doc(input.orderId);
    return this.firestore.runTransaction(async (tx) => {
      const order = parseOrder((await tx.get(ref)).data());
      if (!order || order.checkoutAttemptId !== input.attemptId || order.checkoutToken || order.status !== 'payment_pending') return 'mismatch' as const;
      tx.update(ref, { status: 'failed', updatedAtMs: input.nowMs, events: [...order.events, { status: 'failed', atMs: input.nowMs, reason: 'checkout_initialize_rejected' }] });
      return 'failed' as const;
    });
  }

  async getByCheckoutToken(token: string): Promise<StoredCoffeeOrder | null> {
    const binding = await this.firestore.collection('webCoffeeCheckoutTokens').doc(digest(token)).get();
    const orderId = binding.data()?.orderId;
    if (typeof orderId !== 'string') return null;
    return parseOrder((await this.firestore.collection(ORDERS).doc(orderId).get()).data());
  }

  async recordCheckoutState(input: { orderId: string; checkoutToken: string; status: 'failed' | 'refunded'; nowMs: number }) {
    const ref = this.firestore.collection(ORDERS).doc(input.orderId);
    return this.firestore.runTransaction(async (tx) => {
      const order = parseOrder((await tx.get(ref)).data());
      if (!order || order.checkoutToken !== input.checkoutToken) return 'mismatch' as const;
      if (order.status === 'entitlement_consumed') return 'already_consumed' as const;
      if (order.status === input.status) return 'recorded' as const;
      tx.update(ref, { status: input.status, updatedAtMs: input.nowMs, events: [...order.events, { status: input.status, atMs: input.nowMs }] });
      return 'recorded' as const;
    });
  }

  async confirmVerifiedPayment(input: { orderId: string; providerPaymentId: string; priceMinor: number; currency: 'TRY'; nowMs: number }) {
    return this.confirmPayment(input, false);
  }

  async confirmCheckoutPayment(input: { orderId: string; checkoutToken: string; providerPaymentId: string; priceMinor: number; currency: 'TRY'; nowMs: number }) {
    return this.confirmPayment(input, true);
  }

  private async confirmPayment(input: { orderId: string; checkoutToken?: string; providerPaymentId: string; priceMinor: number; currency: 'TRY'; nowMs: number }, requireCheckoutToken: boolean) {
    const orderRef = this.firestore.collection(ORDERS).doc(input.orderId);
    const paymentRef = this.firestore.collection(PAYMENTS).doc(digest(input.providerPaymentId));
    return this.firestore.runTransaction(async (tx) => {
      const [orderSnap, paymentSnap] = await Promise.all([tx.get(orderRef), tx.get(paymentRef)]);
      const order = parseOrder(orderSnap.data());
      if (!order || (requireCheckoutToken && (!input.checkoutToken || order.checkoutToken !== input.checkoutToken)) || order.priceMinor !== input.priceMinor || order.currency !== input.currency) return 'mismatch' as const;
      if (order.providerPaymentId === input.providerPaymentId && (order.status === 'entitlement_granted' || order.status === 'entitlement_consumed')) return 'already_applied' as const;
      if (paymentSnap.exists && paymentSnap.data()?.orderId !== input.orderId) return 'payment_reused' as const;
      if (order.status !== 'payment_pending' && order.status !== 'created') return 'mismatch' as const;
      const events = [...order.events, { status: 'payment_verified' as const, atMs: input.nowMs }, { status: 'entitlement_granted' as const, atMs: input.nowMs }];
      tx.create(paymentRef, { orderId: input.orderId, createdAtMs: input.nowMs });
      tx.update(orderRef, { providerPaymentId: input.providerPaymentId, status: 'entitlement_granted', updatedAtMs: input.nowMs, events });
      return 'granted' as const;
    });
  }

  async consumeEntitlement(input: { orderId: string; ownerUserId: string; operationId: string; nowMs: number }) {
    const orderRef = this.firestore.collection(ORDERS).doc(input.orderId);
    return this.firestore.runTransaction(async (tx) => {
      const order = parseOrder((await tx.get(orderRef)).data());
      if (!order || order.ownerUserId !== input.ownerUserId) return 'wrong_owner' as const;
      if (order.status === 'entitlement_consumed') return order.readingOperationId === input.operationId ? 'already_consumed' as const : 'not_entitled' as const;
      if (order.status !== 'entitlement_granted') return 'not_entitled' as const;
      tx.update(orderRef, { status: 'entitlement_consumed', readingOperationId: input.operationId, updatedAtMs: input.nowMs, events: [...order.events, { status: 'entitlement_consumed', atMs: input.nowMs }] });
      return 'consumed' as const;
    });
  }
}

function digest(value: string): string { return createHash('sha256').update(value).digest('hex'); }
function parseOrder(value: FirebaseFirestore.DocumentData | undefined): StoredCoffeeOrder | null {
  const statuses: OrderStatus[] = ['created', 'payment_pending', 'payment_verified', 'entitlement_granted', 'entitlement_consumed', 'failed', 'refunded'];
  if (!value || typeof value.orderId !== 'string' || typeof value.ownerUserId !== 'string' || value.productId !== COFFEE_READING_PRODUCT_ID || typeof value.catalogVersion !== 'string' || typeof value.priceMinor !== 'number' || value.currency !== 'TRY' || !statuses.includes(value.status as OrderStatus) || typeof value.createdAtMs !== 'number' || typeof value.updatedAtMs !== 'number' || !Array.isArray(value.events)) return null;
  return value as StoredCoffeeOrder;
}
