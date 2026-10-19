/**
 * Direct /v1/ai/complete soulmate calls must use the same premium proof as
 * the durable worker. A missing guard fails closed only in locked envs so
 * existing development tests keep their fixture path.
 */
import type { AppConfig } from '../config.js';
import { ErrorCode, errorEnvelope } from '../errors.js';
import type { SoulmateEntitlementGuard } from './soulmate-entitlement-guard.js';

const GATED = new Set(['soulmate_draw', 'soulmate_interpretation']);

export function soulmateRouteNeedsPremium(operation: string): boolean {
  return GATED.has(operation);
}

export async function denySoulmateWithoutPremium(input: {
  operation: string;
  identity: string;
  config: AppConfig;
  guard: SoulmateEntitlementGuard | undefined;
}): Promise<{ status: number; body: ReturnType<typeof errorEnvelope> } | null> {
  if (!soulmateRouteNeedsPremium(input.operation)) return null;
  const locked =
    input.config.appEnv === 'production' || input.config.appEnv === 'staging';
  if (!input.guard) {
    if (!locked) return null;
    return { status: 503, body: errorEnvelope(ErrorCode.noConfiguration) };
  }
  if (await input.guard.isPremiumActive(input.identity)) return null;
  return { status: 403, body: errorEnvelope(ErrorCode.forbidden) };
}
