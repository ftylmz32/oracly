export const COFFEE_READING_PRODUCT_ID = 'oracly_coffee_single_v1' as const;

export type OrderStatus = 'created' | 'payment_pending' | 'payment_verified' | 'entitlement_granted' | 'entitlement_consumed' | 'failed' | 'refunded';
export type OrderEvent = { status: OrderStatus; atMs: number; reason?: string };
export type CoffeeOrder = {
  orderId: string; ownerUserId: string; productId: typeof COFFEE_READING_PRODUCT_ID;
  priceMinor: number; currency: 'TRY'; status: OrderStatus; checkoutToken?: string;
  providerPaymentId?: string; readingOperationId?: string; createdAtMs: number; updatedAtMs: number; events: OrderEvent[];
};
export type PaymentResult = { status: 'paid' | 'pending' | 'failed' | 'refunded'; conversationId: string; providerPaymentId?: string; priceMinor: number; currency: string; reason?: string };
