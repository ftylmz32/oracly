import type { AppCheck } from 'firebase-admin/app-check';
import type { Auth } from 'firebase-admin/auth';

export class RequestAuthError extends Error {
  constructor(readonly code: 'unauthorized' | 'app_check_required' | 'app_check_invalid') { super(code); }
}

export interface OrderRequestVerifier { verify(request: Request): Promise<{ uid: string; appId: string }>; }

export class FirebaseOrderRequestVerifier implements OrderRequestVerifier {
  constructor(private readonly auth: Auth, private readonly appCheck: AppCheck, private readonly expectedWebAppId: string) {}

  async verify(request: Request): Promise<{ uid: string; appId: string }> {
    const authorization = request.headers.get('authorization') ?? '';
    const match = /^Bearer ([^\s]+)$/u.exec(authorization);
    if (!match) throw new RequestAuthError('unauthorized');
    const appCheckToken = request.headers.get('x-firebase-appcheck');
    if (!appCheckToken) throw new RequestAuthError('app_check_required');
    let uid: string;
    try { uid = (await this.auth.verifyIdToken(match[1], true)).uid; } catch { throw new RequestAuthError('unauthorized'); }
    if (!uid) throw new RequestAuthError('unauthorized');
    let appId: string;
    try { appId = (await this.appCheck.verifyToken(appCheckToken)).appId; } catch { throw new RequestAuthError('app_check_invalid'); }
    if (appId !== this.expectedWebAppId) throw new RequestAuthError('app_check_invalid');
    return { uid, appId };
  }
}
