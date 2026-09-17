/** Shipped Apple PKI roots must load via APPLE_ROOT_CA_DIR. */
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';
import { resolveAppleRootCertificates } from '../src/billing/load-credentials.js';

const shippedDir = join(process.cwd(), 'certs', 'apple');

const requiredNames = [
  'AppleIncRootCertificate.cer',
  'AppleRootCA-G2.cer',
  'AppleRootCA-G3.cer',
] as const;

describe('Apple root CA directory (shipped)', () => {
  it('ships the three official Apple PKI root certificates', () => {
    expect(existsSync(shippedDir)).toBe(true);
    const names = new Set(readdirSync(shippedDir));
    for (const name of requiredNames) {
      expect(names.has(name), `missing ${name}`).toBe(true);
    }
  });

  it('resolveAppleRootCertificates loads all .cer files from APPLE_ROOT_CA_DIR', () => {
    const certs = resolveAppleRootCertificates(null, shippedDir);
    expect(certs.length).toBeGreaterThanOrEqual(3);
    for (const buf of certs) {
      expect(Buffer.isBuffer(buf)).toBe(true);
      expect(buf.byteLength).toBeGreaterThan(200);
    }
  });

  it('Dockerfile copies certs/apple into /app/certs/apple for APPLE_ROOT_CA_DIR', () => {
    const dockerfile = readFileSync(join(process.cwd(), 'Dockerfile'), 'utf8');
    expect(dockerfile).toContain('COPY --chown=oracly:oracly certs/apple ./certs/apple');
    expect(dockerfile).toContain('APPLE_ROOT_CA_DIR=/app/certs/apple');
  });
});
