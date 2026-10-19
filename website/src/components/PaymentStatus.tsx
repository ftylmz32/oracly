'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { getFirebaseRequestTokens } from '@/lib/firebase/client';
import { clearPurchaseAttempt } from '@/lib/orders/purchase-attempt';
import { paymentView, type PaymentView } from '@/lib/orders/payment-display';

type OwnedOrder = { orderId: string; priceMinor: number; currency: string; status: string; providerPaymentStatus?: string; financialReviewRequired?: boolean };

export default function PaymentStatus({ orderId, callbackState }: { orderId?: string; callbackState?: string }) {
  const [order, setOrder] = useState<OwnedOrder | null>(null); const [error, setError] = useState(''); const [pollingFinished, setPollingFinished] = useState(false);
  useEffect(() => {
    if (!orderId) return;
    let active = true; let timer: ReturnType<typeof setTimeout> | undefined; let attempts = 0;
    const poll = async () => {
      try {
        const headers = await secureHeaders(); const owned = await getOwnedOrder(orderId, headers);
        if (!active) return; setOrder(owned); setError('');
        const view = paymentView(owned.status, owned.providerPaymentStatus);
        if (view !== 'pending') { clearPurchaseAttempt(sessionStorage, owned.orderId); setPollingFinished(true); return; }
        attempts += 1;
        if (attempts >= 6) { setPollingFinished(true); return; }
        await fetch(`/api/orders/${encodeURIComponent(orderId)}/reconcile`, { method: 'POST', headers, cache: 'no-store' });
        if (active) timer = setTimeout(poll, 3_000);
      } catch (cause) {
        if (!active) return;
        setError(cause instanceof Error ? cause.message : 'Sipariş doğrulanamadı.'); setPollingFinished(true);
      }
    };
    void poll();
    return () => { active = false; if (timer) clearTimeout(timer); };
  }, [orderId]);
  const view: PaymentView = order ? paymentView(order.status, order.providerPaymentStatus) : 'pending';
  const copy = viewCopy(view, callbackState, pollingFinished || !orderId);
  return <section className="payment-result-card" aria-live="polite"><span className="test-badge">SANDBOX / TEST</span><div className={`payment-result-symbol ${view === 'paid' ? 'ok' : view === 'failed' || view === 'refunded' ? 'failed' : ''}`} aria-hidden="true">{view === 'paid' ? '✓' : view === 'failed' ? '×' : view === 'refunded' ? '↩' : '◌'}</div><h1>{copy.title}</h1><p>{copy.body}</p>{order && <dl><div><dt>Sipariş</dt><dd>{order.orderId}</dd></div><div><dt>Tutar</dt><dd>{new Intl.NumberFormat('tr-TR', { style: 'currency', currency: order.currency }).format(order.priceMinor / 100)}</dd></div><div><dt>Durum</dt><dd>{viewLabel(view)}</dd></div></dl>}{error && <div className="payment-state payment-error" role="alert">{error}</div>}<Link className="button button-gold" href="/kahve-fali">Kahve falına dön</Link></section>;
}

async function secureHeaders() { const tokens = await getFirebaseRequestTokens(); return { Authorization: `Bearer ${tokens.authToken}`, 'X-Firebase-AppCheck': tokens.appCheckToken }; }
async function getOwnedOrder(orderId: string, headers: Record<string, string>): Promise<OwnedOrder> { const response = await fetch(`/api/orders/${encodeURIComponent(orderId)}`, { headers, cache: 'no-store' }); if (!response.ok) throw new Error(response.status === 404 ? 'Bu sipariş mevcut kullanıcı oturumuna ait değil. Önceki oturumla tekrar giriş yapın.' : 'Sipariş durumu şu anda alınamadı.'); return ((await response.json()) as { order: OwnedOrder }).order; }
function viewLabel(view: PaymentView) { return view === 'paid' ? 'Doğrulandı' : view === 'failed' ? 'Başarısız / iptal' : view === 'refunded' ? 'İade edildi' : 'Bekliyor'; }
function viewCopy(view: PaymentView, callbackState: string | undefined, finished: boolean) {
  if (view === 'paid') return { title: 'Ödeme doğrulandı', body: 'Kahve falı hakkın siparişine güvenle tanımlandı. Gerçek fal başlatma özelliği hâlâ kapalıdır.' };
  if (view === 'failed') return { title: 'Ödeme tamamlanmadı', body: 'İşlem başarısız oldu, iptal edildi veya süresi doldu. Bu sipariş hak kazandırmadı.' };
  if (view === 'refunded') return { title: 'Ödeme iade edildi', body: 'İade finansal kayıtta korunuyor. Bu sipariş yeni bir fal hakkı sağlamaz.' };
  if (callbackState === 'invalid') return { title: 'Geçersiz ödeme dönüşü', body: 'Ödeme dönüşü doğrulanamadı ve hiçbir hak tanımlanmadı.' };
  return finished ? { title: 'Ödeme hâlâ bekliyor', body: 'Sınırlı doğrulama süresi doldu. Yeni tahsilat başlatılmadı; daha sonra bu sipariş bağlantısından tekrar kontrol edebilirsin.' } : { title: 'Ödeme doğrulanıyor', body: 'Sonuç yalnız sana ait sipariş kaydından sınırlı aralıklarla kontrol ediliyor. Sayfayı kapatsan bile sipariş kaydı korunur.' };
}
