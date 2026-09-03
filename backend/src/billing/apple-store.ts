/** Apple App Store Server API + SignedDataVerifier entitlement checks. */

import { readFileSync, existsSync } from 'node:fs';
import {
  AppStoreServerAPIClient,
  Environment,
  ReceiptUtility,
  SignedDataVerifier,
  Status,
  type JWSTransactionDecodedPayload,
} from '@apple/app-store-server-library';
import { isKnownProduct, productKind } from './catalog.js';
import {
  billingResult,
  type BillingVerifyRequest,
  type BillingVerifyResult,
  type StoreVerifier,
} from './types.js';

export type AppleStoreConfig = {
  bundleId: string | null;
  appAppleId: number | null;
  issuerId: string | null;
  keyId: string | null;
  privateKey: string | null;
  rootCertificates: Buffer[];
  /** Prefer Production; Sandbox fallback on transaction-not-found. */
  preferEnvironment: 'Production' | 'Sandbox';
  /** Test seams */
  verifyJws?: (
    jws: string,
    environment: Environment,
  ) => Promise<JWSTransactionDecodedPayload>;
  getSubscriptionStatuses?: (
    originalTransactionId: string,
    environment: Environment,
  ) => Promise<AppleSubscriptionSnapshot>;
  getTransactionInfo?: (
    transactionId: string,
    environment: Environment,
  ) => Promise<JWSTransactionDecodedPayload | null>;
  extractReceiptTransactionId?: (receipt: string) => string | null;
};

export type AppleSubscriptionSnapshot = {
  /** Only cryptographically verified rows belong here. */
  statuses: Array<{
    status: number;
    productId: string;
    expiresDate?: number;
    revocationDate?: number;
    /** Verified JWS purchaseDate — preferred chronology. */
    purchaseDate?: number;
    /** Verified JWS signedDate — secondary chronology. */
    signedDate?: number;
  }>;
};

const TXN_NOT_FOUND = new Set([4040010, 4040005]);

export function createAppleStoreVerifier(
  config: AppleStoreConfig,
): StoreVerifier {
  return {
    get configured() {
      return Boolean(
        config.bundleId &&
          config.issuerId &&
          config.keyId &&
          config.privateKey &&
          config.rootCertificates.length > 0,
      );
    },
    async verify(request: BillingVerifyRequest): Promise<BillingVerifyResult> {
      if (!this.configured) {
        return billingResult('unverified', 'provider_not_configured');
      }
      if (!isKnownProduct(request.productId)) {
        return billingResult('unverified', 'unknown_product');
      }
      try {
        if (looksLikeJws(request.purchaseToken)) {
          return await verifySk2(config, request);
        }
        return await verifySk1Receipt(config, request);
      } catch {
        return billingResult('error', 'provider_unavailable');
      }
    },
  };
}

async function verifySk2(
  config: AppleStoreConfig,
  request: BillingVerifyRequest,
): Promise<BillingVerifyResult> {
  const primary = toEnv(config.preferEnvironment);
  const decoded = await decodeJwsWithFallback(config, request.purchaseToken, primary);
  if (decoded.status !== 'ok') return decoded.result;
  return evaluateDecoded(config, request, decoded.payload, decoded.environment);
}

async function verifySk1Receipt(
  config: AppleStoreConfig,
  request: BillingVerifyRequest,
): Promise<BillingVerifyResult> {
  const extract =
    config.extractReceiptTransactionId ??
    ((receipt: string) => {
      try {
        return new ReceiptUtility().extractTransactionIdFromAppReceipt(receipt);
      } catch {
        return null;
      }
    });
  const transactionId =
    extract(request.purchaseToken) ?? request.transactionId ?? null;
  if (!transactionId) {
    return billingResult('unverified', 'receipt_no_transaction_id');
  }
  const primary = toEnv(config.preferEnvironment);
  const info = await loadTransactionWithFallback(config, transactionId, primary);
  if (info.status !== 'ok') return info.result;
  return evaluateDecoded(config, request, info.payload, info.environment);
}

