/**
 * Live consumable verifier. Admitted only when that platform's credentials
 * exist in the environment. Admission is not a sandbox or console pass.
 */
import { GoogleAuth, type JWTInput } from 'google-auth-library';
import type { AppConfig } from '../config.js';
import { decodeSignedAppleTransaction, type AppleStoreConfig } from '../billing/apple-store.js';
import { readingCommerceProduct, type ReadingCommerceProductId } from './reading-commerce-catalog.js';
import { interpretAppleConsumable } from './reading-consumable-apple.js';
import { consumePlayPurchase, readPlayConsumable } from './reading-consumable-play.js';
import { listPlayVoidedPurchases } from './reading-voided-sync.js';
import {
  createClosedConsumableVerifier,
  type ConsumableVerifier,
  type ConsumableVerifyRequest,
  type ConsumableVerifyResult,
} from './reading-commerce-verify.js';

const PLAY_SCOPE = 'https://www.googleapis.com/auth/androidpublisher';

export function createReadingConsumableVerifier(
  config: AppConfig,
  fetchImpl: typeof fetch = fetch,
): ConsumableVerifier {
  const playReady = Boolean(
    config.playPackageName && (config.googlePlayCredentials || config.googlePlayUseAdc),
  );
  const appleReady = Boolean(
    config.appleBundleId && config.appleIssuerId && config.appleKeyId
      && config.applePrivateKey && config.appleRootCertificates.length > 0,
  );
  if (!playReady && !appleReady) return createClosedConsumableVerifier();
  const playToken = playReady ? playAccessToken(config) : null;
  return {
    admitted: true,
    androidAdmitted: playReady,
    iosAdmitted: appleReady,
    async verify(request) {
      if (!readingCommerceProduct(request.productId)) {
        return { ok: false, reason: 'invalid' };
      }
      if (request.platform === 'android') {
        if (!playReady || !playToken) return { ok: false, reason: 'provider_unavailable' };
        try {
          const decision = await readPlayConsumable({
            fetchImpl,
            packageName: config.playPackageName,
            productId: request.productId,
            purchaseToken: request.purchaseToken,
            accessToken: await playToken(),
          });
          if (!decision.ok) return {
            ok: false,
            reason: decision.reason,
            transactionId: 'transactionId' in decision ? decision.transactionId : undefined,
          };
          return {
            ok: true,
            transactionId: decision.transactionId,
            licenseTest: decision.licenseTest,
            accountTag: decision.accountTag,
          };
        } catch {
          return { ok: false, reason: 'provider_unavailable' };
        }
      }
      if (!appleReady || !config.appleBundleId) return { ok: false, reason: 'provider_unavailable' };
      try {
        const decoded = await decodeSignedAppleTransaction(appleConfig(config), request.purchaseToken);
        if (!decoded.ok) return { ok: false, reason: 'unverified' };
        const decision = interpretAppleConsumable(
          {
            bundleId: decoded.payload.bundleId,
            productId: decoded.payload.productId,
            transactionId: decoded.payload.transactionId,
            revocationDate: decoded.payload.revocationDate,
            type: decoded.payload.type == null ? null : String(decoded.payload.type),
            appAccountToken: decoded.payload.appAccountToken ?? null,
          },
          {
            bundleId: config.appleBundleId,
            productId: request.productId,
            environment: decoded.environment,
          },
        );
        return decision.ok
          ? {
              ok: true,
              transactionId: decision.transactionId,
              environment: decision.environment,
              // App Review and TestFlight buy in Sandbox; the QA server
              // treats it as the counterpart of a Play license test.
              licenseTest: decision.environment === 'Sandbox',
              accountTag: decision.accountTag,
            }
          : { ok: false, reason: decision.reason, transactionId: decision.transactionId };
      } catch {
        return { ok: false, reason: 'provider_unavailable' };
      }
    },
    async listVoided() {
      if (!playReady || !playToken) return null;
      try {
        return await listPlayVoidedPurchases({
          fetchImpl,
          packageName: config.playPackageName,
          accessToken: await playToken(),
        });
      } catch {
        return null;
      }
    },
    async consume(request) {
      if (request.platform !== 'android' || !playReady || !playToken) return 'skipped';
      try {
        return await consumePlayPurchase({
          fetchImpl,
          packageName: config.playPackageName,
          productId: request.productId,
          purchaseToken: request.purchaseToken,
          accessToken: await playToken(),
        });
      } catch {
        return 'pending';
      }
    },
  };
}

function playAccessToken(config: AppConfig): () => Promise<string> {
  let auth: GoogleAuth | null = null;
  return async () => {
    auth ??= new GoogleAuth({
      credentials: (config.googlePlayCredentials ?? undefined) as JWTInput | undefined,
      scopes: [PLAY_SCOPE],
    });
    const client = await auth.getClient();
    const token = await client.getAccessToken();
    if (!token.token) throw new Error('missing_access_token');
    return token.token;
  };
}

function appleConfig(config: AppConfig): AppleStoreConfig {
  return {
    bundleId: config.appleBundleId,
    appAppleId: config.appleAppAppleId,
    issuerId: config.appleIssuerId,
    keyId: config.appleKeyId,
    privateKey: config.applePrivateKey,
    rootCertificates: config.appleRootCertificates,
    preferEnvironment: config.applePreferEnvironment,
  };
}

export type { ConsumableVerifyRequest, ConsumableVerifyResult, ReadingCommerceProductId };
