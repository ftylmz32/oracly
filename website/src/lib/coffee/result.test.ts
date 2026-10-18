import { describe, expect, it } from 'vitest';
import { coffeeResultParagraphs, parseCoffeeResultDelivery } from './result';

const valid = {
  operationId: 'op-1', resultId: 'result-1', readingType: 'coffee', persistedAt: '2026-10-18T12:00:00.000Z',
  result: { coffeeResultContract: 'm2_public_v1', visualObservation: '', overall: 'İlk paragraf.\n\nİkinci paragraf.', love: '', career: '', money: '', nearFuture: '', takeaway: '', symbols: [] },
};

describe('Coffee V3 public result contract', () => {
  it('accepts only the expected identity and renders overall verbatim as paragraphs', () => {
    const delivery = parseCoffeeResultDelivery(valid, { operationId: 'op-1', resultId: 'result-1' });
    expect(coffeeResultParagraphs(delivery.result)).toEqual(['İlk paragraf.', 'İkinci paragraf.']);
  });

  it.each([
    [{ ...valid, operationId: 'someone-else' }, 'invalid_result_identity'],
    [{ ...valid, result: { ...valid.result, coffeeResultContract: 'other' } }, 'invalid_result_contract'],
    [{ ...valid, result: { ...valid.result, overall: '   ' } }, 'missing_result_content'],
    [{ ...valid, result: { ...valid.result, symbols: ['invented'] } }, 'invalid_result_contract'],
  ])('rejects invalid, foreign, or incomplete payloads', (payload, code) => {
    expect(() => parseCoffeeResultDelivery(payload, { operationId: 'op-1', resultId: 'result-1' })).toThrow(code);
  });
});
