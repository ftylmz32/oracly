import { beforeEach, describe, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({
  getFirebaseAuth: vi.fn(), linkWithCredential: vi.fn(), createUserWithEmailAndPassword: vi.fn(),
  sendEmailVerification: vi.fn(), signInWithEmailAndPassword: vi.fn(), credential: vi.fn(() => ({ kind: 'credential' })),
}));
vi.mock('./client', () => ({ getFirebaseAuth: mocks.getFirebaseAuth }));
vi.mock('@firebase/auth', async (original) => ({ ...(await original<typeof import('@firebase/auth')>()), EmailAuthProvider: { credential: mocks.credential }, linkWithCredential: mocks.linkWithCredential, createUserWithEmailAndPassword: mocks.createUserWithEmailAndPassword, sendEmailVerification: mocks.sendEmailVerification, signInWithEmailAndPassword: mocks.signInWithEmailAndPassword }));

import { loginAccount, registerAccount } from './account';

describe('permanent Firebase account transitions', () => {
  beforeEach(() => vi.clearAllMocks());
  it('links an anonymous account and preserves its UID', async () => {
    const anonymous = { uid: 'anon-uid', isAnonymous: true };
    mocks.getFirebaseAuth.mockResolvedValue({ currentUser: anonymous }); mocks.linkWithCredential.mockResolvedValue({ user: anonymous });
    await expect(registerAccount('user@example.test', 'secret12')).resolves.toBe(anonymous);
    expect(mocks.linkWithCredential).toHaveBeenCalledWith(anonymous, { kind: 'credential' }); expect(mocks.createUserWithEmailAndPassword).not.toHaveBeenCalled();
  });
  it('never silently switches an anonymous UID during login', async () => {
    mocks.getFirebaseAuth.mockResolvedValue({ currentUser: { uid: 'anon-uid', isAnonymous: true } });
    await expect(loginAccount('user@example.test', 'secret12')).rejects.toMatchObject({ code: 'anonymous_switch_confirmation_required' });
    expect(mocks.signInWithEmailAndPassword).not.toHaveBeenCalled();
  });
  it('does not merge an email already owned by another account', async () => {
    mocks.getFirebaseAuth.mockResolvedValue({ currentUser: { uid: 'anon-uid', isAnonymous: true } });
    mocks.linkWithCredential.mockRejectedValue({ code: 'auth/email-already-in-use' });
    await expect(registerAccount('owned@example.test', 'secret12')).rejects.toMatchObject({ code: 'email_in_use' });
    expect(mocks.signInWithEmailAndPassword).not.toHaveBeenCalled();
  });
  it('reports a disabled Email/Password provider', async () => {
    mocks.getFirebaseAuth.mockResolvedValue({ currentUser: null }); mocks.createUserWithEmailAndPassword.mockRejectedValue({ code: 'auth/operation-not-allowed' });
    await expect(registerAccount('user@example.test', 'secret12')).rejects.toMatchObject({ code: 'provider_disabled' });
  });
});
