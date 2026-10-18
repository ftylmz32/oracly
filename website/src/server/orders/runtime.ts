import 'server-only';
import { applicationDefault, cert, getApp, getApps, initializeApp, type App } from 'firebase-admin/app';
import { getAppCheck } from 'firebase-admin/app-check';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { FirebaseOrderRequestVerifier } from './auth';
import { FirestoreOrderStore } from './store';

export type OrderServerConfig = {
  enabled: true; expectedWebAppId: string; catalogVersion: string; priceMinor: number; currency: 'TRY';
};

export class OrderServerUnavailable extends Error { constructor() { super('order_server_unavailable'); } }

export function loadOrderServerConfig(): OrderServerConfig {
  const priceMinor = Number(process.env.ORACLY_COFFEE_ORDER_PRICE_MINOR);
  const expectedWebAppId = process.env.FIREBASE_APP_CHECK_WEB_APP_ID?.trim() ?? '';
  const catalogVersion = process.env.ORACLY_COFFEE_CATALOG_VERSION?.trim() ?? '';
  if (process.env.ORACLY_ORDERS_ENABLED !== 'true' || !expectedWebAppId || !catalogVersion || !Number.isSafeInteger(priceMinor) || priceMinor <= 0) throw new OrderServerUnavailable();
  return { enabled: true, expectedWebAppId, catalogVersion, priceMinor, currency: 'TRY' };
}

export function createOrderRuntime() {
  const config = loadOrderServerConfig();
  const app = firebaseAdminApp();
  return {
    config,
    verifier: new FirebaseOrderRequestVerifier(getAuth(app), getAppCheck(app), config.expectedWebAppId),
    store: new FirestoreOrderStore(getFirestore(app)),
  };
}

function firebaseAdminApp(): App {
  const name = 'oracly-web-orders';
  const existing = getApps().find((candidate) => candidate.name === name);
  if (existing) return getApp(name);
  const projectId = process.env.FIREBASE_ADMIN_PROJECT_ID?.trim();
  if (!projectId) throw new OrderServerUnavailable();
  const clientEmail = process.env.FIREBASE_ADMIN_CLIENT_EMAIL?.trim();
  const privateKey = process.env.FIREBASE_ADMIN_PRIVATE_KEY?.replace(/\\n/gu, '\n').trim();
  if (Boolean(clientEmail) !== Boolean(privateKey)) throw new OrderServerUnavailable();
  const credential = clientEmail && privateKey ? cert({ projectId, clientEmail, privateKey }) : applicationDefault();
  return initializeApp({ projectId, credential }, name);
}
