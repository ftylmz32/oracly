/** Load Google service-account JSON and Apple root CA paths from env values. */

import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import type { JWTInput } from 'google-auth-library';
import { loadAppleRootCertificates } from './apple-store.js';

export function loadGooglePlayCredentials(
  jsonOrPath: string | null,
  applicationCredentialsPath: string | null,
): JWTInput | null {
  const raw = jsonOrPath ?? applicationCredentialsPath;
  if (!raw) return null;
  try {
    const text = raw.trim().startsWith('{')
      ? raw
      : existsSync(raw)
        ? readFileSync(raw, 'utf8')
        : null;
    if (!text) return null;
    const parsed = JSON.parse(text) as JWTInput;
    if (!parsed || typeof parsed !== 'object') return null;
    return parsed;
  } catch {
    return null;
  }
}

export function resolveAppleRootCertificates(
  pathsCsv: string | null,
  directory: string | null,
): Buffer[] {
  const paths: string[] = [];
  if (pathsCsv) {
    for (const part of pathsCsv.split(',')) {
      const p = part.trim();
      if (p) paths.push(p);
    }
  }
  if (directory && existsSync(directory)) {
    for (const name of readdirSync(directory)) {
      if (/\.(cer|der|pem|crt)$/i.test(name)) {
        paths.push(join(directory, name));
      }
    }
  }
  return loadAppleRootCertificates(paths);
}