async function evaluateDecoded(
  config: AppleStoreConfig,
  request: BillingVerifyRequest,
  payload: JWSTransactionDecodedPayload,
  environment: Environment,
): Promise<BillingVerifyResult> {
  if (payload.bundleId && payload.bundleId !== config.bundleId) {
    return billingResult('unverified', 'bundle_mismatch');
  }
  const ownedProduct = payload.productId;
  if (!ownedProduct || ownedProduct !== request.productId) {
    return billingResult('unverified', 'product_mismatch');
  }
  if (!isKnownProduct(ownedProduct)) {
    return billingResult('unverified', 'unknown_product');
  }
  if (payload.revocationDate != null) {
    return billingResult('inactive', 'revoked');
  }

  const kind = productKind(ownedProduct)!;
  if (kind === 'lifetime') {
    return billingResult('active', 'lifetime_owned');
  }

  const originalId =
    payload.originalTransactionId ?? payload.transactionId ?? null;
  if (!originalId) {
    return billingResult('unverified', 'missing_transaction_id');
  }

  const statuses = await loadStatusesWithFallback(config, originalId, environment);
  if (statuses.status !== 'ok') return statuses.result;

  const selected = selectVerifiedAppleStatus(
    statuses.snapshot.statuses,
    request.productId,
  );
  if (selected.kind === 'none') {
    return billingResult('unverified', 'no_verified_matching_status');
  }
  if (selected.kind === 'ambiguous') {
    return billingResult('unverified', 'ambiguous_subscription_chronology');
  }
  const match = selected.row;
  if (match.revocationDate != null || match.status === Status.REVOKED) {
    return billingResult('inactive', 'revoked');
  }
  return mapAppleStatus(match.status, match.expiresDate);
}

function mapAppleStatus(
  status: number,
  expiresDate?: number,
): BillingVerifyResult {
  const now = Date.now();
  const futureExpiry =
    typeof expiresDate === 'number' &&
    Number.isFinite(expiresDate) &&
    expiresDate > now;

  switch (status) {
    case Status.ACTIVE:
      if (expiresDate == null || !Number.isFinite(expiresDate)) {
        return billingResult('unverified', 'missing_expiry');
      }
      return futureExpiry
        ? billingResult('active', 'subscription_active')
        : billingResult('expired', 'subscription_past_expiry');
    case Status.BILLING_GRACE_PERIOD:
      return billingResult('active', 'grace_period');
    case Status.BILLING_RETRY:
      // Retry alone is not entitlement; require proven future expiry.
      if (expiresDate == null || !Number.isFinite(expiresDate)) {
        return billingResult('unverified', 'billing_retry_missing_expiry');
      }
      return futureExpiry
        ? billingResult('active', 'billing_retry_entitled')
        : billingResult('pending', 'billing_retry');
    case Status.EXPIRED:
      return billingResult('expired', 'subscription_expired');
    case Status.REVOKED:
      return billingResult('inactive', 'revoked');
    default:
      return billingResult('unverified', 'unknown_subscription_status');
  }
}

type VerifiedAppleStatus = AppleSubscriptionSnapshot['statuses'][number];

type AppleStatusSelection =
  | { kind: 'row'; row: VerifiedAppleStatus }
  | { kind: 'none' }
  | { kind: 'ambiguous' };

/**
 * Current authoritative matching row by verified chronology.
 * Never picks historically "best" entitlement over a newer end-state.
 */
function selectVerifiedAppleStatus(
  statuses: VerifiedAppleStatus[],
  productId: string,
): AppleStatusSelection {
  const matching = statuses.filter((s) => s.productId === productId);
  if (matching.length === 0) return { kind: 'none' };
  if (matching.length === 1) return { kind: 'row', row: matching[0] };

  const dated = matching.map((row) => ({
    row,
    t: chronologyMs(row),
  }));
  // Multiple candidates without a total authoritative order → fail closed.
  if (dated.some((d) => d.t == null)) {
    return { kind: 'ambiguous' };
  }
  dated.sort((a, b) => (b.t as number) - (a.t as number));
  const newest = dated[0];
  const tied = dated.filter((d) => d.t === newest.t);
  if (tied.length > 1) {
    const sameOutcome = tied.every(
      (d) =>
        d.row.status === newest.row.status &&
        (d.row.revocationDate != null) === (newest.row.revocationDate != null),
    );
    if (!sameOutcome) return { kind: 'ambiguous' };
  }
  return { kind: 'row', row: newest.row };
}

