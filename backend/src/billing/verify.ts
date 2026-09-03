/** Orchestrates platform routing for POST /v1/billing/verify. */

import type { AppConfig } from '../config.js';
import { createAppleStoreVerifier } from './apple-store.js';
import { isKnownProduct } from './catalog.js';
import { createGooglePlayVerifier } from './google-play.js';
import {
  billingResult,
  type BillingProviders,
  type BillingVerifyRequest,
  type BillingVerifyResult,
  type StoreVerifier,
} from './types.js';

export function createBillingProviders(
  config: AppConfig,
  overrides: BillingProviders = {},
): { google: StoreVerifier; apple: StoreVerifier } {
  return {
    google:
      overrides.google ??
      createGooglePlayVerifier({
        packageName: config.playPackageName,
        credentials: config.googlePlayCredentials,
      }),
    apple:
      overrides.apple ??
      createAppleStoreVerifier({
        bundleId: config.appleBundleId,
        appAppleId: config.appleAppAppleId,
        issuerId: config.appleIssuerId,
        keyId: config.appleKeyId,
        privateKey: config.applePrivateKey,
        rootCertificates: config.appleRootCertificates,
        preferEnvironment: config.applePreferEnvironment,
      }),
  };
}

export async function verifyPurchase(
  request: BillingVerifyRequest,
  providers: { google: StoreVerifier; apple: StoreVerifier },
): Promise<BillingVerifyResult> {
  if (!isKnownProduct(request.productId)) {
    return billingResult('unverified', 'unknown_product');
  }
  if (request.platform === 'android') {
    if (!providers.google.configured) {
      return billingResult('unverified', 'provider_not_configured');
    }
    return providers.google.verify(request);
  }
  if (!providers.apple.configured) {
    return billingResult('unverified', 'provider_not_configured');
  }
  return providers.apple.verify(request);
}