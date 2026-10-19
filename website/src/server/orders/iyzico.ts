import 'server-only';
import { createHmac, randomBytes, timingSafeEqual } from 'node:crypto';
import { COFFEE_READING_PRODUCT_ID } from '../../lib/orders/types';

const INITIALIZE_PATH = '/payment/iyzipos/checkoutform/initialize/auth/ecom';
const RETRIEVE_PATH = '/payment/iyzipos/checkoutform/auth/ecom/detail';

export type IyzicoConfig = {
  environment: 'sandbox' | 'production'; apiKey: string; secretKey: string;
  callbackUrl: string; baseUrl: string;
};
export type BuyerDetails = {
  name: string; surname: string; identityNumber: string; email: string; gsmNumber: string;
  registrationAddress: string; city: string; country: string; zipCode?: string;
};
export type BillingDetails = { address: string; contactName: string; city: string; country: string; zipCode?: string };
export type CheckoutOrder = { orderId: string; ownerUserId: string; priceMinor: number; currency: 'TRY'; productId: typeof COFFEE_READING_PRODUCT_ID };
export type IyzicoPaymentResult = {
  status: 'paid' | 'pending' | 'failed' | 'refunded'; conversationId: string;
  checkoutToken: string; basketId: string; providerPaymentId?: string;
  priceMinor: number; paidPriceMinor: number; currency: string; fraudStatus?: number;
  itemProductId?: string; itemPriceMinor?: number; paymentTransactionId?: string; transactionStatus?: number;
};

export class IyzicoError extends Error {}

export class IyzicoCheckoutClient {
  constructor(private readonly config: IyzicoConfig, private readonly http: typeof fetch = fetch, private readonly randomKey = () => randomBytes(16).toString('hex')) {}

  async initialize(order: CheckoutOrder, buyer: BuyerDetails, billingAddress: BillingDetails) {
    const amount = minorToDecimal(order.priceMinor);
    const body = {
      locale: 'tr', conversationId: order.orderId, price: amount, paidPrice: amount,
      currency: order.currency, basketId: order.orderId, paymentGroup: 'PRODUCT', callbackUrl: this.config.callbackUrl,
      enabledInstallments: [1], buyer: { id: order.ownerUserId, ...buyer }, billingAddress,
      basketItems: [{ id: order.productId, price: amount, name: 'ORACLY Kahve Falı', category1: 'Dijital Hizmet', itemType: 'VIRTUAL' }],
    };
    const result = await this.post(INITIALIZE_PATH, body);
    if (result.status !== 'success' || result.conversationId !== order.orderId || typeof result.token !== 'string' || typeof result.paymentPageUrl !== 'string') throw new IyzicoError('initialize_rejected');
    const page = new URL(result.paymentPageUrl);
    const expectedHost = this.config.environment === 'sandbox' ? 'sandbox-cpp.iyzipay.com' : 'cpp.iyzipay.com';
    if (page.protocol !== 'https:' || page.hostname !== expectedHost) throw new IyzicoError('invalid_payment_page');
    return { token: result.token, conversationId: result.conversationId, paymentPageUrl: page.toString() };
  }

  async retrieve(token: string, conversationId: string): Promise<IyzicoPaymentResult> {
    const value = await this.post(RETRIEVE_PATH, { locale: 'tr', conversationId, token });
    const items = Array.isArray(value.itemTransactions) ? value.itemTransactions as Record<string, unknown>[] : [];
    const matchingItems = items.filter((candidate) => string(candidate.itemId) === COFFEE_READING_PRODUCT_ID);
    const item = matchingItems.length === 1 ? matchingItems[0] : undefined;
    return {
      status: value.paymentStatus === 'SUCCESS' ? 'paid' : value.paymentStatus === 'REFUNDED' ? 'refunded' : value.status === 'success' ? 'pending' : 'failed',
      conversationId: string(value.conversationId), checkoutToken: string(value.token), basketId: string(value.basketId),
      providerPaymentId: typeof value.paymentId === 'string' ? value.paymentId : undefined,
      priceMinor: decimalToMinor(value.price), paidPriceMinor: decimalToMinor(value.paidPrice), currency: string(value.currency),
      fraudStatus: typeof value.fraudStatus === 'number' ? value.fraudStatus : undefined,
      itemProductId: item ? string(item.itemId) : undefined,
      itemPriceMinor: item ? decimalToMinor(item.price) : undefined,
      paymentTransactionId: item ? scalarString(item.paymentTransactionId) || undefined : undefined,
      transactionStatus: item && typeof item.transactionStatus === 'number' && Number.isInteger(item.transactionStatus) ? item.transactionStatus : undefined,
    };
  }

