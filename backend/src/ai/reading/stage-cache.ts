/** Parent-op stage cache: observer/writer/repair without re-calling providers. */

type StageEntry = {
  at: number;
  payload: unknown;
  repairUsed?: boolean;
};

const TTL_MS = 15 * 60_000;
const MAX = 400;

export function createReadingStageStore() {
  const map = new Map<string, StageEntry>();

  function key(identity: string, parent: string, stage: string): string {
    return `${identity}|${parent}|${stage}`;
  }

  function sweep(now: number) {
    if (map.size <= MAX) return;
    for (const [k, v] of map) {
      if (now - v.at > TTL_MS) map.delete(k);
    }
  }

  return {
    get<T>(identity: string, parent: string, stage: string): T | null {
      const hit = map.get(key(identity, parent, stage));
      if (!hit) return null;
      if (Date.now() - hit.at > TTL_MS) {
        map.delete(key(identity, parent, stage));
        return null;
      }
      return hit.payload as T;
    },

    set(identity: string, parent: string, stage: string, payload: unknown): void {
      const now = Date.now();
      map.set(key(identity, parent, stage), { at: now, payload });
      sweep(now);
    },

    markRepairUsed(identity: string, parent: string): void {
      map.set(key(identity, parent, 'repair_flag'), {
        at: Date.now(),
        payload: true,
        repairUsed: true,
      });
    },

    repairUsed(identity: string, parent: string): boolean {
      return this.get<boolean>(identity, parent, 'repair_flag') === true;
    },

    clear(): void {
      map.clear();
    },
  };
}

export type ReadingStageStore = ReturnType<typeof createReadingStageStore>;

/** Process-wide singleton for Coffee/Palm stages (single Cloud Run instance). */
export const readingStageStore = createReadingStageStore();
