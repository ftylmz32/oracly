import { createRemoteJWKSet, jwtVerify, type JWTVerifyGetKey } from 'jose';
import type { AuthenticationService, AuthResult } from './types.js';
import {
  identityKeyFromSubject,
  looksLikeOpenAiKey,
  parseBearer,
} from './identity.js';
import { jwtVerifyOptions, subjectFromPayload, type JwtVerifyEnv } from './jwt-options.js';

export class JwksAuthenticationService implements AuthenticationService {
  constructor(
    private readonly getKey: JWTVerifyGetKey,
    private readonly env: JwtVerifyEnv,
  ) {}

  static fromUrl(jwksUrl: string, env: JwtVerifyEnv): JwksAuthenticationService {
    return new JwksAuthenticationService(
      createRemoteJWKSet(new URL(jwksUrl)),
      env,
    );
  }

  async authenticate(authorizationHeader: unknown): Promise<AuthResult> {
    const token = parseBearer(authorizationHeader);
    if (!token || looksLikeOpenAiKey(token)) return { ok: false };
    try {
      const { payload } = await jwtVerify(token, this.getKey, {
        ...jwtVerifyOptions(this.env),
        algorithms: ['RS256', 'ES256'],
      });
      const subject = subjectFromPayload(payload);
      if (!subject) return { ok: false };
      return {
        ok: true,
        identity: {
          subject,
          identityKey: identityKeyFromSubject(subject),
        },
      };
    } catch {
      return { ok: false };
    }
  }
}
