'use client';

import { useMemo, useState, type FormEvent } from 'react';
import { getFirebaseRequestTokens, hasFirebaseWebConfiguration } from '@/lib/firebase/client';
import { COFFEE_READING_PRODUCT_ID } from '@/lib/orders/types';

type Order = { orderId: string; productId: string; priceMinor: number; currency: 'TRY'; status: string };
type Phase = 'idle' | 'creating' | 'details' | 'starting' | 'error';
const sandboxVerified = process.env.NEXT_PUBLIC_ORACLY_IYZICO_SANDBOX_VERIFIED === 'true';
const purchaseEnabled = process.env.NEXT_PUBLIC_ORACLY_PURCHASE_ENABLED === 'true';

export default function CoffeePurchase() {
  const [phase, setPhase] = useState<Phase>('idle');
  const [order, setOrder] = useState<Order | null>(null);
  const [error, setError] = useState('');
  const configured = useMemo(() => hasFirebaseWebConfiguration() && sandboxVerified && purchaseEnabled, []);
  const testPreview = process.env.NODE_ENV !== 'production';

  async function prepare() {
    if (!configured) return;
    setPhase('creating'); setError('');
    try {
      const headers = await secureHeaders();
      const response = await fetch('/api/orders', { method: 'POST', headers, body: JSON.stringify({ productId: COFFEE_READING_PRODUCT_ID, idempotencyKey: localIdempotencyKey() }) });
      if (!response.ok) throw new Error('Sipariş şu anda hazırlanamadı.');
      const value = await response.json() as { order: Order };
      setOrder(value.order); setPhase('details');
    } catch (cause) { setError(cause instanceof Error ? cause.message : 'Bir bağlantı hatası oluştu.'); setPhase('error'); }
  }

  async function startCheckout(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); if (!order || !configured) return;
    setPhase('starting'); setError('');
    const data = new FormData(event.currentTarget);
    const contactName = String(data.get('name')) + ' ' + String(data.get('surname'));
    const address = String(data.get('address'));
    try {
      const headers = await secureHeaders();
      const response = await fetch(`/api/orders/${encodeURIComponent(order.orderId)}/checkout`, { method: 'POST', headers, body: JSON.stringify({ buyer: { name: data.get('name'), surname: data.get('surname'), identityNumber: data.get('identityNumber'), email: data.get('email'), gsmNumber: data.get('gsmNumber'), registrationAddress: address, city: data.get('city'), country: 'Turkey' }, billingAddress: { address, contactName, city: data.get('city'), country: 'Turkey' } }) });
      const value = await response.json() as { paymentPageUrl?: string };
      if (!response.ok || !value.paymentPageUrl) throw new Error('Güvenli ödeme oturumu başlatılamadı.');
      window.location.assign(value.paymentPageUrl);
    } catch (cause) { setError(cause instanceof Error ? cause.message : 'Ödeme sağlayıcısına ulaşılamadı.'); setPhase('error'); }
  }

  return <section className="purchase-panel" aria-labelledby="purchase-title">
    <div className="purchase-heading"><div><div className="eyebrow">GÜVENLİ SATIN ALMA</div><h2 id="purchase-title">Kahve falı hakkın</h2><p>Fiyat ve ürün bilgisi yalnızca güvenli sunucu siparişinden alınır.</p></div>{testPreview && <span className="test-badge">TEST ÖNİZLEMESİ</span>}</div>
    <div className="order-summary"><span>Ürün</span><strong>ORACLY Tek Kahve Falı</strong><span>Tutar</span><strong>{order ? formatPrice(order.priceMinor, order.currency) : 'Sunucudan doğrulanacak'}</strong></div>
    {!configured && <div className="payment-state payment-locked"><strong>Satın alma kapalı</strong><p>Gerçek Firebase ve iyzico sandbox yapılandırması doğrulanmadan ödeme düğmesi etkinleşmez. Bu ekran ödeme almaz.</p></div>}
    {configured && phase !== 'details' && phase !== 'starting' && <button className="button button-gold purchase-primary" type="button" onClick={prepare} disabled={phase === 'creating'}>{phase === 'creating' ? 'Sipariş hazırlanıyor…' : 'Güvenli sipariş oluştur'}</button>}
    {order && (phase === 'details' || phase === 'starting') && <form className="buyer-form" onSubmit={startCheckout}><p className="data-note">Bu bilgiler iyzico Checkout Form sözleşmesi için kullanılır; kart bilgileri ORACLY sunucularına gelmez.</p><div className="buyer-grid">
      <label>Ad<input name="name" required maxLength={100} autoComplete="given-name" /></label><label>Soyad<input name="surname" required maxLength={100} autoComplete="family-name" /></label>
      <label>E-posta<input name="email" required type="email" maxLength={100} autoComplete="email" /></label><label>Telefon<input name="gsmNumber" required inputMode="tel" placeholder="+905xxxxxxxxx" pattern="\+?[0-9]{10,15}" autoComplete="tel" /></label>
      <label>Kimlik numarası<input name="identityNumber" required inputMode="numeric" pattern="[0-9]{10,11}" maxLength={11} autoComplete="off" /></label><label>Şehir<input name="city" required maxLength={100} autoComplete="address-level2" /></label>
      <label className="wide">Fatura adresi<textarea name="address" required maxLength={250} rows={3} autoComplete="street-address" /></label>
    </div><button className="button button-gold purchase-primary" disabled={phase === 'starting'}>{phase === 'starting' ? 'iyzico hazırlanıyor…' : `${formatPrice(order.priceMinor, order.currency)} · Sandbox ödemeye geç`}</button></form>}
    {error && <div className="payment-state payment-error" role="alert"><strong>İşlem tamamlanamadı</strong><p>{error}</p></div>}
    <small className="purchase-footnote">Feature flag varsayılan olarak kapalıdır. Üretim ödemesi bu aşamada etkin değildir.</small>
  </section>;
}

async function secureHeaders() { const tokens = await getFirebaseRequestTokens(); return { 'Content-Type': 'application/json', Authorization: `Bearer ${tokens.authToken}`, 'X-Firebase-AppCheck': tokens.appCheckToken }; }
function localIdempotencyKey() { const key = 'oracly_checkout_request'; const existing = sessionStorage.getItem(key); if (existing) return existing; const next = crypto.randomUUID().replaceAll('-', '_'); sessionStorage.setItem(key, next); return next; }
function formatPrice(minor: number, currency: string) { return new Intl.NumberFormat('tr-TR', { style: 'currency', currency }).format(minor / 100); }
