import type { AuthenticationService, AuthResult } from './types.js';
import {
  identityKeyFromIp,
  identityKeyFromOpaqueToken,
  looksLikeOpenAiKey,
  parseBearer,
} from './identity.js';

/** Development-only. Never used when APP_ENV is production or staging. */
export class DevBypassAuthenticationService implements AuthenticationService {
  async authenticate(
    _authorizationHeader: unknown,
    requestIp = 'unknown',
  ): Promise<AuthResult> {
    return {
      ok: true,
      identity: {
        subject: 'dev-bypass',
        identityKey: identityKeyFromIp(requestIp || 'unknown'),
      },
    };
  }
}

/**
 * Development-only opaque Bearer. Not signature-verified.
 * Exists so local Flutter mock tokens can hit a local proxy.
 * Forbidden in production/staging.
 */
export class OpaqueBearerAuthenticationService implements AuthenticationService {
  async authenticate(authorizationHeader: unknown): Promise<AuthResult> {
    const token = parseBearer(authorizationHeader);
    if (!token || looksLikeOpenAiKey(token)) return { ok: false };
    return {
      ok: true,
      identity: {
        subject: 'opaque-dev',
        identityKey: identityKeyFromOpaqueToken(token),
      },
    };
  }
}

/** Production/staging without JWT/JWKS config — every request fails closed. */
export class FailClosedAuthenticationService implements AuthenticationService {
  async authenticate(_authorizationHeader: unknown): Promise<AuthResult> {
    return { ok: false };
  }
}
