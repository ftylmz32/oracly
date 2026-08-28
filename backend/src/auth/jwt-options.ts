import type { JWTVerifyOptions } from 'jose';

export type JwtVerifyEnv = {
  jwtIssuer: string | null;
  jwtAudience: string | null;
};

export function jwtVerifyOptions(env: JwtVerifyEnv): JWTVerifyOptions {
  const options: JWTVerifyOptions = {
    clockTolerance: 30,
    requiredClaims: ['sub', 'exp'],
  };
  if (env.jwtIssuer) options.issuer = env.jwtIssuer;
  if (env.jwtAudience) options.audience = env.jwtAudience;
  return options;
}

export function subjectFromPayload(payload: { sub?: unknown }): string | null {
  if (typeof payload.sub !== 'string') return null;
  const sub = payload.sub.trim();
  if (!sub || looksLikeClaimUserIdInjection(sub)) return null;
  return sub;
}

function looksLikeClaimUserIdInjection(sub: string): boolean {
  return sub.startsWith('sk-');
}