  verifyWebhook(rawBody: string, signature: string) {
    let value: Record<string, unknown>;
    try { value = JSON.parse(rawBody) as Record<string, unknown>; } catch { throw new IyzicoError('invalid_webhook'); }
    const eventType = string(value.iyziEventType); const paymentId = scalarString(value.iyziPaymentId);
    const token = string(value.token); const conversationId = string(value.paymentConversationId); const status = string(value.status);
    if (eventType !== 'CHECKOUT_FORM_AUTH' || !paymentId || !token || !conversationId || !status) throw new IyzicoError('invalid_webhook');
    const expected = createHmac('sha256', this.config.secretKey).update(this.config.secretKey + eventType + paymentId + token + conversationId + status).digest('hex');
    if (!safeEqualHex(expected, signature)) throw new IyzicoError('invalid_signature');
    return { orderId: conversationId, checkoutToken: token, providerPaymentId: paymentId, status };
  }

  private async post(path: string, value: object): Promise<Record<string, unknown>> {
    const body = JSON.stringify(value); const randomKey = this.randomKey();
    const signature = createHmac('sha256', this.config.secretKey).update(randomKey + path + body).digest('hex');
    const authorization = `IYZWSv2 ${Buffer.from(`apiKey:${this.config.apiKey}&randomKey:${randomKey}&signature:${signature}`).toString('base64')}`;
    const response = await this.http(this.config.baseUrl + path, { method: 'POST', headers: { Authorization: authorization, 'x-iyzi-rnd': randomKey, 'Content-Type': 'application/json' }, body, signal: AbortSignal.timeout(15_000) });
    let parsed: unknown; try { parsed = await response.json(); } catch { throw new IyzicoError('invalid_response'); }
    if (!response.ok || !parsed || typeof parsed !== 'object' || Array.isArray(parsed)) throw new IyzicoError('provider_unavailable');
    const result = parsed as Record<string, unknown>;
    if (result.status === 'success' && !verifyResponseSignature(path, result, this.config.secretKey)) throw new IyzicoError('invalid_response_signature');
    return result;
  }
}

export function validateBuyer(value: unknown): { buyer: BuyerDetails; billingAddress: BillingDetails } | null {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null;
  const body = value as Record<string, unknown>; const buyer = body.buyer; const billing = body.billingAddress;
  if (!buyer || typeof buyer !== 'object' || Array.isArray(buyer) || !billing || typeof billing !== 'object' || Array.isArray(billing)) return null;
  const b = buyer as Record<string, unknown>; const a = billing as Record<string, unknown>;
  const requiredBuyer = ['name','surname','identityNumber','email','gsmNumber','registrationAddress','city','country'];
  const requiredAddress = ['address','contactName','city','country'];
  if (!requiredBuyer.every((key) => validText(b[key], key === 'registrationAddress' ? 250 : 100)) || !requiredAddress.every((key) => validText(a[key], key === 'address' ? 250 : 100))) return null;
  if (!/^\S+@\S+\.\S+$/u.test(String(b.email)) || !/^\+?[0-9]{10,15}$/u.test(String(b.gsmNumber)) || !/^[0-9]{10,11}$/u.test(String(b.identityNumber))) return null;
  return {
    buyer: {
      name: String(b.name), surname: String(b.surname), identityNumber: String(b.identityNumber),
      email: String(b.email), gsmNumber: String(b.gsmNumber), registrationAddress: String(b.registrationAddress),
      city: String(b.city), country: String(b.country), ...(validText(b.zipCode, 20) ? { zipCode: String(b.zipCode) } : {}),
    },
    billingAddress: {
      address: String(a.address), contactName: String(a.contactName), city: String(a.city), country: String(a.country),
      ...(validText(a.zipCode, 20) ? { zipCode: String(a.zipCode) } : {}),
    },
  };
}

function validText(value: unknown, max: number) { return typeof value === 'string' && value.trim().length > 0 && value.length <= max; }
function string(value: unknown) { return typeof value === 'string' ? value : ''; }
function scalarString(value: unknown) { return typeof value === 'string' ? value : typeof value === 'number' && Number.isSafeInteger(value) ? String(value) : ''; }
function minorToDecimal(value: number) { return (value / 100).toFixed(2); }
function decimalToMinor(value: unknown) { const n = Number(value); return Number.isFinite(n) ? Math.round(n * 100) : -1; }
function safeEqualHex(expected: string, actual: string) { if (!/^[0-9a-f]{64}$/iu.test(actual)) return false; return timingSafeEqual(Buffer.from(expected, 'hex'), Buffer.from(actual, 'hex')); }
function verifyResponseSignature(path: string, value: Record<string, unknown>, secret: string) {
  const fields = path === INITIALIZE_PATH
    ? [value.conversationId, value.token]
    : [value.paymentStatus, value.paymentId, value.currency, value.basketId, value.conversationId, normalizedDecimal(value.paidPrice), normalizedDecimal(value.price), value.token];
  if (fields.some((field) => field === undefined || field === null || field === '')) return false;
  const expected = createHmac('sha256', secret).update(fields.map(String).join(':')).digest('hex');
  return typeof value.signature === 'string' && safeEqualHex(expected, value.signature);
}
function normalizedDecimal(value: unknown) { const raw = String(value); if (!/^\d+(?:\.\d+)?$/u.test(raw)) return ''; return raw.replace(/(?:\.0+|(?:(\.\d*?)0+))$/u, '$1').replace(/\.$/u, ''); }
