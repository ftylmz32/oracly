/** Google Play Developer API entitlement verification. */

import { GoogleAuth, type JWTInput } from 'google-auth-library';
import { isKnownProduct, productKind } from './catalog.js';
import {
  billingResult,
  type BillingVerifyRequest,
  type BillingVerifyResult,
  type StoreVerifier,
} from './types.js';

const PLAY_SCOPE = 'https://www.googleapis.com/auth/androidpublisher';
const PLAY_BASE =
  'https://androidpublisher.googleapis.com/androidpublisher/v3/applications';

export type GooglePlayConfig = {
  packageName: string;
  /** Parsed service-account JSON, or null when not configured. */
  credentials: JWTInput | null;
  fetchImpl?: typeof fetch;
  /** Test seam: override access-token acquisition. */
  getAccessToken?: () => Promise<string>;
};

export function createGooglePlayVerifier(
  config: GooglePlayConfig,
): StoreVerifier {
  const fetchImpl = config.fetchImpl ?? fetch;
  let auth: GoogleAuth | null = null;

  const getToken =
    config.getAccessToken ??
    (async () => {
      if (!config.credentials) throw new Error('missing_credentials');
      auth ??= new GoogleAuth({
        credentials: config.credentials,
        scopes: [PLAY_SCOPE],
      });
      const client = await auth.getClient();
      const token = await client.getAccessToken();
      if (!token.token) throw new Error('missing_access_token');
      return token.token;
    });

  return {
    get configured() {
      return Boolean(config.packageName && config.credentials);
    },
    async verify(request: BillingVerifyRequest): Promise<BillingVerifyResult> {
      if (!this.configured) {
        return billingResult('unverified', 'provider_not_configured');
      }
      if (!isKnownProduct(request.productId)) {
        return billingResult('unverified', 'unknown_product');
      }
      const kind = productKind(request.productId)!;
      try {
        const accessToken = await getToken();
        if (kind === 'subscription') {
          return await verifySubscription(
            fetchImpl,
            config.packageName,
            accessToken,
            request,
          );
        }
        return await verifyProduct(
          fetchImpl,
          config.packageName,
          accessToken,
          request,
        );
      } catch {
        return billingResult('error', 'provider_unavailable');
      }
    },
  };
}

async function verifySubscription(
  fetchImpl: typeof fetch,
  packageName: string,
  accessToken: string,
  request: BillingVerifyRequest,
): Promise<BillingVerifyResult> {
  const url =
    `${PLAY_BASE}/${encodeURIComponent(packageName)}` +
    `/purchases/subscriptionsv2/tokens/${encodeURIComponent(request.purchaseToken)}`;
  const res = await fetchImpl(url, {
    headers: { authorization: `Bearer ${accessToken}` },
  });
  if (res.status === 404 || res.status === 410) {
    return billingResult('inactive', 'not_found');
  }
  if (!res.ok) {
    return billingResult('error', `play_http_${res.status}`);
  }
  const body = (await res.json()) as Record<string, unknown>;
  const lineItems = Array.isArray(body.lineItems) ? body.lineItems : [];
  const matching = collectMatchingLineItems(lineItems, request.productId);
  if (matching.length === 0) {
    return billingResult('unverified', 'product_mismatch');
  }

  const state = String(body.subscriptionState ?? '');

  // Grace: matching product is enough; Play state is authoritative for access.
  if (state === 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD') {
    return billingResult('active', 'grace_period');
  }
  if (state === 'SUBSCRIPTION_STATE_PENDING') {
    return billingResult('pending', 'subscription_pending');
  }
  if (state === 'SUBSCRIPTION_STATE_EXPIRED') {
    return billingResult('expired', 'subscription_expired');
  }
  if (
    state === 'SUBSCRIPTION_STATE_ON_HOLD' ||
    state === 'SUBSCRIPTION_STATE_PAUSED' ||
    state === 'SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED'
  ) {
    return billingResult('inactive', state.toLowerCase());
  }

  if (
    state !== 'SUBSCRIPTION_STATE_ACTIVE' &&
    state !== 'SUBSCRIPTION_STATE_CANCELED'
  ) {
    return billingResult('unverified', 'unknown_subscription_state');
  }

  const selected = selectBestMatchingLineItem(matching);
  if (selected == null) {
    return billingResult('unverified', 'missing_expiry');
  }
  const now = Date.now();
  if (selected.expiryMs > now) {
    return state === 'SUBSCRIPTION_STATE_ACTIVE'
      ? billingResult('active', 'subscription_active')
      : billingResult('active', 'canceled_still_entitled');
  }
  return state === 'SUBSCRIPTION_STATE_ACTIVE'
    ? billingResult('expired', 'subscription_past_expiry')
    : billingResult('expired', 'canceled_expired');
}

