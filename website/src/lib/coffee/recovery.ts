import type { CoffeeV3Slot } from './contracts';

export type CoffeeRecoveryRecord = {
  version: 1;
  sourceRequestId: string;
  operationId?: string;
  stagedSlots: CoffeeV3Slot[];
  createdAtMs: number;
};

export interface CoffeeRecoveryStore {
  load(): CoffeeRecoveryRecord | null;
  save(record: CoffeeRecoveryRecord): void;
  clear(): void;
}

const KEY = 'oracly.web.coffee-v3.active.v1';
const MAX_AGE_MS = 24 * 60 * 60 * 1000;

export class BrowserCoffeeRecoveryStore implements CoffeeRecoveryStore {
  load(): CoffeeRecoveryRecord | null {
    if (typeof window === 'undefined') return null;
    try {
      const parsed = JSON.parse(window.localStorage.getItem(KEY) ?? 'null') as Partial<CoffeeRecoveryRecord> | null;
      if (!parsed || parsed.version !== 1 || typeof parsed.sourceRequestId !== 'string' || !Array.isArray(parsed.stagedSlots) ||
          typeof parsed.createdAtMs !== 'number' || Date.now() - parsed.createdAtMs > MAX_AGE_MS) {
        window.localStorage.removeItem(KEY);
        return null;
      }
      return parsed as CoffeeRecoveryRecord;
    } catch {
      window.localStorage.removeItem(KEY);
      return null;
    }
  }

  save(record: CoffeeRecoveryRecord): void {
    if (typeof window !== 'undefined') window.localStorage.setItem(KEY, JSON.stringify(record));
  }

  clear(): void {
    if (typeof window !== 'undefined') window.localStorage.removeItem(KEY);
  }
}