/** Prefer purchaseDate, then signedDate, then expiresDate. */
function chronologyMs(row: VerifiedAppleStatus): number | null {
  if (typeof row.purchaseDate === 'number' && Number.isFinite(row.purchaseDate)) {
    return row.purchaseDate;
  }
  if (typeof row.signedDate === 'number' && Number.isFinite(row.signedDate)) {
    return row.signedDate;
  }
  if (typeof row.expiresDate === 'number' && Number.isFinite(row.expiresDate)) {
    return row.expiresDate;
  }
  return null;
}

async function decodeJwsWithFallback(
  config: AppleStoreConfig,
  jws: string,
  primary: Environment,
): Promise<
  | { status: 'ok'; payload: JWSTransactionDecodedPayload; environment: Environment }
  | { status: 'fail'; result: BillingVerifyResult }
> {
  const order =
    primary === Environment.PRODUCTION
      ? [Environment.PRODUCTION, Environment.SANDBOX]
      : [Environment.SANDBOX, Environment.PRODUCTION];
  let last: BillingVerifyResult = billingResult('unverified', 'jws_invalid');
  for (const environment of order) {
    try {
      const payload = await decodeJws(config, jws, environment);
      return { status: 'ok', payload, environment };
    } catch (error) {
      last = mapVerifyError(error);
      if (last.reason === 'jws_invalid' || last.reason === 'bundle_mismatch') {
        // try next environment for env mismatch; signature failures stay fail-closed
        if (last.reason === 'jws_invalid' && order.indexOf(environment) === 0) {
          continue;
        }
        if (isEnvMismatch(error)) continue;
        return { status: 'fail', result: last };
      }
      if (isEnvMismatch(error)) continue;
      return { status: 'fail', result: last };
    }
  }
  return { status: 'fail', result: last };
}

async function decodeJws(
  config: AppleStoreConfig,
  jws: string,
  environment: Environment,
): Promise<JWSTransactionDecodedPayload> {
  if (config.verifyJws) return config.verifyJws(jws, environment);
  if (environment === Environment.PRODUCTION && config.appAppleId == null) {
    throw Object.assign(new Error('missing_app_apple_id'), {
      appleStatus: 'MISSING_APP_APPLE_ID',
    });
  }
  const verifier = new SignedDataVerifier(
    config.rootCertificates,
    true,
    environment,
    config.bundleId!,
    config.appAppleId ?? undefined,
  );
  return verifier.verifyAndDecodeTransaction(jws);
}

async function loadStatusesWithFallback(
  config: AppleStoreConfig,
  originalTransactionId: string,
  primary: Environment,
): Promise<
  | { status: 'ok'; snapshot: AppleSubscriptionSnapshot }
  | { status: 'fail'; result: BillingVerifyResult }
> {
  const order =
    primary === Environment.PRODUCTION
      ? [Environment.PRODUCTION, Environment.SANDBOX]
      : [Environment.SANDBOX, Environment.PRODUCTION];
  let last: BillingVerifyResult = billingResult('error', 'provider_unavailable');
  for (const environment of order) {
    try {
      const snapshot = await getStatuses(config, originalTransactionId, environment);
      return { status: 'ok', snapshot };
    } catch (error) {
      if (isTxnNotFound(error) && environment === order[0]) {
        last = billingResult('unverified', 'transaction_not_found');
        continue;
      }
      last = billingResult('error', 'provider_unavailable');
      if (isTxnNotFound(error)) continue;
      return { status: 'fail', result: last };
    }
  }
  return { status: 'fail', result: last };
}

async function loadTransactionWithFallback(
  config: AppleStoreConfig,
  transactionId: string,
  primary: Environment,
): Promise<
  | { status: 'ok'; payload: JWSTransactionDecodedPayload; environment: Environment }
  | { status: 'fail'; result: BillingVerifyResult }
> {
  const order =
    primary === Environment.PRODUCTION
      ? [Environment.PRODUCTION, Environment.SANDBOX]
      : [Environment.SANDBOX, Environment.PRODUCTION];
  let last: BillingVerifyResult = billingResult('unverified', 'transaction_not_found');
  for (const environment of order) {
    try {
      const payload = await getTxn(config, transactionId, environment);
      if (!payload) {
        last = billingResult('unverified', 'transaction_not_found');
        continue;
      }
      return { status: 'ok', payload, environment };
    } catch (error) {
      if (isTxnNotFound(error) && environment === order[0]) {
        last = billingResult('unverified', 'transaction_not_found');
        continue;
      }
      last = billingResult('error', 'provider_unavailable');
      if (isTxnNotFound(error)) continue;
      return { status: 'fail', result: last };
    }
  }
  return { status: 'fail', result: last };
}

