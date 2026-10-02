import {
  Environment,
  Status,
  VerificationException,
  VerificationStatus,
  type JWSTransactionDecodedPayload,
} from '@apple/app-store-server-library';
import { afterEach, describe, expect, it, vi } from 'vitest';
import {
  createAppleStoreVerifier,
  type AppleStoreConfig,
} from '../src/billing/apple-store.js';
import { testApp, testConfig } from './helpers.js';

const MONTHLY = 'app.oracly.premium.monthly';
const YEARLY = 'app.oracly.premium.yearly';
const LIFETIME = 'app.oracly.premium.lifetime';
const JWS = 'eyJhbGciOiJFUzI1NiJ9.SECRET-JWS-PAYLOAD.SECRET-JWS-SIGNATURE';
const PRIVATE_KEY = 'SECRET-PRIVATE-KEY-PEM';
const ISSUER = 'SECRET-ISSUER-ID';
const CAUSE_DETAIL = 'SECRET-CERT-CHAIN-DETAIL';

type Outcome = JWSTransactionDecodedPayload | { throws: unknown };

function sandboxPayload(productId = MONTHLY): JWSTransactionDecodedPayload {
  return {
    bundleId: 'app.oracly',
    productId,
    originalTransactionId: 'orig-sandbox',
    transactionId: 'txn-sandbox',
    expiresDate: Date.now() + 86_400_000,
    environment: Environment.SANDBOX,
  };
}

function harness(
  outcomes: Partial<Record<Environment, Outcome>>,
  overrides: Partial<AppleStoreConfig> = {},
) {
  const decodeEnvs: Environment[] = [];
  const statusEnvs: Environment[] = [];
  const verifier = createAppleStoreVerifier({
    bundleId: 'app.oracly',
    appAppleId: 1,
    issuerId: ISSUER,
    keyId: 'key',
    privateKey: PRIVATE_KEY,
    rootCertificates: [Buffer.from('cert')],
    preferEnvironment: 'Production',
    verifyJws: async (_jws, environment) => {
      decodeEnvs.push(environment);
      const outcome = outcomes[environment];
      if (!outcome) throw new Error('unexpected environment');
      if ('throws' in outcome) throw outcome.throws;
      return outcome;
    },
    getSubscriptionStatuses: async (_id, environment) => {
      statusEnvs.push(environment);
      return {
        statuses: [
          { status: Status.ACTIVE, productId: MONTHLY, expiresDate: Date.now() + 86_400_000 },
          { status: Status.ACTIVE, productId: YEARLY, expiresDate: Date.now() + 86_400_000 },
        ],
      };
    },
    ...overrides,
  });
  const verify = (productId = MONTHLY) =>
    verifier.verify({ platform: 'ios', productId, purchaseToken: JWS });
  return { verifier, verify, decodeEnvs, statusEnvs };
}

const real = (status: VerificationStatus, cause?: Error) =>
  ({ throws: new VerificationException(status, cause) });

