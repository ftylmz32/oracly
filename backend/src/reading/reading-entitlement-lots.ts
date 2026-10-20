import type { ReadingCommerceFeature } from './reading-commerce-catalog.js';

export const ENTITLEMENT_LOTS = 'readingEntitlementLots';

export type EntitlementLot = {
  purchaseId: string;
  feature: ReadingCommerceFeature;
  remaining: number;
  units: number;
  refunded: boolean;
};

export function readLots(data: Record<string, unknown> | undefined): EntitlementLot[] {
  const items = data?.items;
  if (!Array.isArray(items)) return [];
  return items.flatMap((raw) => {
    if (!raw || typeof raw !== 'object') return [];
    const item = raw as Record<string, unknown>;
    if (typeof item.purchaseId !== 'string') return [];
    if (item.feature !== 'coffee' && item.feature !== 'palm') return [];
    const remaining = count(item.remaining);
    const units = count(item.units);
    if (units < 1) return [];
    return [{
      purchaseId: item.purchaseId,
      feature: item.feature,
      remaining,
      units,
      refunded: item.refunded === true,
    }];
  });
}

/** Assigns one unused unit from the oldest matching purchase. */
export function takeLot(
  lots: EntitlementLot[],
  feature: ReadingCommerceFeature,
): { lots: EntitlementLot[]; purchaseId: string | null } {
  const index = lots.findIndex((lot) => lot.feature === feature && !lot.refunded && lot.remaining > 0);
  if (index < 0) return { lots, purchaseId: null };
  const next = lots.map((lot, i) => i === index ? { ...lot, remaining: lot.remaining - 1 } : lot);
  return { lots: next, purchaseId: lots[index].purchaseId };
}

/**
 * Puts one unit back on the purchase a failed create consumed.
 * A store-refunded purchase does not receive it.
 */
export function giveLot(
  lots: EntitlementLot[],
  purchaseId: string,
): { lots: EntitlementLot[]; refunded: boolean } {
  const index = lots.findIndex((lot) => lot.purchaseId === purchaseId);
  if (index < 0) return { lots, refunded: false };
  const lot = lots[index];
  if (lot.refunded) return { lots, refunded: true };
  if (lot.remaining >= lot.units) return { lots, refunded: false };
  const next = lots.map((item, i) => i === index ? { ...item, remaining: item.remaining + 1 } : item);
  return { lots: next, refunded: false };
}

export function appendLot(lots: EntitlementLot[], lot: EntitlementLot): EntitlementLot[] {
  if (lots.some((item) => item.purchaseId === lot.purchaseId)) return lots;
  return [...lots, lot];
}

export function protectedRemaining(lots: EntitlementLot[], feature: ReadingCommerceFeature): number {
  return lots
    .filter((lot) => lot.feature === feature && !lot.refunded)
    .reduce((sum, lot) => sum + lot.remaining, 0);
}

export function refundLot(
  lots: EntitlementLot[],
  purchaseId: string,
): { lots: EntitlementLot[]; drop: number | null } {
  const index = lots.findIndex((lot) => lot.purchaseId === purchaseId);
  if (index < 0) return { lots, drop: null };
  const drop = lots[index].refunded ? 0 : lots[index].remaining;
  const next = lots.map((lot, i) => i === index ? { ...lot, remaining: 0, refunded: true } : lot);
  return { lots: next, drop };
}

function count(value: unknown): number {
  return typeof value === 'number' && Number.isInteger(value) && value > 0 ? value : 0;
}
