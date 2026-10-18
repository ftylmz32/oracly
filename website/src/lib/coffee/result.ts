export const COFFEE_RESULT_CONTRACT = 'm2_public_v1' as const;

export type CoffeeV3PublicResult = {
  coffeeResultContract: typeof COFFEE_RESULT_CONTRACT;
  visualObservation: '';
  overall: string;
  love: '';
  career: '';
  money: '';
  nearFuture: '';
  takeaway: '';
  symbols: [];
};

export type CoffeeResultDelivery = {
  operationId: string;
  resultId: string;
  readingType: 'coffee';
  persistedAt: string;
  result: CoffeeV3PublicResult;
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

export function parseCoffeeResultDelivery(
  value: unknown,
  expected: { operationId: string; resultId: string },
): CoffeeResultDelivery {
  if (!isRecord(value) || value.operationId !== expected.operationId || value.resultId !== expected.resultId) {
    throw new Error('invalid_result_identity');
  }
  if (value.readingType !== 'coffee' || typeof value.persistedAt !== 'string' || Number.isNaN(Date.parse(value.persistedAt))) {
    throw new Error('invalid_result_metadata');
  }
  const result = value.result;
  if (!isRecord(result) || result.coffeeResultContract !== COFFEE_RESULT_CONTRACT) throw new Error('invalid_result_contract');
  if (typeof result.overall !== 'string' || !result.overall.trim()) throw new Error('missing_result_content');
  for (const key of ['visualObservation', 'love', 'career', 'money', 'nearFuture', 'takeaway'] as const) {
    if (result[key] !== '') throw new Error('invalid_result_contract');
  }
  if (!Array.isArray(result.symbols) || result.symbols.length !== 0) throw new Error('invalid_result_contract');
  return value as CoffeeResultDelivery;
}

export function coffeeResultParagraphs(result: CoffeeV3PublicResult): string[] {
  return result.overall.trim().split(/\n\s*\n/u).map((paragraph) => paragraph.trim()).filter(Boolean);
}
