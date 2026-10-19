'use client';

import { useEffect, useMemo, useState, type FormEvent } from 'react';
import { getFirebaseRequestTokens, hasFirebaseWebConfiguration } from '@/lib/firebase/client';
import { COFFEE_READING_PRODUCT_ID } from '@/lib/orders/types';
import { bindPurchaseOrder, clearPurchaseAttempt, getOrCreatePurchaseAttempt, isTerminalOrder, readPurchaseAttempt } from '@/lib/orders/purchase-attempt';

type Order = { orderId: string; productId: string; priceMinor: number; currency: 'TRY'; status: string; providerPaymentStatus?: string };
type Phase = 'idle' | 'recovering' | 'creating' | 'details' | 'starting' | 'terminal' | 'error';
const sandboxVerified = process.env.NEXT_PUBLIC_ORACLY_IYZICO_SANDBOX_VERIFIED === 'true';
const purchaseEnabled = process.env.NEXT_PUBLIC_ORACLY_PURCHASE_ENABLED === 'true';

export default function CoffeePurchase() {
  const [phase, setPhase] = useState<Phase>('idle');
  const [order, setOrder] = useState<Order | null>(null);
  const [error, setError] = useState('');
  const configured = useMemo(() => hasFirebaseWebConfiguration() && sandboxVerified && purchaseEnabled, []);
  const testPreview = process.env.NODE_ENV !== 'production';

  useEffect(() => {
    if (!configured) return;
    const attempt = readPurchaseAttempt(sessionStorage); if (!attempt?.orderId) return;
    let active = true;
    void fetchOwnedOrder(attempt.orderId).then((owned) => {
      if (!active) return;
      setOrder(owned);
      if (isTerminalOrder(owned.status, owned.providerPaymentStatus)) { clearPurchaseAttempt(sessionStorage, owned.orderId); setPhase('terminal'); }
      else setPhase('details');
    }).catch(() => { if (active) { setError('Önceki sipariş güvenle doğrulanamadı. Yeni tahsilat başlatılmadı.'); setPhase('error'); } });
    return () => { active = false; };
  }, [configured]);

  async function prepare() {
    if (!configured) return;
    setPhase('creating'); setError('');
    try {
      const attempt = getOrCreatePurchaseAttempt(sessionStorage);
      const headers = await secureHeaders();
      const response = await fetch('/api/orders', { method: 'POST', headers, body: JSON.stringify({ productId: COFFEE_READING_PRODUCT_ID, idempotencyKey: attempt.idempotencyKey }) });
      if (!response.ok) throw new Error('Sipariş şu anda hazırlanamadı.');
      const value = await response.json() as { order: Order };
      bindPurchaseOrder(sessionStorage, attempt, value.order.orderId);
      setOrder(value.order);
      if (isTerminalOrder(value.order.status, value.order.providerPaymentStatus)) { clearPurchaseAttempt(sessionStorage, value.order.orderId); setPhase('terminal'); } else setPhase('details');
    } catch (cause) { setError(cause instanceof Error ? cause.message : 'Bir bağlantı hatası oluştu.'); setPhase('error'); }
  }

  function beginAnotherPurchase() { clearPurchaseAttempt(sessionStorage); setOrder(null); setError(''); setPhase('idle'); }

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
    {configured && !['details','starting','terminal'].includes(phase) && <button className="button button-gold purchase-primary" type="button" onClick={prepare} disabled={phase === 'creating' || phase === 'recovering'}>{phase === 'creating' ? 'Sipariş hazırlanıyor…' : phase === 'recovering' ? 'Önceki sipariş aranıyor…' : 'Güvenli sipariş oluştur'}</button>}
    {order && (phase === 'details' || phase === 'starting') && <form className="buyer-form" onSubmit={startCheckout}><p className="data-note">Bu bilgiler iyzico Checkout Form sözleşmesi için kullanılır; kart bilgileri ORACLY sunucularına gelmez.</p><div className="buyer-grid">
      <label>Ad<input name="name" required maxLength={100} autoComplete="given-name" /></label><label>Soyad<input name="surname" required maxLength={100} autoComplete="family-name" /></label>
      <label>E-posta<input name="email" required type="email" maxLength={100} autoComplete="email" /></label><label>Telefon<input name="gsmNumber" required inputMode="tel" placeholder="+905xxxxxxxxx" pattern="\+?[0-9]{10,15}" autoComplete="tel" /></label>
      <label>Kimlik numarası<input name="identityNumber" required inputMode="numeric" pattern="[0-9]{10,11}" maxLength={11} autoComplete="off" /></label><label>Şehir<input name="city" required maxLength={100} autoComplete="address-level2" /></label>
      <label className="wide">Fatura adresi<textarea name="address" required maxLength={250} rows={3} autoComplete="street-address" /></label>
    </div><button className="button button-gold purchase-primary" disabled={phase === 'starting'}>{phase === 'starting' ? 'iyzico hazırlanıyor…' : `${formatPrice(order.priceMinor, order.currency)} · Sandbox ödemeye geç`}</button></form>}
    {order && phase === 'terminal' && <div className="payment-state"><strong>{order.status === 'refunded' || order.providerPaymentStatus === 'refunded' ? 'Sipariş iade edildi' : order.status === 'failed' || order.providerPaymentStatus === 'failed' ? 'Ödeme tamamlanmadı' : 'Bu sipariş tamamlandı'}</strong><p>Bu sipariş yeni bir tahsilat için tekrar kullanılmaz. İstersen bağımsız bir kahve falı hakkı için yeni sipariş oluşturabilirsin.</p><button className="button button-gold purchase-primary" type="button" onClick={beginAnotherPurchase}>Yeni fal hakkı satın al</button></div>}
    {error && <div className="payment-state payment-error" role="alert"><strong>İşlem tamamlanamadı</strong><p>{error}</p></div>}
    <small className="purchase-footnote">Feature flag varsayılan olarak kapalıdır. Üretim ödemesi bu aşamada etkin değildir.</small>
  </section>;
}

async function secureHeaders() { const tokens = await getFirebaseRequestTokens({ permanent: true, createAnonymous: false }); return { 'Content-Type': 'application/json', Authorization: `Bearer ${tokens.authToken}`, 'X-Firebase-AppCheck': tokens.appCheckToken }; }
async function fetchOwnedOrder(orderId: string): Promise<Order> { const headers = await secureHeaders(); const response = await fetch(`/api/orders/${encodeURIComponent(orderId)}`, { headers, cache: 'no-store' }); if (!response.ok) throw new Error('order_unavailable'); return ((await response.json()) as { order: Order }).order; }
function formatPrice(minor: number, currency: string) { return new Intl.NumberFormat('tr-TR', { style: 'currency', currency }).format(minor / 100); }
