import type { AppCheck } from 'firebase-admin/app-check';
import type { Auth } from 'firebase-admin/auth';

export class RequestAuthError extends Error {
  constructor(readonly code: 'unauthorized' | 'app_check_required' | 'app_check_invalid' | 'verified_account_required') { super(code); }
}

export type VerifiedRequestIdentity = { uid: string; appId: string; email?: string; emailVerified: boolean; provider: string };
export interface OrderRequestVerifier {
  verify(request: Request): Promise<VerifiedRequestIdentity>;
  verifyPermanent(request: Request): Promise<VerifiedRequestIdentity>;
}

export class FirebaseOrderRequestVerifier implements OrderRequestVerifier {
  constructor(private readonly auth: Auth, private readonly appCheck: AppCheck, private readonly expectedWebAppId: string) {}

  async verify(request: Request): Promise<VerifiedRequestIdentity> {
    const authorization = request.headers.get('authorization') ?? '';
    const match = /^Bearer ([^\s]+)$/u.exec(authorization);
    if (!match) throw new RequestAuthError('unauthorized');
    const appCheckToken = request.headers.get('x-firebase-appcheck');
    if (!appCheckToken) throw new RequestAuthError('app_check_required');
    let decoded;
    try { decoded = await this.auth.verifyIdToken(match[1], true); } catch { throw new RequestAuthError('unauthorized'); }
    const uid = decoded.uid;
    if (!uid) throw new RequestAuthError('unauthorized');
    let appId: string;
    try { appId = (await this.appCheck.verifyToken(appCheckToken)).appId; } catch { throw new RequestAuthError('app_check_invalid'); }
    if (appId !== this.expectedWebAppId) throw new RequestAuthError('app_check_invalid');
    return { uid, appId, ...(typeof decoded.email === 'string' ? { email: decoded.email } : {}), emailVerified: decoded.email_verified === true, provider: decoded.firebase?.sign_in_provider ?? '' };
  }

  async verifyPermanent(request: Request): Promise<VerifiedRequestIdentity> {
    const identity = await this.verify(request);
    if (!identity.email || !identity.emailVerified || identity.provider === 'anonymous') throw new RequestAuthError('verified_account_required');
    return identity;
  }
}
