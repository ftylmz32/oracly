/**
 * OIDC check for billing task endpoints (Cloud Tasks retries and the Cloud
 * Scheduler sweep). Accepts only a Google-signed ID token for the billing
 * audience, issued to the dedicated billing task service account. The
 * reading task identity is not accepted, and an unconfigured billing
 * identity refuses everything.
 */
import { OAuth2Client } from 'google-auth-library';
import type { FastifyRequest } from 'fastify';
import type { AppConfig } from '../config.js';

type OidcVerifier = Pick<OAuth2Client, 'verifyIdToken'>;

export function verifyBillingTask(
  config: AppConfig,
  oauth: OidcVerifier = new OAuth2Client(),
) {
  return async (request: FastifyRequest): Promise<boolean> => {
    const audience = config.billingAckAudience;
    const serviceAccount = config.billingAckServiceAccount;
    if (!audience || !serviceAccount) return false;
    const raw = request.headers.authorization;
    const token =
      typeof raw === 'string' && raw.startsWith('Bearer ')
        ? raw.slice('Bearer '.length)
        : null;
    if (!token || token.split('.').length !== 3) return false;
    try {
      const ticket = await oauth.verifyIdToken({ idToken: token, audience });
      const payload = ticket.getPayload();
      return Boolean(
        payload &&
          (payload.iss === 'https://accounts.google.com' ||
            payload.iss === 'accounts.google.com') &&
          payload.email === serviceAccount &&
          payload.email_verified === true,
      );
    } catch {
      return false;
    }
  };
}