describe('Apple VerificationException structured status mapping', () => {
  it('H: real VerificationException has an empty message, status still maps', async () => {
    const error = new VerificationException(VerificationStatus.INVALID_ENVIRONMENT);
    expect(error.message).toBe('');
    const { verify, decodeEnvs } = harness({
      [Environment.PRODUCTION]: { throws: error },
      [Environment.SANDBOX]: sandboxPayload(),
    });
    expect(await verify()).toMatchObject({ status: 'active', reason: 'subscription_active' });
    expect(decodeEnvs).toEqual([Environment.PRODUCTION, Environment.SANDBOX]);
  });

  it('A + TestFlight: Production-first verifies a Sandbox JWS, statuses load in Sandbox', async () => {
    const { verify, decodeEnvs, statusEnvs } = harness({
      [Environment.PRODUCTION]: real(VerificationStatus.INVALID_ENVIRONMENT),
      [Environment.SANDBOX]: sandboxPayload(YEARLY),
    });
    expect(await verify(YEARLY)).toMatchObject({ status: 'active', reason: 'subscription_active' });
    expect(decodeEnvs).toEqual([Environment.PRODUCTION, Environment.SANDBOX]);
    expect(statusEnvs[0]).toBe(Environment.SANDBOX);
  });

  it('Sandbox-first falls back to Production only on real INVALID_ENVIRONMENT', async () => {
    const { verify, decodeEnvs } = harness(
      {
        [Environment.SANDBOX]: real(VerificationStatus.INVALID_ENVIRONMENT),
        [Environment.PRODUCTION]: { ...sandboxPayload(), environment: Environment.PRODUCTION },
      },
      { preferEnvironment: 'Sandbox' },
    );
    expect(await verify()).toMatchObject({ status: 'active' });
    expect(decodeEnvs).toEqual([Environment.SANDBOX, Environment.PRODUCTION]);
  });

  it('mismatch in both environments stays unverified', async () => {
    const { verify, decodeEnvs } = harness({
      [Environment.PRODUCTION]: real(VerificationStatus.INVALID_ENVIRONMENT),
      [Environment.SANDBOX]: real(VerificationStatus.INVALID_ENVIRONMENT),
    });
    expect(await verify()).toEqual({ status: 'unverified', reason: 'environment_mismatch' });
    expect(decodeEnvs).toEqual([Environment.PRODUCTION, Environment.SANDBOX]);
  });

  it.each([
    ['B', VerificationStatus.INVALID_APP_IDENTIFIER, 'unverified', 'bundle_mismatch'],
    ['C', VerificationStatus.VERIFICATION_FAILURE, 'unverified', 'jws_invalid'],
    ['D', VerificationStatus.INVALID_CERTIFICATE, 'unverified', 'jws_invalid'],
    ['D2', VerificationStatus.INVALID_CHAIN_LENGTH, 'unverified', 'jws_invalid'],
    ['D3', VerificationStatus.FAILURE, 'unverified', 'jws_invalid'],
    ['E', VerificationStatus.RETRYABLE_VERIFICATION_FAILURE, 'error', 'provider_unavailable'],
    ['OK-thrown', VerificationStatus.OK, 'error', 'provider_unavailable'],
  ] as const)('%s: real status %s fails closed without trying Sandbox', async (_c, status, s, reason) => {
    const { verify, decodeEnvs, statusEnvs } = harness({
      [Environment.PRODUCTION]: real(status),
      [Environment.SANDBOX]: sandboxPayload(),
    });
    expect(await verify()).toEqual({ status: s, reason });
    expect(decodeEnvs).toEqual([Environment.PRODUCTION]);
    expect(statusEnvs).toEqual([]);
  });

  it.each([
    ['unknown VerificationException status', new VerificationException(99 as VerificationStatus)],
    ['unknown numeric status on a jws-looking Error', Object.assign(new Error('INVALID signature'), { status: 500 })],
    ['F: unrecognizable plain Error', new Error('socket hang up')],
    ['F: non-Error throwable', { detail: 'opaque' }],
  ])('%s -> provider_unavailable, Sandbox not attempted', async (_c, thrown) => {
    const { verify, decodeEnvs } = harness({
      [Environment.PRODUCTION]: { throws: thrown },
      [Environment.SANDBOX]: sandboxPayload(),
    });
    expect(await verify()).toEqual({ status: 'error', reason: 'provider_unavailable' });
    expect(decodeEnvs).toEqual([Environment.PRODUCTION]);
  });

  it('recognized numeric status on a duck-typed Error is honoured', async () => {
    const duck = Object.assign(new Error(''), { status: VerificationStatus.INVALID_ENVIRONMENT });
    const { verify, decodeEnvs } = harness({
      [Environment.PRODUCTION]: { throws: duck },
      [Environment.SANDBOX]: sandboxPayload(),
    });
    expect(await verify()).toMatchObject({ status: 'active' });
    expect(decodeEnvs).toEqual([Environment.PRODUCTION, Environment.SANDBOX]);
  });

  it('G: legacy message errors keep the backwards-compatible fallback', async () => {
    const env = harness({
      [Environment.PRODUCTION]: { throws: new Error('INVALID_ENVIRONMENT') },
      [Environment.SANDBOX]: sandboxPayload(),
    });
    expect(await env.verify()).toMatchObject({ status: 'active' });
    expect(env.decodeEnvs).toEqual([Environment.PRODUCTION, Environment.SANDBOX]);

    const sig = harness({
      [Environment.PRODUCTION]: { throws: new Error('VERIFICATION_FAILURE') },
      [Environment.SANDBOX]: sandboxPayload(),
    });
    expect(await sig.verify()).toEqual({ status: 'unverified', reason: 'jws_invalid' });
    expect(sig.decodeEnvs).toEqual([Environment.PRODUCTION]);
  });
});

