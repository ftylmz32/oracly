/**
 * Dream Phase 4C.2a — where a re-derived evidence document differs from its
 * frozen copy. Frozen files are only read; tests pin the exact drift the
 * 4C.2a gate calibration explains, so any other change still fails.
 */
export type Drift = { path: string; frozen: unknown; now: unknown };

export function jsonDrift(frozen: unknown, now: unknown, path = '$'): Drift[] {
  if (JSON.stringify(frozen) === JSON.stringify(now)) return [];
  if (frozen && now && typeof frozen === 'object' && typeof now === 'object') {
    const a = frozen as Record<string, unknown>;
    const b = now as Record<string, unknown>;
    return [...new Set([...Object.keys(a), ...Object.keys(b)])].flatMap((k) => jsonDrift(a[k], b[k], `${path}.${k}`));
  }
  return [{ path, frozen, now }];
}
