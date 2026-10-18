'use client';

import Image from 'next/image';
import { useEffect, useMemo, useRef, useState } from 'react';
import { COFFEE_INTENTION_MAX_LENGTH, sanitizeCoffeeIntention, type WebCoffeeSlot } from '@/lib/coffee/contracts';
import { getCoffeeRuntime, type CoffeeFlowResult, type CoffeeFlowUpdate } from '@/lib/coffee/service';

type Selected = { name: string; url: string; file: File };
type Selection = Partial<Record<WebCoffeeSlot, Selected>>;
const MAX_BYTES = 10 * 1024 * 1024;
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const slots: { id: WebCoffeeSlot; number: string; title: string; detail: string }[] = [
  { id: 'cup-primary', number: '01', title: 'Fincan — ilk açı', detail: 'Fincanın içini net göreceğimiz bir fotoğraf.' },
  { id: 'cup-secondary', number: '02', title: 'Fincan — ikinci açı', detail: 'Fincanı çevirip başka açıdan fotoğraflandır.' },
  { id: 'saucer', number: '03', title: 'Tabak', detail: 'Fincanın tabağının tamamını gösteren fotoğraf.' },
];
const intentions = [
  ['Genel', 'Önümüzdeki dönem genel olarak'],
  ['Aşk / İlişkiler', 'Aşk ve ilişkilerim hakkında'],
  ['İş / Kariyer', 'İşim ve kariyerim hakkında'],
  ['Para', 'Maddi durumum hakkında'],
  ['Aklımdaki kişi', 'Aklımdaki kişiyle ilgili'],
] as const;

