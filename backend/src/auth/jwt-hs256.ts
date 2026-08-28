import { jwtVerify } from 'jose';
import type { AuthenticationService, AuthResult } from './types.js';
import {
  identityKeyFromSubject,
  looksLikeOpenAiKey,
  parseBearer,
} from './identity.js';
import { jwtVerifyOptions, subjectFromPayload, type JwtVerifyEnv } from './jwt-options.js';

export class Hs256AuthenticationService implements AuthenticationService {
  constructor(
    private readonly secret: Uint8Array,
    private readonly env: JwtVerifyEnv,
  ) {}

  async authenticate(authorizationHeader: unknown): Promise<AuthResult> {
    const token = parseBearer(authorizationHeader);
    if (!token || looksLikeOpenAiKey(token)) return { ok: false };
    try {
      const { payload } = await jwtVerify(
        token,
        this.secret,
        { ...jwtVerifyOptions(this.env), algorithms: ['HS256'] },
      );
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