describe('Apple verification security regressions', () => {
  afterEach(() => vi.restoreAllMocks());

  it('lifetime stays disallowed on iOS even when Sandbox would decode it', async () => {
    const { verify, decodeEnvs } = harness({
      [Environment.PRODUCTION]: real(VerificationStatus.INVALID_ENVIRONMENT),
      [Environment.SANDBOX]: sandboxPayload(LIFETIME),
    });
    expect(await verify(LIFETIME)).toEqual({ status: 'unverified', reason: 'platform_product_mismatch' });
    expect(decodeEnvs).toEqual([]);
  });

  it('wrong or unknown product never grants after an environment fallback', async () => {
    const wrong = harness({
      [Environment.PRODUCTION]: real(VerificationStatus.INVALID_ENVIRONMENT),
      [Environment.SANDBOX]: sandboxPayload(YEARLY),
    });
    expect(await wrong.verify(MONTHLY)).toEqual({ status: 'unverified', reason: 'product_mismatch' });
    const unknown = harness({ [Environment.PRODUCTION]: sandboxPayload() });
    expect(await unknown.verify('app.oracly.premium.weekly')).toEqual({
      status: 'unverified',
      reason: 'unknown_product',
    });
  });

  it('bundle mismatch in the fallback payload never grants', async () => {
    const { verify } = harness({
      [Environment.PRODUCTION]: real(VerificationStatus.INVALID_ENVIRONMENT),
      [Environment.SANDBOX]: { ...sandboxPayload(), bundleId: 'com.other.app' },
    });
    expect(await verify()).toEqual({ status: 'unverified', reason: 'bundle_mismatch' });
  });

  it('verifier and billing route never log exception contents, JWS, key or issuer', async () => {
    const consoleCalls: unknown[][] = [];
    for (const method of ['log', 'info', 'warn', 'error', 'debug'] as const) {
      vi.spyOn(console, method).mockImplementation((...args) => void consoleCalls.push(args));
    }
    const failure = real(VerificationStatus.INVALID_CERTIFICATE, new Error(CAUSE_DETAIL));
    const { verifier } = harness({ [Environment.PRODUCTION]: failure });
    const app = await testApp(
      testConfig({ AI_AUTH_REQUIRED: 'false', FIREBASE_PROJECT_ID: '', AI_JWKS_URL: '', AI_JWT_SECRET: '' }),
      undefined,
      { billing: { apple: verifier } },
    );
    const logged: string[] = [];
    const capture = (...args: unknown[]) => void logged.push(JSON.stringify(args));
    const logger = {
      level: 'info',
      info: capture, warn: capture, error: capture, debug: capture, trace: capture, fatal: capture,
      child: () => logger,
    };
    app.addHook('onRequest', async (request) => {
      (request as { log: unknown }).log = logger;
    });
    const res = await app.inject({
      method: 'POST',
      url: '/v1/billing/verify',
      payload: { platform: 'ios', productId: MONTHLY, purchaseToken: JWS },
    });
    await app.close();

    expect(res.json()).toEqual({ status: 'unverified', reason: 'jws_invalid' });
    expect(logged.some((line) => line.includes('billing_verify'))).toBe(true);
    const everything = [...logged, JSON.stringify(consoleCalls), res.body].join('\n');
    for (const secret of ['SECRET-JWS', PRIVATE_KEY, ISSUER, CAUSE_DETAIL, 'VerificationException']) {
      expect(everything).not.toContain(secret);
    }
    expect(consoleCalls).toEqual([]);
  });
});