export default function CoffeeCapture() {
  const [selected, setSelected] = useState<Selection>({});
  const selectedRef = useRef<Selection>({});
  const [error, setError] = useState('');
  const [reviewed, setReviewed] = useState(false);
  const [intention, setIntention] = useState('');
  const [flow, setFlow] = useState<CoffeeFlowUpdate | null>(null);
  const [result, setResult] = useState<CoffeeFlowResult | null>(null);
  const [running, setRunning] = useState(false);
  const runtime = useMemo(() => getCoffeeRuntime(), []);
  const serviceRef = useRef(runtime.service);

  useEffect(() => () => { Object.values(selectedRef.current).forEach((photo) => photo && URL.revokeObjectURL(photo.url)); }, []);

  const count = slots.filter((slot) => Boolean(selected[slot.id])).length;
  const safeIntention = sanitizeCoffeeIntention(intention);
  const ready = count === 3 && Boolean(safeIntention);

  function pick(slot: WebCoffeeSlot, file: File) {
    setReviewed(false); setResult(null); setFlow(null);
    if (!ALLOWED_TYPES.includes(file.type)) { setError('Yalnızca JPG, PNG veya WebP fotoğrafı seçebilirsin.'); return; }
    if (file.size === 0 || file.size > MAX_BYTES) { setError('Fotoğraf boyutu 0 MB’dan büyük, 10 MB’dan küçük olmalı.'); return; }
    const duplicate = Object.entries(selectedRef.current).find(([key, value]) => key !== slot && value?.name === file.name && value.file.size === file.size);
    if (duplicate) { setError('Aynı fotoğrafı iki alanda kullanamazsın. Farklı bir kare seç.'); return; }
    const old = selectedRef.current[slot]; if (old) URL.revokeObjectURL(old.url);
    const next = { ...selectedRef.current, [slot]: { name: file.name, url: URL.createObjectURL(file), file } };
    selectedRef.current = next; setSelected(next); setError('');
  }

  function remove(slot: WebCoffeeSlot) {
    const old = selectedRef.current[slot]; if (old) URL.revokeObjectURL(old.url);
    const next = { ...selectedRef.current }; delete next[slot]; selectedRef.current = next;
    setSelected(next); setReviewed(false); setResult(null); setFlow(null); setError('');
  }

  async function runFlow() {
    const service = serviceRef.current;
    if (!service || !runtime.canRun || !safeIntention || count !== 3) return;
    const files = Object.fromEntries(slots.map((slot) => [slot.id, selectedRef.current[slot.id]!.file])) as Record<WebCoffeeSlot, File>;
    setRunning(true); setError(''); setResult(null);
    try { setResult(await service.run({ files, intention: safeIntention, onUpdate: setFlow })); }
    catch { setError('Demo akışı tamamlanamadı. Fotoğrafların korunuyor; tekrar deneyebilirsin.'); }
    finally { setRunning(false); }
  }

  return <div className="capture-panel">
    <div className="capture-top"><div><div className="eyebrow">FOTOĞRAF HAZIRLIĞI</div><h2>Üç kare, tek fincan.</h2><p>2 fincan + 1 tabak. Her kare farklı olmalı.</p></div><div className="capture-counter" aria-live="polite"><strong>{count}<span>/3</span></strong><small>fotoğraf</small></div></div>
    <div className="progress-track" role="progressbar" aria-valuenow={count} aria-valuemin={0} aria-valuemax={3} aria-label="Seçilen fotoğraf sayısı"><span style={{ width: `${(count / 3) * 100}%` }} /></div>
    <div className="capture-grid">{slots.map((slot) => { const photo = selected[slot.id]; const inputId = `upload-${slot.id}`; return <div key={slot.id} className={`capture-slot ${photo ? 'has-photo' : ''}`}><span className="capture-slot-number">{slot.number}</span><div className="capture-slot-preview">{photo ? <Image src={photo.url} alt={`${slot.title} için seçilen fotoğraf`} fill sizes="(max-width: 700px) 80vw, 250px" unoptimized /> : <><Image className="slot-reference" src="/images/home_coffee.webp" alt="" fill sizes="(max-width: 700px) 80vw, 250px" /><span className="slot-guide" aria-hidden="true">{slot.id === 'saucer' ? 'TABAK' : 'FİNCAN'}</span></>}</div><h3>{slot.title}</h3><p>{slot.detail}</p><input id={inputId} className="sr-only-file" type="file" accept="image/jpeg,image/png,image/webp" aria-label={`${slot.title} fotoğrafı seç`} onChange={(event) => { const file = event.currentTarget.files?.[0]; if (file) pick(slot.id, file); event.currentTarget.value = ''; }} /><div className="capture-actions"><label htmlFor={inputId} className="capture-upload">{photo ? 'Değiştir' : 'Fotoğraf seç'} <span aria-hidden="true">+</span></label>{photo && <button type="button" onClick={() => remove(slot.id)} className="remove-photo">Kaldır</button>}</div>{photo && <small className="file-name" title={photo.name}>{photo.name}</small>}</div>; })}</div>
    {error && <p role="alert" className="form-error">{error}</p>}
    <div className="capture-summary"><div><strong>{count === 3 ? 'Fotoğrafların seçildi' : 'Fotoğraflarını hazırlıyoruz'}</strong><p>{count === 3 ? 'Niyetini seçerek son kontrolü tamamla.' : 'Devam etmek için üç farklı fotoğraf seç.'}</p></div><button type="button" className="button button-gold" disabled={count !== 3} onClick={() => setReviewed(true)}>Seçimi Kontrol Et <span aria-hidden="true">→</span></button></div>
    {reviewed && <section className="intention-panel" aria-labelledby="intention-title"><div className="eyebrow">NİYET / TRUSTED_INTENTION_V1</div><h3 id="intention-title">Falına hangi niyetle bakalım?</h3><p>Niyetin, yorumun gerçekten merak ettiğin konuya odaklanmasına yardımcı olur.</p><div className="intention-chips">{intentions.map(([label, value]) => <button type="button" className={intention === value ? 'selected' : ''} aria-pressed={intention === value} onClick={() => setIntention(value)} key={label}>{label}</button>)}</div><label className="custom-intention"><span>Ya da kısa niyetini yaz</span><textarea value={intention} maxLength={COFFEE_INTENTION_MAX_LENGTH} onChange={(event) => setIntention(event.target.value)} rows={3} placeholder="Kısa niyetini yaz" /><small>{intention.length}/{COFFEE_INTENTION_MAX_LENGTH}</small></label><div className={`integration-state state-${runtime.mode}`}><strong>{runtime.mode === 'mock' ? 'Yerel demo modu' : runtime.mode === 'live' ? 'Canlı entegrasyon kilitli' : 'Entegrasyon henüz etkin değil'}</strong><p>{runtime.reason}</p></div><button type="button" className="button button-gold flow-button" disabled={!ready || !runtime.canRun || running} onClick={runFlow}>{running ? 'Akış sürüyor…' : flow?.phase === 'failed' ? 'Tekrar Dene' : 'Demo Akışını Başlat'} <span aria-hidden="true">→</span></button><button type="button" className="button purchase-button" disabled>Satın alma yakında · Ödeme kapalı</button></section>}
    {flow && <div className={`flow-status flow-${flow.phase}`} role="status"><span className="flow-orb" aria-hidden="true" /><div><strong>{phaseTitle(flow.phase)}</strong><p>{flow.message}</p>{flow.uploaded != null && <small>{flow.uploaded}/3 hazırlandı</small>}</div></div>}
    {result?.kind === 'demo' && <div className="demo-result"><span>DEMO · SAHTE SONUÇ</span><h3>Akış başarıyla tamamlandı.</h3><p>Bu kart yalnızca işlem durumlarını doğrulayan bir test çıktısıdır; gerçek fal, AI yorumu veya kişisel sonuç değildir.</p></div>}
    {result?.kind === 'live-result-unavailable' && <div className="preview-notice"><strong>İşlem hazır.</strong> Sonuç teslim route’u web için doğrulanmadığından içerik gösterilmedi.</div>}
    <p className="capture-disclaimer">Güvenlik notu: Varsayılan durumda fotoğraflar yalnızca bu sayfa açıkken tarayıcında önizlenir. Gerçek gönderim, ödeme ve fal üretimi bu web sürümünde etkin değildir.</p>
  </div>;
}

function phaseTitle(phase: CoffeeFlowUpdate['phase']) {
  return ({ preparing: 'Hazırlanıyor', uploading: 'Fotoğraflar hazırlanıyor', waiting: 'Sırada bekliyor', processing: 'İşleniyor', ready: 'Tamamlandı', failed: 'Tekrar deneyebilirsin' })[phase];
}
