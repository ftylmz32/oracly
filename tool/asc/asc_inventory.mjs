// Read-only App Store Connect inventory for ORACLY (app 6812580786).
// GET requests only. Never prints the key, the bearer token or headers.
// First non-2xx answer stops the run with its real status and Apple code;
// there are no retries.
import { sign } from 'node:crypto';
import { writeFileSync } from 'node:fs';
import { AscKeyError, loadAscPrivateKey } from './asc_key.mjs';

const APP_ID = '6812580786';
const BUNDLE_ID = 'app.oracly';
const TARGETS = [
  'app.oracly.reading.coffee',
  'app.oracly.reading.palm',
  'app.oracly.reading.coffee.pack3',
  'app.oracly.premium.monthly',
  'app.oracly.premium.yearly',
];
const OUT = `${process.env.CM_BUILD_DIR ?? '.'}/asc_inventory.json`;

const env = {
  key: process.env.APP_STORE_CONNECT_PRIVATE_KEY,
  kid: process.env.APP_STORE_CONNECT_KEY_IDENTIFIER,
  iss: process.env.APP_STORE_CONNECT_ISSUER_ID,
};
console.log('credentials present:', {
  APP_STORE_CONNECT_PRIVATE_KEY: Boolean(env.key),
  APP_STORE_CONNECT_KEY_IDENTIFIER: Boolean(env.kid),
  APP_STORE_CONNECT_ISSUER_ID: Boolean(env.iss),
});
if (!env.key || !env.kid || !env.iss) {
  console.log('STOP: integration credentials are not available in this build.');
  process.exit(2);
}

// Only the fixed reason code is printed; the key never reaches the log.
let privateKey;
try {
  privateKey = loadAscPrivateKey(env.key);
} catch (error) {
  const reason = error instanceof AscKeyError ? error.reason : 'unexpected';
  console.log(`STOP: private key not usable (${reason}). No Apple request was made.`);
  process.exit(4);
}

const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
const now = Math.floor(Date.now() / 1000);
const unsigned = `${b64({ alg: 'ES256', kid: env.kid, typ: 'JWT' })}.` +
  b64({ iss: env.iss, iat: now, exp: now + 1200, aud: 'appstoreconnect-v1' });
const signature = sign('sha256', Buffer.from(unsigned), {
  key: privateKey,
  dsaEncoding: 'ieee-p1363',
}).toString('base64url');
const bearer = `${unsigned}.${signature}`;

// Price/localization details never hide the inventory: their errors are
// recorded on the product. Listing calls stop on the first error.
const DETAIL = { optional: true };

const report = { queriedAtUtc: new Date().toISOString(), appId: APP_ID, calls: [] };

function stop(path, status, body) {
  const err = body?.errors?.[0] ?? {};
  console.log(`STOP: GET ${path} -> ${status} ${err.code ?? ''} ${err.title ?? ''}`);
  report.error = { path, status, code: err.code ?? null, title: err.title ?? null };
  writeFileSync(OUT, JSON.stringify(report, null, 2));
  process.exit(3);
}

async function get(path, { optional = false } = {}) {
  const url = path.startsWith('http') ? path : `https://api.appstoreconnect.apple.com${path}`;
  // The bearer token only ever goes to Apple (pagination links included).
  if (new URL(url).origin !== 'https://api.appstoreconnect.apple.com') {
    stop('pagination', 'foreign_host', null);
  }
  const res = await fetch(url, { method: 'GET', headers: { Authorization: `Bearer ${bearer}` } });
  const body = await res.json().catch(() => null);
  const shown = url.replace('https://api.appstoreconnect.apple.com', '');
  report.calls.push({ path: shown, status: res.status });
  console.log(`GET ${shown} -> ${res.status}`);
  if (!res.ok) {
    if (!optional) stop(shown, res.status, body);
    return { error: { status: res.status, code: body?.errors?.[0]?.code ?? null } };
  }
  return body;
}

async function all(path, opts) {
  const data = [];
  const included = [];
  let next = path;
  while (next) {
    const page = await get(next, opts);
    if (page.error) return { data, included, error: page.error };
    data.push(...(page.data ?? []));
    included.push(...(page.included ?? []));
    next = page.links?.next ?? null;
  }
  return { data, included };
}

