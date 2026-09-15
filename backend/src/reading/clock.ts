/**
 * Authoritative timestamps come only from this clock.
 * Clients never supply createdAt, readyAt, or elapsed time.
 */
export type ServerClock = {
  now(): Date;
};

export function systemClock(): ServerClock {
  return {
    now: () => new Date(),
  };
}

export function toEpochMs(value: Date): number {
  const ms = value.getTime();
  if (!Number.isFinite(ms)) {
    throw new Error('invalid_server_clock');
  }
  return ms;
}

export function toUtcIso(ms: number): string {
  return new Date(ms).toISOString();
}
