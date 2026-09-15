/**
 * Provisional, non-commercial acceleration costs.
 * Not business pricing. The client cannot choose these values.
 * A Premium modifier hook exists only as `none` and cannot discount.
 */
import type { ReadingType } from './operation-model.js';

export const GEM_COST_POLICY_KIND = 'provisional_non_commercial' as const;

export type GemCostModifier = {
  readonly kind: 'none';
};

export const noGemCostModifier: GemCostModifier = { kind: 'none' };

export type GemCostPolicy = {
  readonly kind: typeof GEM_COST_POLICY_KIND;
  cost(type: ReadingType): number;
};

export const PROVISIONAL_ACCELERATION_COST: Record<ReadingType, number> = {
  coffee: 10,
  palm: 15,
  soulmate: 20,
};

export function provisionalGemCostPolicy(
  overrides: Partial<Record<ReadingType, number>> = {},
): GemCostPolicy {
  const costs: Record<ReadingType, number> = {
    coffee: bounded(overrides.coffee ?? PROVISIONAL_ACCELERATION_COST.coffee),
    palm: bounded(overrides.palm ?? PROVISIONAL_ACCELERATION_COST.palm),
    soulmate: bounded(overrides.soulmate ?? PROVISIONAL_ACCELERATION_COST.soulmate),
  };
  return {
    kind: GEM_COST_POLICY_KIND,
    cost(type: ReadingType): number {
      return costs[type];
    },
  };
}

export function resolveAccelerationCost(
  type: ReadingType,
  policy: GemCostPolicy = provisionalGemCostPolicy(),
  modifier: GemCostModifier = noGemCostModifier,
): number {
  if (modifier.kind !== 'none') {
    throw new Error('unsupported_gem_cost_modifier');
  }
  return policy.cost(type);
}

function bounded(value: number): number {
  if (!Number.isInteger(value) || value < 1 || value > 100_000) {
    throw new Error('invalid_gem_cost');
  }
  return value;
}
