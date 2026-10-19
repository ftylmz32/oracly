export type PaymentView = 'pending' | 'paid' | 'failed' | 'refunded';

export function paymentView(status: string, providerPaymentStatus?: string): PaymentView {
  if (providerPaymentStatus === 'refunded' || status === 'refunded') return 'refunded';
  if (providerPaymentStatus === 'failed' || status === 'failed') return 'failed';
  if (providerPaymentStatus === 'paid' && (status === 'entitlement_granted' || status === 'entitlement_consumed')) return 'paid';
  return 'pending';
}
