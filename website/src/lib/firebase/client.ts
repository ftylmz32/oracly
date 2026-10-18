import { getApp, getApps, initializeApp, type FirebaseApp, type FirebaseOptions } from '@firebase/app';
import { getAuth, signInAnonymously } from '@firebase/auth';
import { getToken, initializeAppCheck, ReCaptchaEnterpriseProvider, type AppCheck } from '@firebase/app-check';

const firebaseOptions: FirebaseOptions = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
};

const appCheckSiteKey = process.env.NEXT_PUBLIC_FIREBASE_APP_CHECK_SITE_KEY?.trim();

export function hasFirebaseWebConfiguration(): boolean {
  return Boolean(
    firebaseOptions.apiKey && firebaseOptions.authDomain && firebaseOptions.projectId &&
    firebaseOptions.appId && firebaseOptions.messagingSenderId && appCheckSiteKey,
  );
}

let appCheck: AppCheck | null = null;

function firebaseApp(): FirebaseApp {
  if (!hasFirebaseWebConfiguration()) throw new Error('firebase_web_not_configured');
  return getApps().length ? getApp() : initializeApp(firebaseOptions);
}

function firebaseAppCheck(app: FirebaseApp): AppCheck {
  if (!appCheck) {
    appCheck = initializeAppCheck(app, {
      provider: new ReCaptchaEnterpriseProvider(appCheckSiteKey!),
      isTokenAutoRefreshEnabled: true,
    });
  }
  return appCheck;
}

export async function getFirebaseRequestTokens(): Promise<{ authToken: string; appCheckToken: string }> {
  const app = firebaseApp();
  const auth = getAuth(app);
  const user = auth.currentUser ?? (await signInAnonymously(auth)).user;
  const [authToken, appCheckResult] = await Promise.all([
    user.getIdToken(),
    getToken(firebaseAppCheck(app), false),
  ]);
  return { authToken, appCheckToken: appCheckResult.token };
}
