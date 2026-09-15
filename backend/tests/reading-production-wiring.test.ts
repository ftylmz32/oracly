import { describe, expect, it } from 'vitest';
import { loadConfig } from '../src/config.js';
import { createProductionReadingWiring } from '../src/reading/production-wiring.js';
import { PROVISIONAL_WAIT_MS, SOULMATE_NO_COMMERCIAL_WAIT_MS } from '../src/reading/wait-policy.js';

describe('BATCH 5F — production reading wiring', () => {
  it('fails closed (no fake durability) when Firestore is not configured', () => {
    const config = loadConfig({ APP_ENV: 'development' });
    const wiring = createProductionReadingWiring(config);
    expect(wiring.readingFlow).toBeNull();
    expect(wiring.gemLedger).toBeNull();
    // The repository/operations service still exist (createReadingOperationRepository
    // itself fails closed internally), but never a fake standing in as durable.
    expect(wiring.repository).toBeDefined();
    expect(wiring.operations).toBeDefined();
  });

  it('constructs a real ReadingFlow + GemLedger when locked and Firestore project id is present', () => {
    const config = loadConfig({
      APP_ENV: 'production',
      FIREBASE_PROJECT_ID: 'oracly-7f613',
      PORT: '8080',
    });
    expect(config.entitlementDurableRequired).toBe(true);
    const wiring = createProductionReadingWiring(config);
    // Constructing the Firestore SDK client is lazy/local — it never connects
    // just by being instantiated, so this is safe without live credentials.
    expect(wiring.readingFlow).not.toBeNull();
    expect(wiring.gemLedger).not.toBeNull();
  });

  it('never constructs Firestore-backed objects when firebaseProjectId is missing even if locked', () => {
    const config = loadConfig({ APP_ENV: 'production', PORT: '8080' });
    expect(config.firebaseProjectId).toBeFalsy();
    const wiring = createProductionReadingWiring(config);
    expect(wiring.readingFlow).toBeNull();
    expect(wiring.gemLedger).toBeNull();
  });
});

describe('ORACLY_DEV_READING_WAIT_MS wiring', () => {
  it('uses the real commercial wait durations when unset', () => {
    const config = loadConfig({ APP_ENV: 'development' });
    const wiring = createProductionReadingWiring(config);
    expect(wiring.policy.durationMs('coffee')).toBe(PROVISIONAL_WAIT_MS.coffee);
    expect(wiring.policy.durationMs('palm')).toBe(PROVISIONAL_WAIT_MS.palm);
    expect(wiring.policy.durationMs('soulmate')).toBe(SOULMATE_NO_COMMERCIAL_WAIT_MS);
  });

  it('overrides only coffee/palm in development when set — soulmate untouched', () => {
    const config = loadConfig({
      APP_ENV: 'development',
      ORACLY_DEV_READING_WAIT_MS: '10000',
    });
    const wiring = createProductionReadingWiring(config);
    expect(wiring.policy.durationMs('coffee')).toBe(10000);
    expect(wiring.policy.durationMs('palm')).toBe(10000);
    expect(wiring.policy.durationMs('soulmate')).toBe(SOULMATE_NO_COMMERCIAL_WAIT_MS);
  });

  it('never overrides the real commercial wait in production, even if set', () => {
    const config = loadConfig({
      APP_ENV: 'production',
      PORT: '8080',
      ORACLY_DEV_READING_WAIT_MS: '10000',
    });
    const wiring = createProductionReadingWiring(config);
    expect(wiring.policy.durationMs('coffee')).toBe(PROVISIONAL_WAIT_MS.coffee);
    expect(wiring.policy.durationMs('palm')).toBe(PROVISIONAL_WAIT_MS.palm);
  });
});