type MatchingLineItem = {
  item: Record<string, unknown>;
  expiryMs: number | null;
};

function collectMatchingLineItems(
  lineItems: unknown[],
  productId: string,
): MatchingLineItem[] {
  const out: MatchingLineItem[] = [];
  for (const raw of lineItems) {
    if (!raw || typeof raw !== 'object') continue;
    const item = raw as Record<string, unknown>;
    if (String(item.productId ?? '') !== productId) continue;
    const expiryMs = parseExpiry(item.expiryTime ?? item.expiryTimeMillis);
    out.push({ item, expiryMs });
  }
  return out;
}

/** Prefer future entitlement, then latest expiry. Ignore order. */
function selectBestMatchingLineItem(
  matching: MatchingLineItem[],
): { item: Record<string, unknown>; expiryMs: number } | null {
  const withExpiry = matching.filter(
    (m): m is MatchingLineItem & { expiryMs: number } => m.expiryMs != null,
  );
  if (withExpiry.length === 0) return null;
  const now = Date.now();
  const future = withExpiry.filter((m) => m.expiryMs > now);
  const pool = future.length > 0 ? future : withExpiry;
  pool.sort((a, b) => b.expiryMs - a.expiryMs);
  return pool[0];
}

async function verifyProduct(
  fetchImpl: typeof fetch,
  packageName: string,
  accessToken: string,
  request: BillingVerifyRequest,
): Promise<BillingVerifyResult> {
  const url =
    `${PLAY_BASE}/${encodeURIComponent(packageName)}` +
    `/purchases/products/${encodeURIComponent(request.productId)}` +
    `/tokens/${encodeURIComponent(request.purchaseToken)}`;
  const res = await fetchImpl(url, {
    headers: { authorization: `Bearer ${accessToken}` },
  });
  if (res.status === 404 || res.status === 410) {
    return billingResult('inactive', 'not_found');
  }
  if (!res.ok) {
    return billingResult('error', `play_http_${res.status}`);
  }
  const body = (await res.json()) as Record<string, unknown>;
  // purchaseState: 0 purchased, 1 canceled, 2 pending
  const purchaseState = Number(body.purchaseState);
  if (purchaseState === 2) {
    return billingResult('pending', 'product_pending');
  }
  if (purchaseState === 1) {
    return billingResult('inactive', 'product_canceled');
  }
  if (purchaseState !== 0) {
    return billingResult('unverified', 'unknown_purchase_state');
  }
  return billingResult('active', 'product_purchased');
}

function parseExpiry(raw: unknown): number | null {
  if (raw == null) return null;
  if (typeof raw === 'number' && Number.isFinite(raw)) {
    return raw < 1e12 ? raw * 1000 : raw;
  }
  const s = String(raw).trim();
  if (!s) return null;
  if (/^\d+$/.test(s)) {
    const n = Number(s);
    return n < 1e12 ? n * 1000 : n;
  }
  const ms = Date.parse(s);
  return Number.isFinite(ms) ? ms : null;
}