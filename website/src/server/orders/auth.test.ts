import { describe, expect, it, vi } from 'vitest';
import type { AppCheck } from 'firebase-admin/app-check';
import type { Auth } from 'firebase-admin/auth';
import { FirebaseOrderRequestVerifier } from './auth';

function verifier(options: { authOk?: boolean; appOk?: boolean; appId?: string; emailVerified?: boolean; provider?: string } = {}) {
  const auth = { verifyIdToken: vi.fn(async () => { if (options.authOk === false) throw new Error('bad'); return { uid: 'uid-a', email: 'user@example.test', email_verified: options.emailVerified ?? true, firebase: { sign_in_provider: options.provider ?? 'password' } }; }) } as unknown as Auth;
  const appCheck = { verifyToken: vi.fn(async () => { if (options.appOk === false) throw new Error('bad'); return { appId: options.appId ?? 'web-app-id' }; }) } as unknown as AppCheck;
  return { auth, appCheck, value: new FirebaseOrderRequestVerifier(auth, appCheck, 'web-app-id') };
}

const request = (headers: HeadersInit = {}) => new Request('https://example.test/api/orders', { headers });

describe('Firebase order request verification', () => {
  it('requires a strict bearer token', async () => {
    await expect(verifier().value.verify(request({ 'X-Firebase-AppCheck': 'app' }))).rejects.toMatchObject({ code: 'unauthorized' });
  });
  it('requires App Check and cannot skip verification', async () => {
    const value = verifier();
    await expect(value.value.verify(request({ Authorization: 'Bearer auth' }))).rejects.toMatchObject({ code: 'app_check_required' });
    expect(value.appCheck.verifyToken).not.toHaveBeenCalled();
  });
  it('rejects invalid auth, invalid App Check, and a different Firebase app', async () => {
    const headers = { Authorization: 'Bearer auth', 'X-Firebase-AppCheck': 'app' };
    await expect(verifier({ authOk: false }).value.verify(request(headers))).rejects.toMatchObject({ code: 'unauthorized' });
    await expect(verifier({ appOk: false }).value.verify(request(headers))).rejects.toMatchObject({ code: 'app_check_invalid' });
    await expect(verifier({ appId: 'mobile-app-id' }).value.verify(request(headers))).rejects.toMatchObject({ code: 'app_check_invalid' });
  });
  it('returns verified identity claims', async () => {
    await expect(verifier().value.verify(request({ Authorization: 'Bearer auth', 'X-Firebase-AppCheck': 'app' }))).resolves.toEqual({ uid: 'uid-a', appId: 'web-app-id', email: 'user@example.test', emailVerified: true, provider: 'password' });
  });
  it('requires a verified non-anonymous account for paid operations', async () => {
    const headers = { Authorization: 'Bearer auth', 'X-Firebase-AppCheck': 'app' };
    await expect(verifier({ provider: 'anonymous' }).value.verifyPermanent(request(headers))).rejects.toMatchObject({ code: 'verified_account_required' });
    await expect(verifier({ emailVerified: false }).value.verifyPermanent(request(headers))).rejects.toMatchObject({ code: 'verified_account_required' });
    await expect(verifier().value.verifyPermanent(request(headers))).resolves.toMatchObject({ uid: 'uid-a', emailVerified: true });
  });
});