async function getStatuses(
  config: AppleStoreConfig,
  originalTransactionId: string,
  environment: Environment,
): Promise<AppleSubscriptionSnapshot> {
  if (config.getSubscriptionStatuses) {
    // Test/prod seam must only supply already-verified rows (productId required).
    return config.getSubscriptionStatuses(originalTransactionId, environment);
  }
  const client = apiClient(config, environment);
  const response = await client.getAllSubscriptionStatuses(originalTransactionId);
  const statuses: AppleSubscriptionSnapshot['statuses'] = [];
  for (const group of response.data ?? []) {
    for (const last of group.lastTransactions ?? []) {
      if (!last.signedTransactionInfo) continue;
      try {
        const decoded = await decodeJws(
          config,
          last.signedTransactionInfo,
          environment,
        );
        const productId = decoded.productId?.trim();
        if (!productId) continue;
        if (decoded.bundleId && decoded.bundleId !== config.bundleId) continue;
        statuses.push({
          status: last.status ?? Status.EXPIRED,
          productId,
          expiresDate: decoded.expiresDate,
          revocationDate: decoded.revocationDate,
          purchaseDate: decoded.purchaseDate,
          signedDate: decoded.signedDate,
        });
      } catch {
        // Discard unverified nested JWS — never keep numeric status alone.
      }
    }
  }
  return { statuses };
}

async function getTxn(
  config: AppleStoreConfig,
  transactionId: string,
  environment: Environment,
): Promise<JWSTransactionDecodedPayload | null> {
  if (config.getTransactionInfo) {
    return config.getTransactionInfo(transactionId, environment);
  }
  const client = apiClient(config, environment);
  const response = await client.getTransactionInfo(transactionId);
  if (!response.signedTransactionInfo) return null;
  return decodeJws(config, response.signedTransactionInfo, environment);
}

function apiClient(
  config: AppleStoreConfig,
  environment: Environment,
): AppStoreServerAPIClient {
  return new AppStoreServerAPIClient(
    normalizePem(config.privateKey!),
    config.keyId!,
    config.issuerId!,
    config.bundleId!,
    environment,
  );
}

export function looksLikeJws(token: string): boolean {
  const parts = token.split('.');
  return parts.length === 3 && parts.every((p) => p.length > 0);
}

export function loadAppleRootCertificates(paths: string[]): Buffer[] {
  const out: Buffer[] = [];
  for (const raw of paths) {
    const path = raw.trim();
    if (!path || !existsSync(path)) continue;
    out.push(readFileSync(path));
  }
  return out;
}

function toEnv(value: 'Production' | 'Sandbox'): Environment {
  return value === 'Sandbox' ? Environment.SANDBOX : Environment.PRODUCTION;
}

function normalizePem(key: string): string {
  return key.includes('\\n') ? key.replace(/\\n/g, '\n') : key;
}

function mapVerifyError(error: unknown): BillingVerifyResult {
  const message = String((error as { message?: string })?.message ?? error);
  if (/MISSING_APP_APPLE_ID/i.test(message)) {
    return billingResult('error', 'missing_app_apple_id');
  }
  if (/INVALID_APP_IDENTIFIER|bundle/i.test(message)) {
    return billingResult('unverified', 'bundle_mismatch');
  }
  if (/INVALID_ENVIRONMENT/i.test(message)) {
    return billingResult('unverified', 'environment_mismatch');
  }
  if (/VERIFICATION|signature|certificate|INVALID/i.test(message)) {
    return billingResult('unverified', 'jws_invalid');
  }
  return billingResult('error', 'provider_unavailable');
}

function isEnvMismatch(error: unknown): boolean {
  const message = String((error as { message?: string })?.message ?? error);
  return /INVALID_ENVIRONMENT/i.test(message);
}

function isTxnNotFound(error: unknown): boolean {
  const apiError = error as { httpStatusCode?: number; apiError?: number; errorCode?: number };
  const code = apiError.apiError ?? apiError.errorCode;
  if (code != null && TXN_NOT_FOUND.has(Number(code))) return true;
  const message = String((error as { message?: string })?.message ?? error);
  return /TransactionIdNotFound|not found/i.test(message);
}