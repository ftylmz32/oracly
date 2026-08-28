import type { AppConfig } from '../config.js';
import {
  DevBypassAuthenticationService,
  FailClosedAuthenticationService,
  OpaqueBearerAuthenticationService,
} from './dev-auth.js';
import { Hs256AuthenticationService } from './jwt-hs256.js';
import { JwksAuthenticationService } from './jwt-jwks.js';
import type { AuthenticationService } from './types.js';

/** One instance per process — JWKS remote set must be reused. */
export function createAuthenticationService(
  config: AppConfig,
): AuthenticationService {
  switch (config.authMode) {
    case 'bypass':
      return new DevBypassAuthenticationService();
    case 'jwks':
      return JwksAuthenticationService.fromUrl(config.jwksUrl!, {
        jwtIssuer: config.jwtIssuer,
        jwtAudience: config.jwtAudience,
      });
    case 'hs256':
      return new Hs256AuthenticationService(
        new TextEncoder().encode(config.jwtSecret!),
        { jwtIssuer: config.jwtIssuer, jwtAudience: config.jwtAudience },
      );
    case 'opaque':
      return new OpaqueBearerAuthenticationService();
    case 'fail_closed':
      return new FailClosedAuthenticationService();
  }
}
