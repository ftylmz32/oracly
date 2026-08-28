/** Firebase App Check token verification for AI routes. */
import { createRemoteJWKSet, jwtVerify, type JWTVerifyGetKey } from 'jose';
import type { AppConfig } from '../config.js';

export type AppCheckOutcome =
  | { ok: true }
  | { ok: false; reason: 'missing' | 'invalid' | 'unavailable' };

export interface AppCheckVerifier {
  readonly mode: 'verify' | 'bypass' | 'fail_closed';
  verify(tokenHeader: unknown): Promise<AppCheckOutcome>;
}

const APP_CHECK_JWKS_URL = 'https://firebaseappcheck.googleapis.com/v1/jwks';

export function readAppCheckHeader(
  headers: Record<string, unknown> | undefined,
): string | undefined {
  if (!headers) return undefined;
  const raw = headers['x-firebase-appcheck'] ?? headers['X-Firebase-AppCheck'];
  if (typeof raw !== 'string') return undefined;
  const trimmed = raw.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

export class BypassAppCheckVerifier implements AppCheckVerifier {
  readonly mode = 'bypass' as const;
  async verify(): Promise<AppCheckOutcome> {
    return { ok: true };
  }
}

export class FailClosedAppCheckVerifier implements AppCheckVerifier {
  readonly mode = 'fail_closed' as const;
  async verify(): Promise<AppCheckOutcome> {
    return { ok: false, reason: 'unavailable' };
  }
}

/** Test double — accepts one fixed token string. */
export class StaticAppCheckVerifier implements AppCheckVerifier {
  readonly mode = 'verify' as const;
  constructor(private readonly acceptToken: string) {}
  async verify(tokenHeader: unknown): Promise<AppCheckOutcome> {
    const token =
      typeof tokenHeader === 'string'
        ? tokenHeader.trim()
        : readAppCheckHeader(tokenHeader as Record<string, unknown> | undefined);
    if (!token) return { ok: false, reason: 'missing' };
    if (token !== this.acceptToken) return { ok: false, reason: 'invalid' };
    return { ok: true };
  }
}

export class FirebaseAppCheckVerifier implements AppCheckVerifier {
  readonly mode = 'verify' as const;

  constructor(
    private readonly getKey: JWTVerifyGetKey,
    private readonly projectId: string,
    private readonly projectNumber: string | null,
  ) {}

  static fromProject(
    projectId: string,
    projectNumber: string | null = null,
  ): FirebaseAppCheckVerifier {
    return new FirebaseAppCheckVerifier(
      createRemoteJWKSet(new URL(APP_CHECK_JWKS_URL)),
      projectId,
      projectNumber,
    );
  }

  async verify(tokenHeader: unknown): Promise<AppCheckOutcome> {
    const token =
      typeof tokenHeader === 'string'
        ? tokenHeader.trim()
        : readAppCheckHeader(tokenHeader as Record<string, unknown> | undefined);
    if (!token) return { ok: false, reason: 'missing' };
    try {
      const audience = ['projects/' + this.projectId];
      if (this.projectNumber) {
        audience.push('projects/' + this.projectNumber);
      }
      const { payload } = await jwtVerify(token, this.getKey, {
        audience,
        algorithms: ['RS256', 'ES256'],
      });
      const iss = typeof payload.iss === 'string' ? payload.iss : '';
      if (!iss.startsWith('https://firebaseappcheck.googleapis.com/')) {
        return { ok: false, reason: 'invalid' };
      }
      return { ok: true };
    } catch {
      return { ok: false, reason: 'invalid' };
    }
  }
}

export function createAppCheckVerifier(config: AppConfig): AppCheckVerifier {
  if (!config.appCheckRequired) {
    return new BypassAppCheckVerifier();
  }
  if (!config.firebaseProjectId) {
    return new FailClosedAppCheckVerifier();
  }
  try {
    return FirebaseAppCheckVerifier.fromProject(
      config.firebaseProjectId,
      config.firebaseProjectNumber,
    );
  } catch {
    return new FailClosedAppCheckVerifier();
  }
}
