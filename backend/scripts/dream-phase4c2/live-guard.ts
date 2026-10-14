/** Pure opt-in guard shared by the live runner and its no-call regression. */
export function phase4c2LiveOptInFailure(
  env: NodeJS.ProcessEnv,
): string | null {
  return env.PHASE4C2_LIVE === '1'
    ? null
    : 'PHASE4C2_LIVE=1 not set (explicit opt-in required)';
}
