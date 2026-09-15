import { createHash } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import type { AppCheckVerifier } from '../auth/app-check.js';
import { createAppCheckVerifier } from '../auth/app-check.js';
import { createAuthenticationService } from '../auth/create-auth.js';
import type { AppConfig } from '../config.js';
import { ErrorCode, errorEnvelope, successEnvelope } from '../errors.js';
import { requireAppCheck } from '../middleware/app-check.js';
import { requireAuth } from '../middleware/auth.js';
import { GoogleAdMobSsvVerifier, parseAdMobSsv, type AdMobSsvVerifier } from '../ads/admob-ssv.js';
import { RewardedIdentityClaims } from '../ads/rewarded-identity-claim.js';
import type { ServerClock } from '../reading/clock.js';
import { systemClock, toEpochMs } from '../reading/clock.js';
import type { GemLedger } from '../reading/gem-ledger.js';
import { PROVISIONAL_NON_COMMERCIAL_REWARDED_AD_GEMS } from '../reading/gem-wallet-policy.js';

export type RewardedAdRouteOptions = { appCheck?: AppCheckVerifier; ledger?: GemLedger; clock?: ServerClock; claims?: RewardedIdentityClaims; verifier?: AdMobSsvVerifier };

export async function registerRewardedAdRoutes(app: FastifyInstance, config: AppConfig, options: RewardedAdRouteOptions = {}): Promise<void> {
  const auth = requireAuth(createAuthenticationService(config));
  const appCheck = requireAppCheck(options.appCheck ?? createAppCheckVerifier(config));
  const clock = options.clock ?? systemClock();
  const claims = options.claims ?? new RewardedIdentityClaims(config.rewardedAdClaimSecret ?? '');
  const verifier = options.verifier ?? new GoogleAdMobSsvVerifier();
  app.post('/v1/gems/rewarded-ad/claim', { preHandler: [auth, appCheck] }, async (request, reply) => {
    const owner = request.identityKey;
    if (!owner) return reply.code(401).send(errorEnvelope(ErrorCode.unauthorized));
    if (!claims.configured) return reply.code(503).send(errorEnvelope(ErrorCode.noConfiguration));
    return reply.code(200).send(successEnvelope(claims.issue(owner, toEpochMs(clock.now()))));
  });
  // Google calls this endpoint: Firebase auth/App Check do not apply; SSV does.
  app.get('/v1/gems/rewarded-ad/ssv', async (request, reply) => {
    if (!options.ledger) return reply.code(503).send('unavailable');
    const parsed = parseAdMobSsv(request.raw.url ?? '');
    if (!parsed || !(await verifier.verify(parsed))) return reply.code(400).send('invalid');
    const claim = claims.verify(parsed.customData, toEpochMs(clock.now()));
    if (!claim) return reply.code(400).send('invalid');
    const correlation = createHash('sha256').update(parsed.transactionId).digest('hex');
    try {
      await options.ledger.credit({ ownerUserId: claim.owner, amount: PROVISIONAL_NON_COMMERCIAL_REWARDED_AD_GEMS, idempotencyKey: `admob:${correlation.slice(0, 48)}`, reason: 'rewarded_ad' });
      return reply.code(200).send('ok');
    } catch { return reply.code(503).send('unavailable'); }
  });
}
