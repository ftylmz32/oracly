'use client';

import { useCallback, useEffect, useRef, useState, type FormEvent } from 'react';
import type { User } from '@firebase/auth';
import { AccountActionError, loginAccount, logoutAccount, observeAccount, refreshAccount, registerAccount, resendAccountVerification, resetAccountPassword } from '@/lib/firebase/account';
import { AccountOrderIsolation } from '@/lib/firebase/account-order-isolation';
import { getFirebaseRequestTokens, hasFirebaseWebConfiguration } from '@/lib/firebase/client';

type Order = { orderId: string; priceMinor: number; currency: string; status: string; providerPaymentStatus?: string; financialReviewRequired: boolean; createdAtMs: number };
type Mode = 'login' | 'register' | 'reset';

export default function AccountDashboard() {
  const configured = hasFirebaseWebConfiguration();
  const [user, setUser] = useState<User | null | undefined>(configured ? undefined : null);
  const [mode, setMode] = useState<Mode>('login'); const [notice, setNotice] = useState(''); const [busy, setBusy] = useState(false); const [confirmSwitch, setConfirmSwitch] = useState(false);
  const [orders, setOrders] = useState<Order[]>([]); const [cursor, setCursor] = useState<string>();
  const isolation = useRef(new AccountOrderIsolation());

  const clearAccountUi = useCallback(() => { setOrders([]); setCursor(undefined); setNotice(''); setBusy(false); setConfirmSwitch(false); setMode('login'); }, []);
  const loadOrders = useCallback(async (uid: string, next?: string, replace = false) => {
    const request = isolation.current.begin(uid); if (!request) return;
    try {
      const tokens = await getFirebaseRequestTokens({ permanent: true, createAnonymous: false });
      if (!isolation.current.accepts(request)) return;
      const response = await fetch(`/api/account/orders?limit=10${next ? `&cursor=${encodeURIComponent(next)}` : ''}`, { headers: { Authorization: `Bearer ${tokens.authToken}`, 'X-Firebase-AppCheck': tokens.appCheckToken }, cache: 'no-store', signal: request.signal });
      if (!response.ok) throw new Error('orders_unavailable');
      const body = await response.json() as { orders: Order[]; nextCursor?: string };
      if (!isolation.current.accepts(request)) return;
      setOrders((old) => replace ? body.orders : [...old, ...body.orders]); setCursor(body.nextCursor);
    } catch { if (!request.signal.aborted && isolation.current.accepts(request)) setNotice('Satın alma geçmişi güvenli biçimde yüklenemedi.'); }
  }, []);

  useEffect(() => {
    if (!configured) return;
    const accountIsolation = isolation.current;
    let unsubscribe: (() => void) | undefined;
    void observeAccount((next) => {
      accountIsolation.switchAccount(next?.uid ?? null); clearAccountUi(); setUser(next);
      if (next && !next.isAnonymous && next.emailVerified) void loadOrders(next.uid, undefined, true);
    }).then((value) => { unsubscribe = value; });
    return () => { unsubscribe?.(); accountIsolation.dispose(); };
  }, [clearAccountUi, configured, loadOrders]);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); setBusy(true); setNotice(''); const data = new FormData(event.currentTarget); const email = String(data.get('email') ?? '').trim(); const password = String(data.get('password') ?? '');
    try {
      if (mode === 'reset') { await resetAccountPassword(email); setNotice('E-posta kayıtlıysa şifre sıfırlama bağlantısı gönderildi.'); }
      else if (mode === 'register') { await registerAccount(email, password); setNotice('Hesap aynı kullanıcı kimliğiyle hazırlandı. E-posta doğrulama bağlantısını kontrol edin.'); }
      else { await loginAccount(email, password, confirmSwitch); setNotice('Giriş yapıldı.'); }
    } catch (error) { setNotice(messageFor(error)); } finally { setBusy(false); }
  }
  function beginLogout() { isolation.current.switchAccount(null); clearAccountUi(); setUser(null); void logoutAccount().catch(() => setNotice('Çıkış tamamlanamadı; sayfayı yenileyip tekrar deneyin.')); }
  async function refreshVerification(uid: string) { const next = await refreshAccount(); if (!next || next.uid !== uid) return; setUser(next); if (next.emailVerified) { isolation.current.switchAccount(uid); clearAccountUi(); setUser(next); await loadOrders(uid, undefined, true); } }

  if (!configured) return <div className="account-card payment-error"><strong>Firebase hesabı yapılandırılmamış</strong><p>Email/Password sağlayıcısı ve web yapılandırması tamamlanmadan hesap işlemleri kullanılamaz.</p></div>;
  if (user === undefined) return <div className="account-card"><p>Kayıtlı oturum yükleniyor…</p></div>;
  if (user && !user.isAnonymous) return <div className="account-grid"><section className="account-card"><h2>{user.email}</h2><p>{user.emailVerified ? 'E-posta doğrulandı.' : 'Satın alma için e-postanızı doğrulamanız gerekir.'}</p>{!user.emailVerified && <div className="account-actions"><button className="button button-gold" onClick={() => void resendAccountVerification().then(() => setNotice('Doğrulama e-postası yeniden gönderildi.')).catch((e) => setNotice(messageFor(e)))}>Doğrulamayı gönder</button><button className="button account-secondary" onClick={() => void refreshVerification(user.uid)}>Durumu yenile</button></div>}<button className="text-link account-logout" onClick={beginLogout}>Çıkış yap</button>{notice && <p role="status">{notice}</p>}</section><section className="account-card"><h2>Satın aldıklarım</h2>{!user.emailVerified ? <p>Geçmiş yalnız doğrulanmış hesaba gösterilir.</p> : orders.length ? <><ul className="order-list">{orders.map((order) => <li key={order.orderId}><strong>{new Intl.NumberFormat('tr-TR', { style: 'currency', currency: order.currency }).format(order.priceMinor / 100)}</strong><span>{statusLabel(order)}</span><small>{new Date(order.createdAtMs).toLocaleDateString('tr-TR')} · {order.orderId}</small></li>)}</ul>{cursor && <button className="button account-secondary" onClick={() => void loadOrders(user.uid, cursor)}>Daha fazla göster</button>}</> : <p>Bu hesaba ait sipariş bulunamadı.</p>}</section></div>;
  return <div className="account-grid"><section className="account-card"><div className="account-tabs"><button onClick={() => setMode('login')}>Giriş</button><button onClick={() => setMode('register')}>Hesap oluştur</button><button onClick={() => setMode('reset')}>Şifre sıfırla</button></div>{user?.isAnonymous && <div className="payment-state"><strong>Geçici oturum bulundu</strong><p>Hesap oluşturmak mevcut UID’yi korur. Var olan hesaba giriş ise bu anonim UID’deki siparişleri taşımaz.</p></div>}<form className="account-form" onSubmit={submit}><label>E-posta<input name="email" type="email" required autoComplete="email" /></label>{mode !== 'reset' && <label>Şifre<input name="password" type="password" required minLength={6} autoComplete={mode === 'register' ? 'new-password' : 'current-password'} /></label>}{mode === 'login' && user?.isAnonymous && <label className="account-check"><input type="checkbox" checked={confirmSwitch} onChange={(e) => setConfirmSwitch(e.target.checked)} /> Anonim oturumumdaki hakların taşınmayacağını anlıyorum.</label>}<button className="button button-gold" disabled={busy}>{busy ? 'İşleniyor…' : mode === 'login' ? 'Giriş yap' : mode === 'register' ? 'Hesap oluştur ve doğrula' : 'Sıfırlama bağlantısı iste'}</button></form>{notice && <p role="alert">{notice}</p>}</section><aside className="account-card"><h2>Eski anonim siparişler</h2><p>Kaybolan anonim UID başka hesaba otomatik devredilmez. Sipariş numarası ve ödeme sağlayıcı referansıyla destek incelemesi gerekir; istemciden sahiplik değiştirilemez.</p></aside></div>;
}
function messageFor(error: unknown) { const code = error instanceof AccountActionError ? error.code : 'unknown'; return ({ email_in_use: 'Bu e-posta başka bir hesaba ait. Otomatik birleştirme yapılmadı; giriş yapın veya şifrenizi sıfırlayın.', provider_disabled: 'Firebase Console’da Email/Password sağlayıcısı etkin değil.', invalid_credentials: 'E-posta veya şifre doğrulanamadı.', anonymous_switch_confirmation_required: 'Anonim oturumdan ayrılmayı açıkça onaylayın.', unknown: 'İşlem tamamlanamadı. Bilgilerinizi kontrol edip tekrar deneyin.' })[code]; }
function statusLabel(order: Order) { if (order.financialReviewRequired) return 'Finansal inceleme gerekli'; if (order.providerPaymentStatus === 'refunded' || order.status === 'refunded') return 'İade edildi'; if (order.status === 'entitlement_granted') return 'Fal hakkı hazır'; if (order.status === 'entitlement_consumed') return 'Fal hakkı kullanıldı'; if (order.status === 'failed') return 'Başarısız'; return 'İşlem sürüyor'; }
