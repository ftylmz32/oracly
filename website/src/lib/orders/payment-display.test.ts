import { describe, expect, it } from 'vitest';
import { paymentView } from './payment-display';

describe('payment result presentation', () => {
  it.each([
    ['payment_pending', undefined, 'pending'], ['entitlement_granted', 'paid', 'paid'], ['entitlement_consumed', 'paid', 'paid'],
    ['failed', 'failed', 'failed'], ['refunded', 'refunded', 'refunded'], ['entitlement_consumed', 'refunded', 'refunded'],
  ])('maps %s/%s to %s', (status, provider, expected) => expect(paymentView(status, provider)).toBe(expected));
  it('never infers success from entitlement status without verified provider state', () => expect(paymentView('entitlement_granted')).toBe('pending'));
});
