import 'server-only';
import { applicationDefault, cert, getApp, getApps, initializeApp, type App } from 'firebase-admin/app';
import { getAppCheck } from 'firebase-admin/app-check';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { FirebaseOrderRequestVerifier } from './auth';
import { FirestoreOrderStore } from './store';
import { IyzicoCheckoutClient, type IyzicoConfig } from './iyzico';
import { CheckoutService } from './checkout';

export type OrderServerConfig = {
  enabled: true; expectedWebAppId: string; catalogVersion: string; priceMinor: number; currency: 'TRY'; firestoreDatabaseId: string;
};
export type CheckoutServerConfig = IyzicoConfig & { enabled: true };

export class OrderServerUnavailable extends Error { constructor() { super('order_server_unavailable'); } }

export function loadOrderServerConfig(): OrderServerConfig {
  const priceMinor = Number(process.env.ORACLY_COFFEE_ORDER_PRICE_MINOR);
  const expectedWebAppId = process.env.FIREBASE_APP_CHECK_WEB_APP_ID?.trim() ?? '';
  const catalogVersion = process.env.ORACLY_COFFEE_CATALOG_VERSION?.trim() ?? '';
  const firestoreDatabaseId = process.env.FIRESTORE_DATABASE_ID?.trim() || '(default)';
  if (process.env.ORACLY_ORDERS_ENABLED !== 'true' || !expectedWebAppId || !catalogVersion || !Number.isSafeInteger(priceMinor) || priceMinor <= 0) throw new OrderServerUnavailable();
  return { enabled: true, expectedWebAppId, catalogVersion, priceMinor, currency: 'TRY', firestoreDatabaseId };
}

export function createOrderRuntime() {
  const config = loadOrderServerConfig();
  const app = firebaseAdminApp();
  return {
    config,
    verifier: new FirebaseOrderRequestVerifier(getAuth(app), getAppCheck(app), config.expectedWebAppId),
    store: new FirestoreOrderStore(getFirestore(app, config.firestoreDatabaseId)),
  };
}

export function loadCheckoutServerConfig(): CheckoutServerConfig {
  if (process.env.ORACLY_IYZICO_CHECKOUT_ENABLED !== 'true') throw new OrderServerUnavailable();
  const environment = process.env.IYZICO_ENVIRONMENT === 'production' ? 'production' : 'sandbox';
  if (environment === 'production' && process.env.ORACLY_IYZICO_PRODUCTION_ENABLED !== 'true') throw new OrderServerUnavailable();
  const apiKey = process.env.IYZICO_API_KEY?.trim() ?? '';
  const secretKey = process.env.IYZICO_SECRET_KEY?.trim() ?? '';
  const callbackUrl = process.env.IYZICO_CALLBACK_URL?.trim() ?? '';
  if (!apiKey || !secretKey || !/^https:\/\//u.test(callbackUrl)) throw new OrderServerUnavailable();
  return { enabled: true, environment, apiKey, secretKey, callbackUrl, baseUrl: environment === 'sandbox' ? 'https://sandbox-api.iyzipay.com' : 'https://api.iyzipay.com' };
}

export function createCheckoutRuntime() {
  const orders = createOrderRuntime(); const checkoutConfig = loadCheckoutServerConfig();
  const provider = new IyzicoCheckoutClient(checkoutConfig);
  return { ...orders, checkoutConfig, provider, checkout: new CheckoutService(orders.store, provider) };
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
