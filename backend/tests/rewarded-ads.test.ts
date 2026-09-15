import { describe, expect, it } from 'vitest';
import { RewardedIdentityClaims } from '../src/ads/rewarded-identity-claim.js';
import { parseAdMobSsv, type AdMobSsvVerifier } from '../src/ads/admob-ssv.js';
import { GemLedger } from '../src/reading/gem-ledger.js';
import { provisionalGemCostPolicy } from '../src/reading/gem-cost-policy.js';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import type { ServerClock } from '../src/reading/clock.js';
import { identityKeyFromSubject } from '../src/auth/identity.js';
import { StaticAppCheckVerifier, appCheckHeader, authHeader, signHs256, testApp, testConfig } from './helpers.js';

class Clock implements ServerClock { constructor(public ms: number) {} now() { return new Date(this.ms); } }
const secret = 'rewarded-ad-test-secret-that-is-over-32-characters';
const verifier: AdMobSsvVerifier = { verify: async ({ signedContent }) => !signedContent.includes('tampered') };

async function setup() {
  const clock = new Clock(Date.parse('2026-09-09T10:00:00Z'));
  const store = new MemoryDocumentStore();
  const ledger = new GemLedger(store, clock, provisionalGemCostPolicy({ coffee: 10, palm: 10, soulmate: 10 }));
  const claims = new RewardedIdentityClaims(secret);
  const app = await testApp(testConfig({ AI_JWT_SECRET: 'unit-test-jwt-secret', ORACLY_REWARDED_AD_CLAIM_SECRET: secret }), undefined, { appCheck: new StaticAppCheckVerifier('test-app-check'), gemLedger: ledger, readingClock: clock, rewardedAds: { claims, verifier } });
  return { app, ledger, clock, claims };
}

describe('rewarded AdMob SSV', () => {
  it('issues an authenticated opaque claim and credits canonical amount once', async () => {
    const { app, ledger } = await setup();
    const headers = { ...authHeader(signHs256('unit-test-jwt-secret', { sub: 'user-a' })), ...appCheckHeader() };
    const claim = await app.inject({ method: 'POST', url: '/v1/gems/rewarded-ad/claim', headers, payload: {} });
    expect(claim.statusCode, claim.body).toBe(200);
    const customData = claim.json().data.customData as string;
    expect(customData).not.toContain('user-a');
    const url = `/v1/gems/rewarded-ad/ssv?ad_network=x&reward_amount=999999&transaction_id=tx-one&custom_data=${encodeURIComponent(customData)}&signature=valid&key_id=1`;
    expect((await app.inject({ method: 'GET', url })).statusCode).toBe(200);
    expect((await app.inject({ method: 'GET', url })).statusCode).toBe(200);
    expect(await ledger.balanceOf(identityKeyFromSubject('user-a'))).toBe(5);
    await app.close();
  });

  it('rejects tampering, malformed signature input, unknown binding, and expired claim', async () => {
    const { app, claims, clock, ledger } = await setup();
    const valid = claims.issue(identityKeyFromSubject('user-a'), clock.ms).customData;
    const callback = (data: string, prefix = 'tampered') => `/v1/gems/rewarded-ad/ssv?x=${prefix}&transaction_id=tx-two&custom_data=${encodeURIComponent(data)}&signature=s&key_id=1`;
    expect((await app.inject({ method: 'GET', url: callback(valid) })).statusCode).toBe(400);
    expect((await app.inject({ method: 'GET', url: '/v1/gems/rewarded-ad/ssv?transaction_id=x' })).statusCode).toBe(400);
    clock.ms += 11 * 60_000;
    expect((await app.inject({ method: 'GET', url: callback(valid, 'ok') })).statusCode).toBe(400);
    expect(await ledger.balanceOf(identityKeyFromSubject('user-a'))).toBe(0);
    await app.close();
  });

  it('preserves the exact signed query prefix', () => {
    const value = parseAdMobSsv('/x?a=1&transaction_id=t&custom_data=c&signature=s&key_id=7');
    expect(value?.signedContent).toBe('a=1&transaction_id=t&custom_data=c');
  });
});
