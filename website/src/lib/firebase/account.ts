'use client';

import { EmailAuthProvider, createUserWithEmailAndPassword, linkWithCredential, onAuthStateChanged, reload, sendEmailVerification, sendPasswordResetEmail, signInWithEmailAndPassword, signOut, type User } from '@firebase/auth';
import { getFirebaseAuth } from './client';

export type AccountErrorCode = 'email_in_use' | 'provider_disabled' | 'invalid_credentials' | 'anonymous_switch_confirmation_required' | 'unknown';
export class AccountActionError extends Error { constructor(readonly code: AccountErrorCode) { super(code); } }

export async function observeAccount(callback: (user: User | null) => void): Promise<() => void> {
  const auth = await getFirebaseAuth();
  return onAuthStateChanged(auth, callback);
}

export async function registerAccount(email: string, password: string): Promise<User> {
  const auth = await getFirebaseAuth();
  try {
    const user = auth.currentUser?.isAnonymous
      ? (await linkWithCredential(auth.currentUser, EmailAuthProvider.credential(email, password))).user
      : (await createUserWithEmailAndPassword(auth, email, password)).user;
    await sendEmailVerification(user);
    return user;
  } catch (error) { throw mapError(error); }
}

export async function loginAccount(email: string, password: string, confirmAnonymousSwitch = false): Promise<User> {
  const auth = await getFirebaseAuth();
  if (auth.currentUser?.isAnonymous && !confirmAnonymousSwitch) throw new AccountActionError('anonymous_switch_confirmation_required');
  try { return (await signInWithEmailAndPassword(auth, email, password)).user; } catch (error) { throw mapError(error); }
}

export async function logoutAccount(): Promise<void> { await signOut(await getFirebaseAuth()); }
export async function resetAccountPassword(email: string): Promise<void> { try { await sendPasswordResetEmail(await getFirebaseAuth(), email); } catch (error) { throw mapError(error); } }
export async function resendAccountVerification(): Promise<void> { const user = (await getFirebaseAuth()).currentUser; if (!user || user.isAnonymous) throw new AccountActionError('unknown'); await sendEmailVerification(user); }
export async function refreshAccount(): Promise<User | null> { const auth = await getFirebaseAuth(); if (auth.currentUser) await reload(auth.currentUser); return auth.currentUser; }

function mapError(error: unknown): AccountActionError {
  const code = typeof error === 'object' && error && 'code' in error ? String(error.code) : '';
  if (code === 'auth/email-already-in-use' || code === 'auth/credential-already-in-use') return new AccountActionError('email_in_use');
  if (code === 'auth/operation-not-allowed') return new AccountActionError('provider_disabled');
  if (code === 'auth/invalid-credential' || code === 'auth/wrong-password' || code === 'auth/user-not-found') return new AccountActionError('invalid_credentials');
  return new AccountActionError('unknown');
}
