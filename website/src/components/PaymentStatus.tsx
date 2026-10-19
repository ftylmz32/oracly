'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { getFirebaseRequestTokens } from '@/lib/firebase/client';

type OwnedOrder = { orderId: string; priceMinor: number; currency: string; status: string; providerPaymentStatus?: string; financialReviewRequired?: boolean };

export default function PaymentStatus({ orderId, callbackState }: { orderId?: string; callbackState?: string }) {
  const [order, setOrder] = useState<OwnedOrder | null>(null); const [error, setError] = useState('');
  useEffect(() => { if (!orderId) return; let active = true; void (async () => { try { const tokens = await getFirebaseRequestTokens(); const response = await fetch(`/api/orders/${encodeURIComponent(orderId)}`, { headers: { Authorization: `Bearer ${tokens.authToken}`, 'X-Firebase-AppCheck': tokens.appCheckToken }, cache: 'no-store' }); if (!response.ok) throw new Error('Bu sipariş hesabınız için bulunamadı.'); const value = await response.json() as { order: OwnedOrder }; if (active) setOrder(value.order); } catch (cause) { if (active) setError(cause instanceof Error ? cause.message : 'Sipariş doğrulanamadı.'); } })(); return () => { active = false; }; }, [orderId]);
  const granted = order?.status === 'entitlement_granted' || order?.status === 'entitlement_consumed';
  return <section className="payment-result-card" aria-live="polite"><span className="test-badge">SANDBOX / TEST</span><div className={`payment-result-symbol ${granted ? 'ok' : ''}`} aria-hidden="true">{granted ? '✓' : '◌'}</div><h1>{granted ? 'Ödeme doğrulandı' : callbackState === 'invalid' ? 'Geçersiz ödeme dönüşü' : 'Ödeme doğrulanıyor'}</h1><p>{granted ? 'Kahve falı hakkın siparişine güvenle tanımlandı.' : 'Ödeme sonucu sunucudan kontrol ediliyor. Sayfayı kapatmış olsan bile sipariş kaydın üzerinden toparlanabilir.'}</p>{order && <dl><div><dt>Sipariş</dt><dd>{order.orderId}</dd></div><div><dt>Tutar</dt><dd>{new Intl.NumberFormat('tr-TR', { style: 'currency', currency: order.currency }).format(order.priceMinor / 100)}</dd></div><div><dt>Durum</dt><dd>{order.providerPaymentStatus ?? order.status}</dd></div></dl>}{error && <div className="payment-state payment-error" role="alert">{error}</div>}<Link className="button button-gold" href="/kahve-fali">Kahve falına dön</Link></section>;
}