async function priceOfIap(iapId) {
  const sched = await get(`/v2/inAppPurchases/${iapId}/iapPriceSchedule?include=baseTerritory`, DETAIL);
  if (sched.error) return { error: sched.error };
  const scheduleId = sched.data?.id;
  const base = sched.included?.find((i) => i.type === 'territories')?.id ?? null;
  if (!scheduleId) return { baseTerritory: base, prices: [] };
  const { data, included, error } = await all(
    `/v1/inAppPurchasePriceSchedules/${scheduleId}/manualPrices` +
      '?include=inAppPurchasePricePoint,territory&limit=200',
    DETAIL,
  );
  if (error) return { baseTerritory: base, error };
  const points = new Map(included.filter((i) => i.type === 'inAppPurchasePricePoints').map((i) => [i.id, i.attributes]));
  return {
    baseTerritory: base,
    prices: data.map((p) => ({
      territory: p.relationships?.territory?.data?.id ?? null,
      startDate: p.attributes?.startDate ?? null,
      customerPrice: points.get(p.relationships?.inAppPurchasePricePoint?.data?.id)?.customerPrice ?? null,
    })),
  };
}

async function localizationsOfIap(iapId) {
  const { data, error } = await all(`/v2/inAppPurchases/${iapId}/inAppPurchaseLocalizations?limit=200`, DETAIL);
  if (error) return { error };
  return data.map((l) => ({ locale: l.attributes?.locale, name: l.attributes?.name, state: l.attributes?.state }));
}

async function priceOfSubscription(subId) {
  const { data, included, error } = await all(
    `/v1/subscriptions/${subId}/prices?include=subscriptionPricePoint,territory&filter[territory]=TUR&limit=200`,
    DETAIL,
  );
  if (error) return { error };
  const points = new Map(included.filter((i) => i.type === 'subscriptionPricePoints').map((i) => [i.id, i.attributes]));
  return data.map((p) => ({
    territory: p.relationships?.territory?.data?.id ?? null,
    startDate: p.attributes?.startDate ?? null,
    customerPrice: points.get(p.relationships?.subscriptionPricePoint?.data?.id)?.customerPrice ?? null,
  }));
}

const app = await get(`/v1/apps/${APP_ID}?fields[apps]=bundleId,name,sku`);
report.app = app.data?.attributes ?? null;
if (report.app?.bundleId !== BUNDLE_ID) stop(`/v1/apps/${APP_ID}`, 'bundle_mismatch', null);

const iaps = await all(`/v1/apps/${APP_ID}/inAppPurchasesV2?limit=200`);
report.inAppPurchasesComplete = true;
report.inAppPurchases = [];
for (const i of iaps.data) {
  const a = i.attributes ?? {};
  const row = { id: i.id, productId: a.productId, name: a.name, type: a.inAppPurchaseType, state: a.state };
  if (TARGETS.includes(a.productId) || a.productId?.startsWith('app.oracly.reading.')) {
    row.price = await priceOfIap(i.id);
    row.localizations = await localizationsOfIap(i.id);
  }
  report.inAppPurchases.push(row);
}

const groups = await all(`/v1/apps/${APP_ID}/subscriptionGroups?limit=200`);
report.subscriptionsComplete = true;
report.subscriptionGroups = [];
for (const g of groups.data) {
  const subs = await all(`/v1/subscriptionGroups/${g.id}/subscriptions?limit=200`);
  const rows = [];
  for (const s of subs.data) {
    const a = s.attributes ?? {};
    rows.push({
      id: s.id, productId: a.productId, name: a.name, state: a.state,
      period: a.subscriptionPeriod, pricesTUR: await priceOfSubscription(s.id),
    });
  }
  report.subscriptionGroups.push({ id: g.id, referenceName: g.attributes?.referenceName, subscriptions: rows });
}

const everything = [
  ...report.inAppPurchases.map((r) => ({ ...r, kind: 'inAppPurchase' })),
  ...report.subscriptionGroups.flatMap((g) => g.subscriptions.map((s) => ({ ...s, kind: 'subscription', type: 'AUTO_RENEWABLE' }))),
];
report.targets = TARGETS.map((id) => {
  const hit = everything.find((r) => r.productId === id);
  return hit
    ? { productId: id, exists: true, kind: hit.kind, type: hit.type, state: hit.state }
    : { productId: id, exists: false, note: 'absent from complete, paginated listing' };
});

writeFileSync(OUT, JSON.stringify(report, null, 2));
console.log('=== ALL IN-APP PURCHASES ===');
console.log(JSON.stringify(report.inAppPurchases, null, 2));
console.log('=== SUBSCRIPTION GROUPS ===');
console.log(JSON.stringify(report.subscriptionGroups, null, 2));
console.log('=== TARGETS ===');
console.table(report.targets);
